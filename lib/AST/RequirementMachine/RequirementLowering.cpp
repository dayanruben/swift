//===--- RequirementLowering.cpp - Building rules from requirements -------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//
//
// This file implements logic for lowering generic requirements to rewrite rules
// in the requirement machine.
//
// This includes generic requirements from canonical generic signatures and
// protocol requirement signatures, as well as user-written requirements in
// protocols ("structural requirements") and the 'where' clauses of generic
// declarations.
//
// There is some additional desugaring logic for user-written requirements.
//
//===----------------------------------------------------------------------===//

#include "RequirementLowering.h"
#include "swift/AST/ASTContext.h"
#include "swift/AST/Decl.h"
#include "swift/AST/ExistentialLayout.h"
#include "swift/AST/Requirement.h"
#include "swift/AST/TypeCheckRequests.h"
#include "swift/AST/TypeMatcher.h"
#include "swift/AST/TypeRepr.h"
#include "llvm/ADT/SmallVector.h"
#include "RewriteContext.h"
#include "RewriteSystem.h"
#include "Symbol.h"
#include "Term.h"

using namespace swift;
using namespace rewriting;

//
// Requirement desugaring -- used in two places:
//
// 1) AbstractGenericSignatureRequest, where the added requirements might have
// substitutions applied.
//
// 2) StructuralRequirementsRequest, which performs further processing to wrap
// desugared requirements with source location information.
//

/// Desugar a same-type requirement that possibly has concrete types on either
/// side into a series of same-type and concrete-type requirements where the
/// left hand side is always a type parameter.
static void desugarSameTypeRequirement(Type lhs, Type rhs,
                                       SmallVectorImpl<Requirement> &result) {
  class Matcher : public TypeMatcher<Matcher> {
    SmallVectorImpl<Requirement> &result;

  public:
    explicit Matcher(SmallVectorImpl<Requirement> &result)
      : result(result) {}

    bool mismatch(TypeBase *firstType, TypeBase *secondType,
                  Type sugaredFirstType) {
      if (firstType->isTypeParameter() && secondType->isTypeParameter()) {
        result.emplace_back(RequirementKind::SameType,
                            firstType, secondType);
        return true;
      }

      if (firstType->isTypeParameter()) {
        result.emplace_back(RequirementKind::SameType,
                            firstType, secondType);
        return true;
      }

      if (secondType->isTypeParameter()) {
        result.emplace_back(RequirementKind::SameType,
                            secondType, firstType);
        return true;
      }

      // FIXME: Record concrete type conflict, diagnose upstream
      return true;
    }
  } matcher(result);

  // FIXME: Record redundancy and diagnose upstream
  (void) matcher.match(lhs, rhs);
}

static void desugarSuperclassRequirement(Type subjectType,
                                         Type constraintType,
                                         SmallVectorImpl<Requirement> &result) {
  if (!subjectType->isTypeParameter()) {
    // FIXME: Perform unification, diagnose redundancy or conflict upstream
    return;
  }

  result.emplace_back(RequirementKind::Superclass, subjectType, constraintType);
}

static void desugarLayoutRequirement(Type subjectType,
                                     LayoutConstraint layout,
                                     SmallVectorImpl<Requirement> &result) {
  if (!subjectType->isTypeParameter()) {
    // FIXME: Diagnose redundancy or conflict upstream
    return;
  }

  result.emplace_back(RequirementKind::Layout, subjectType, layout);
}

/// Desugar a protocol conformance requirement by splitting up protocol
/// compositions on the right hand side into conformance and superclass
/// requirements.
static void desugarConformanceRequirement(Type subjectType, Type constraintType,
                                          SmallVectorImpl<Requirement> &result) {
  // Fast path.
  if (constraintType->is<ProtocolType>()) {
    if (!subjectType->isTypeParameter()) {
      // FIXME: Check conformance, diagnose redundancy or conflict upstream
      return;
    }

    result.emplace_back(RequirementKind::Conformance, subjectType,
                        constraintType);
    return;
  }

  auto layout = constraintType->getExistentialLayout();

  if (auto layoutConstraint = layout.getLayoutConstraint())
    desugarLayoutRequirement(subjectType, layoutConstraint, result);

  if (auto superclass = layout.explicitSuperclass)
    desugarSuperclassRequirement(subjectType, superclass, result);

  for (auto *proto : layout.getProtocols()) {
    if (!subjectType->isTypeParameter()) {
      // FIXME: Check conformance, diagnose redundancy or conflict upstream
      return;
    }

    result.emplace_back(RequirementKind::Conformance, subjectType,
                        proto);
  }
}

/// Convert a requirement where the subject type might not be a type parameter,
/// or the constraint type in the conformance requirement might be a protocol
/// composition, into zero or more "proper" requirements which can then be
/// converted into rewrite rules by the RuleBuilder.
void
swift::rewriting::desugarRequirement(Requirement req,
                                     SmallVectorImpl<Requirement> &result) {
  auto firstType = req.getFirstType();

  switch (req.getKind()) {
  case RequirementKind::Conformance:
    desugarConformanceRequirement(firstType, req.getSecondType(), result);
    break;

  case RequirementKind::Superclass:
    desugarSuperclassRequirement(firstType, req.getSecondType(), result);
    break;

  case RequirementKind::Layout:
    desugarLayoutRequirement(firstType, req.getLayoutConstraint(), result);
    break;

  case RequirementKind::SameType:
    desugarSameTypeRequirement(firstType, req.getSecondType(), result);
    break;
  }
}

//
// StructuralRequirementsRequest computation.
//
// This realizes RequirementReprs into Requirements, desugars them using the
// above, performs requirement inference, and wraps them with source location
// information.
//

static void realizeTypeRequirement(Type subjectType, Type constraintType,
                                   SourceLoc loc, bool wasInferred,
                                   SmallVectorImpl<StructuralRequirement> &result) {
  // Check whether we have a reasonable constraint type at all.
  if (!constraintType->isExistentialType() &&
      !constraintType->getClassOrBoundGenericClass()) {
    // FIXME: Diagnose
    return;
  }

  SmallVector<Requirement, 2> reqs;

  if (constraintType->isExistentialType()) {
    // Handle conformance requirements.
    desugarConformanceRequirement(subjectType, constraintType, reqs);
  } else {
    // Handle superclass requirements.
    desugarSuperclassRequirement(subjectType, constraintType, reqs);
  }

  // Add source location information.
  for (auto req : reqs)
    result.push_back({req, loc, wasInferred});
}

static void inferRequirements(Type type, SourceLoc loc,
                              SmallVectorImpl<StructuralRequirement> &result) {
  // FIXME: Implement
}

static void realizeRequirement(Requirement req, RequirementRepr *reqRepr, bool infer,
                               SmallVectorImpl<StructuralRequirement> &result) {
  auto firstType = req.getFirstType();
  if (infer) {
    auto firstLoc = (reqRepr ? reqRepr->getFirstTypeRepr()->getStartLoc()
                             : SourceLoc());
    inferRequirements(firstType, firstLoc, result);
  }

  auto loc = (reqRepr ? reqRepr->getSeparatorLoc() : SourceLoc());

  switch (req.getKind()) {
  case RequirementKind::Superclass:
  case RequirementKind::Conformance: {
    auto secondType = req.getSecondType();
    if (infer) {
      auto secondLoc = (reqRepr ? reqRepr->getSecondTypeRepr()->getStartLoc()
                                : SourceLoc());
      inferRequirements(secondType, secondLoc, result);
    }

    realizeTypeRequirement(firstType, secondType, loc, /*wasInferred=*/false,
                           result);
    break;
  }

  case RequirementKind::Layout: {
    SmallVector<Requirement, 2> reqs;
    desugarLayoutRequirement(firstType, req.getLayoutConstraint(), reqs);

    for (auto req : reqs)
      result.push_back({req, loc, /*wasInferred=*/false});

    break;
  }

  case RequirementKind::SameType: {
    auto secondType = req.getSecondType();
    if (infer) {
      auto secondLoc = (reqRepr ? reqRepr->getSecondTypeRepr()->getStartLoc()
                                : SourceLoc());
      inferRequirements(secondType, secondLoc, result);
    }

    SmallVector<Requirement, 2> reqs;
    desugarSameTypeRequirement(req.getFirstType(), secondType, reqs);

    for (auto req : reqs)
      result.push_back({req, loc, /*wasInferred=*/false});
    break;
  }
  }
}

static void realizeInheritedRequirements(TypeDecl *decl, Type type, bool infer,
                               SmallVectorImpl<StructuralRequirement> &result) {
  auto &ctx = decl->getASTContext();
  auto inheritedTypes = decl->getInherited();

  for (unsigned index : indices(inheritedTypes)) {
    Type inheritedType
      = evaluateOrDefault(ctx.evaluator,
                          InheritedTypeRequest{decl, index,
                            TypeResolutionStage::Structural},
                          Type());
    if (!inheritedType) continue;

    auto *typeRepr = inheritedTypes[index].getTypeRepr();
    SourceLoc loc = (typeRepr ? typeRepr->getStartLoc() : SourceLoc());
    if (infer) {
      inferRequirements(inheritedType, loc, result);
    }

    realizeTypeRequirement(type, inheritedType, loc, /*wasInferred=*/false,
                           result);
  }
}

ArrayRef<StructuralRequirement>
StructuralRequirementsRequest::evaluate(Evaluator &evaluator,
                                        ProtocolDecl *proto) const {
  assert(!proto->hasLazyRequirementSignature());

  SmallVector<StructuralRequirement, 4> result;

  auto &ctx = proto->getASTContext();

  auto selfTy = proto->getSelfInterfaceType();

  realizeInheritedRequirements(proto, selfTy,
                               /*infer=*/false, result);

  // Add requirements from the protocol's own 'where' clause.
  WhereClauseOwner(proto).visitRequirements(TypeResolutionStage::Structural,
      [&](const Requirement &req, RequirementRepr *reqRepr) {
        realizeRequirement(req, reqRepr, /*infer=*/false, result);
        return false;
      });

  if (proto->isObjC()) {
    // @objc protocols have an implicit AnyObject requirement on Self.
    auto layout = LayoutConstraint::getLayoutConstraint(
        LayoutConstraintKind::Class, ctx);
    result.push_back({Requirement(RequirementKind::Layout, selfTy, layout),
                      proto->getLoc(), /*inferred=*/true});

    // Remaining logic is not relevant to @objc protocols.
    return ctx.AllocateCopy(result);
  }

  // Add requirements for each of the associated types.
  for (auto assocTypeDecl : proto->getAssociatedTypeMembers()) {
    // Add requirements placed directly on this associated type.
    auto assocType = assocTypeDecl->getDeclaredInterfaceType();
    realizeInheritedRequirements(assocTypeDecl, assocType, /*infer=*/false,
                                 result);

    // Add requirements from this associated type's where clause.
    WhereClauseOwner(assocTypeDecl).visitRequirements(
        TypeResolutionStage::Structural,
        [&](const Requirement &req, RequirementRepr *reqRepr) {
          realizeRequirement(req, reqRepr, /*infer=*/false, result);
          return false;
        });
  }

  return ctx.AllocateCopy(result);
}

ArrayRef<ProtocolDecl *>
ProtocolDependenciesRequest::evaluate(Evaluator &evaluator,
                                      ProtocolDecl *proto) const {
  auto &ctx = proto->getASTContext();
  SmallVector<ProtocolDecl *, 4> result;

  // If we have a serialized requirement signature, deserialize it and
  // look at conformance requirements.
  //
  // FIXME: For now we just fall back to the GSB for all protocols
  // unless -requirement-machine-protocol-signatures=on is passed.
  if (proto->hasLazyRequirementSignature() ||
      (ctx.LangOpts.RequirementMachineProtocolSignatures
        == RequirementMachineMode::Disabled)) {
    for (auto req : proto->getRequirementSignature()) {
      if (req.getKind() == RequirementKind::Conformance) {
        result.push_back(req.getProtocolDecl());
      }
    }

    return ctx.AllocateCopy(result);
  }

  // Otherwise, we can't ask for the requirement signature, because
  // this request is used as part of *building* the requirement
  // signature. Look at the structural requirements instead.
  for (auto req : proto->getStructuralRequirements()) {
    if (req.req.getKind() == RequirementKind::Conformance)
      result.push_back(req.req.getProtocolDecl());
  }

  return ctx.AllocateCopy(result);
}

//
// Building rewrite rules from desugared requirements.
//

/// Given a concrete type that may contain type parameters in structural positions,
/// collect all the structural type parameter components, and replace them all with
/// fresh generic parameters. The fresh generic parameters all have a depth of 0,
/// and the index is an index into the 'result' array.
///
/// For example, given the concrete type Foo<X.Y, Array<Z>>, this produces the
/// result type Foo<τ_0_0, Array<τ_0_1>>, with result array {X.Y, Z}.
CanType
RuleBuilder::getConcreteSubstitutionSchema(CanType concreteType,
                                           const ProtocolDecl *proto,
                                           SmallVectorImpl<Term> &result) {
  assert(!concreteType->isTypeParameter() && "Must have a concrete type here");

  if (!concreteType->hasTypeParameter())
    return concreteType;

  return CanType(concreteType.transformRec([&](Type t) -> Optional<Type> {
    if (!t->isTypeParameter())
      return None;

    unsigned index = result.size();
    result.push_back(Context.getTermForType(CanType(t), proto));

    return CanGenericTypeParamType::get(/*type sequence=*/ false,
                                        /*depth=*/0, index,
                                        Context.getASTContext());
  }));
}

void RuleBuilder::addRequirements(ArrayRef<Requirement> requirements) {
  // Collect all protocols transitively referenced from these requirements.
  for (auto req : requirements) {
    if (req.getKind() == RequirementKind::Conformance) {
      addProtocol(req.getProtocolDecl(), /*initialComponent=*/false);
    }
  }

  collectRulesFromReferencedProtocols();

  // Add rewrite rules for all top-level requirements.
  for (const auto &req : requirements)
    addRequirement(req, /*proto=*/nullptr);
}

void RuleBuilder::addProtocols(ArrayRef<const ProtocolDecl *> protos) {
  // Collect all protocols transitively referenced from this connected component
  // of the protocol dependency graph.
  for (auto proto : protos) {
    addProtocol(proto, /*initialComponent=*/true);
  }

  collectRulesFromReferencedProtocols();
}

/// For an associated type T in a protocol P, we add a rewrite rule:
///
///   [P].T => [P:T]
///
/// Intuitively, this means "if a type conforms to P, it has a nested type
/// named T".
void RuleBuilder::addAssociatedType(const AssociatedTypeDecl *type,
                                    const ProtocolDecl *proto) {
  MutableTerm lhs;
  lhs.add(Symbol::forProtocol(proto, Context));
  lhs.add(Symbol::forName(type->getName(), Context));

  MutableTerm rhs;
  rhs.add(Symbol::forAssociatedType(proto, type->getName(), Context));

  PermanentRules.emplace_back(lhs, rhs);
}

/// Lowers a generic requirement to a rewrite rule.
///
/// If \p proto is null, this is a generic requirement from the top-level
/// generic signature. The added rewrite rule will be rooted in a generic
/// parameter symbol.
///
/// If \p proto is non-null, this is a generic requirement in the protocol's
/// requirement signature. The added rewrite rule will be rooted in a
/// protocol symbol.
void RuleBuilder::addRequirement(const Requirement &req,
                                 const ProtocolDecl *proto) {
  if (Dump) {
    llvm::dbgs() << "+ ";
    req.dump(llvm::dbgs());
    llvm::dbgs() << "\n";
  }

  // Compute the left hand side.
  auto subjectType = CanType(req.getFirstType());
  auto subjectTerm = Context.getMutableTermForType(subjectType, proto);

  // Compute the right hand side.
  MutableTerm constraintTerm;

  switch (req.getKind()) {
  case RequirementKind::Conformance: {
    // A conformance requirement T : P becomes a rewrite rule
    //
    //   T.[P] == T
    //
    // Intuitively, this means "any type ending with T conforms to P".
    auto *proto = req.getProtocolDecl();

    constraintTerm = subjectTerm;
    constraintTerm.add(Symbol::forProtocol(proto, Context));
    break;
  }

  case RequirementKind::Superclass: {
    // A superclass requirement T : C<X, Y> becomes a rewrite rule
    //
    //   T.[superclass: C<X, Y>] => T
    //
    // Together with a rewrite rule
    //
    //   [superclass: C<X, Y>].[layout: L] => [superclass: C<X, Y>]
    //
    // Where 'L' is either AnyObject or _NativeObject, depending on the
    // ancestry of C.
    //
    // The second rule is marked permanent. Completion will derive a new
    // rule as a consequence of these two rules:
    //
    //   T.[layout: L] => T
    //
    // The new rule will be marked redundant by homotopy reduction since
    // it is a consequence of the other two rules.
    auto otherType = CanType(req.getSecondType());

    // Build the symbol [superclass: C<X, Y>].
    SmallVector<Term, 1> substitutions;
    otherType = getConcreteSubstitutionSchema(otherType, proto,
                                              substitutions);
    auto superclassSymbol = Symbol::forSuperclass(otherType, substitutions,
                                                  Context);

    {
      // Build the symbol [layout: L].
      auto layout =
        LayoutConstraint::getLayoutConstraint(
          otherType->getClassOrBoundGenericClass()->usesObjCObjectModel()
            ? LayoutConstraintKind::Class
            : LayoutConstraintKind::NativeClass,
          Context.getASTContext());
      auto layoutSymbol = Symbol::forLayout(layout, Context);

      MutableTerm layoutSubjectTerm;
      layoutSubjectTerm.add(superclassSymbol);

      MutableTerm layoutConstraintTerm = layoutSubjectTerm;
      layoutConstraintTerm.add(layoutSymbol);

      // Add the rule [superclass: C<X, Y>].[layout: L] => [superclass: C<X, Y>].
      PermanentRules.emplace_back(layoutConstraintTerm,
                                  layoutSubjectTerm);
    }

    // Build the term T.[superclass: C<X, Y>].
    constraintTerm = subjectTerm;
    constraintTerm.add(superclassSymbol);
    break;
  }

  case RequirementKind::Layout: {
    // A layout requirement T : L becomes a rewrite rule
    //
    //   T.[layout: L] == T
    constraintTerm = subjectTerm;
    constraintTerm.add(Symbol::forLayout(req.getLayoutConstraint(),
                                         Context));
    break;
  }

  case RequirementKind::SameType: {
    auto otherType = CanType(req.getSecondType());

    if (!otherType->isTypeParameter()) {
      // A concrete same-type requirement T == C<X, Y> becomes a
      // rewrite rule
      //
      //   T.[concrete: C<X, Y>] => T
      SmallVector<Term, 1> substitutions;
      otherType = getConcreteSubstitutionSchema(otherType, proto,
                                                substitutions);

      constraintTerm = subjectTerm;
      constraintTerm.add(Symbol::forConcreteType(otherType, substitutions,
                                                 Context));
      break;
    }

    constraintTerm = Context.getMutableTermForType(otherType, proto);
    break;
  }
  }

  RequirementRules.emplace_back(subjectTerm, constraintTerm);
}

/// Record information about a protocol if we have no seen it yet.
void RuleBuilder::addProtocol(const ProtocolDecl *proto,
                              bool initialComponent) {
  if (ProtocolMap.count(proto) > 0)
    return;

  ProtocolMap[proto] = initialComponent;
  Protocols.push_back(proto);
}

/// Compute the transitive closure of the set of all protocols referenced from
/// the right hand sides of conformance requirements, and convert their
/// requirements to rewrite rules.
void RuleBuilder::collectRulesFromReferencedProtocols() {
  unsigned i = 0;
  while (i < Protocols.size()) {
    auto *proto = Protocols[i++];
    for (auto *depProto : proto->getProtocolDependencies()) {
      addProtocol(depProto, /*initialComponent=*/false);
    }
  }

  // Add rewrite rules for each protocol.
  for (auto *proto : Protocols) {
    if (Dump) {
      llvm::dbgs() << "protocol " << proto->getName() << " {\n";
    }

    MutableTerm lhs;
    lhs.add(Symbol::forProtocol(proto, Context));
    lhs.add(Symbol::forProtocol(proto, Context));

    MutableTerm rhs;
    rhs.add(Symbol::forProtocol(proto, Context));

    PermanentRules.emplace_back(lhs, rhs);

    for (auto *assocType : proto->getAssociatedTypeMembers())
      addAssociatedType(assocType, proto);

    for (auto *inheritedProto : Context.getInheritedProtocols(proto)) {
      for (auto *assocType : inheritedProto->getAssociatedTypeMembers())
        addAssociatedType(assocType, proto);
    }

    // If this protocol is part of the initial connected component, we're
    // building requirement signatures for all protocols in this component,
    // and so we must start with the structural requirements.
    //
    // Otherwise, we should either already have a requirement signature, or
    // we can trigger the computation of the requirement signatures of the
    // next component recursively.
    if (ProtocolMap[proto]) {
      for (auto req : proto->getStructuralRequirements()) {
        // FIXME: Keep source location information around for redundancy
        // diagnostics.
        addRequirement(req.req.getCanonical(), proto);
      }
    } else {
      for (auto req : proto->getRequirementSignature())
        addRequirement(req.getCanonical(), proto);
    }

    if (Dump) {
      llvm::dbgs() << "}\n";
    }
  }
}
