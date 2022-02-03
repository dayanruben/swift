//===--- TypeCheckDistributed.cpp - Distributed ---------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//
//
// This file implements type checking support for Swift's concurrency model.
//
//===----------------------------------------------------------------------===//
#include "TypeCheckConcurrency.h"
#include "TypeCheckDistributed.h"
#include "TypeChecker.h"
#include "TypeCheckType.h"
#include "swift/Strings.h"
#include "swift/AST/ASTWalker.h"
#include "swift/AST/Initializer.h"
#include "swift/AST/ParameterList.h"
#include "swift/AST/ProtocolConformance.h"
#include "swift/AST/NameLookupRequests.h"
#include "swift/AST/TypeCheckRequests.h"
#include "swift/AST/TypeVisitor.h"
#include "swift/AST/ExistentialLayout.h"

using namespace swift;

// ==== ------------------------------------------------------------------------

bool swift::ensureDistributedModuleLoaded(Decl *decl) {
  auto &C = decl->getASTContext();
  auto moduleAvailable = evaluateOrDefault(
      C.evaluator, DistributedModuleIsAvailableRequest{decl}, false);
  return moduleAvailable;
}

bool
DistributedModuleIsAvailableRequest::evaluate(Evaluator &evaluator,
                                              Decl *decl) const {
  auto &C = decl->getASTContext();

  if (C.getLoadedModule(C.Id_Distributed))
    return true;

  // seems we're missing the _Distributed module, ask to import it explicitly
  decl->diagnose(diag::distributed_actor_needs_explicit_distributed_import);
  return false;
}

// ==== ------------------------------------------------------------------------

/// Add Fix-It text for the given protocol type to inherit DistributedActor.
void swift::diagnoseDistributedFunctionInNonDistributedActorProtocol(
    const ProtocolDecl *proto, InFlightDiagnostic &diag) {
  if (proto->getInherited().empty()) {
    SourceLoc fixItLoc = proto->getBraces().Start;
    diag.fixItInsert(fixItLoc, ": DistributedActor");
  } else {
    // Similar to how Sendable FitIts do this, we insert at the end of
    // the inherited types.
    ASTContext &ctx = proto->getASTContext();
    SourceLoc fixItLoc = proto->getInherited().back().getSourceRange().End;
    fixItLoc = Lexer::getLocForEndOfToken(ctx.SourceMgr, fixItLoc);
    diag.fixItInsert(fixItLoc, ", DistributedActor");
  }
}


/// Add Fix-It text for the given nominal type to adopt Codable.
///
/// Useful when 'Codable' is the 'SerializationRequirement' and a non-Codable
/// function parameter or return value type is detected.
void swift::addCodableFixIt(
    const NominalTypeDecl *nominal, InFlightDiagnostic &diag) {
  if (nominal->getInherited().empty()) {
    SourceLoc fixItLoc = nominal->getBraces().Start;
    diag.fixItInsert(fixItLoc, ": Codable");
  } else {
    ASTContext &ctx = nominal->getASTContext();
    SourceLoc fixItLoc = nominal->getInherited().back().getSourceRange().End;
    fixItLoc = Lexer::getLocForEndOfToken(ctx.SourceMgr, fixItLoc);
    diag.fixItInsert(fixItLoc, ", Codable");
  }
}

// ==== ------------------------------------------------------------------------

bool IsDistributedActorRequest::evaluate(
    Evaluator &evaluator, NominalTypeDecl *nominal) const {
  // Protocols are actors if they inherit from `DistributedActor`.
  if (auto protocol = dyn_cast<ProtocolDecl>(nominal)) {
    auto &ctx = protocol->getASTContext();
    auto *distributedActorProtocol = ctx.getDistributedActorDecl();
    return (protocol == distributedActorProtocol ||
            protocol->inheritsFrom(distributedActorProtocol));
  }

  // Class declarations are 'distributed actors' if they are declared with
  // 'distributed actor'
  auto classDecl = dyn_cast<ClassDecl>(nominal);
  if(!classDecl)
    return false;

  return classDecl->isExplicitDistributedActor();
}

// ==== ------------------------------------------------------------------------

bool swift::checkDistributedActorSystemAdHocProtocolRequirements(
    ASTContext &C,
    ProtocolDecl *Proto,
    NormalProtocolConformance *Conformance,
    Type Adoptee,
    bool diagnose) {
  auto decl = Adoptee->getAnyNominal();

  // ==== ----------------------------------------------------------------------
  // Check the ad-hoc requirements of 'DistributedActorSystem":
  // - remoteCall
  if (Proto->isSpecificProtocol(KnownProtocolKind::DistributedActorSystem)) {
    auto remoteCallDecl =
        C.getRemoteCallOnDistributedActorSystem(decl, /*isVoidReturn=*/false);
    if (!remoteCallDecl && diagnose) {
      decl->diagnose(
          diag::distributed_actor_system_conformance_missing_adhoc_requirement,
          decl->getDescriptiveKind(), decl->getName(), C.Id_remoteCall);
      decl->diagnose(
          diag::note_distributed_actor_system_conformance_missing_adhoc_requirement,
          decl->getName(), C.Id_remoteCall,
          "func remoteCall<Act, Err, Res>(\n"
          "    on actor: Act,\n"
          "    target: RemoteCallTarget,\n"
          "    invocation: inout InvocationEncoder,\n"
          "    throwing: Err.Type,\n"
          "    returning: Res.Type\n"
          ") async throws -> Res\n"
          "  where Act: DistributedActor,\n"
          "        Act.ID == ActorID,\n"
          "        Err: Error,\n"
          "        Res: SerializationRequirement\n");
      return true;
    }

    auto remoteCallVoidDecl =
        C.getRemoteCallOnDistributedActorSystem(decl, /*isVoidReturn=*/true);
    if (!remoteCallVoidDecl && diagnose) {
      decl->diagnose(
          diag::distributed_actor_system_conformance_missing_adhoc_requirement,
          decl->getDescriptiveKind(), decl->getName(), C.Id_remoteCallVoid);
      decl->diagnose(
          diag::note_distributed_actor_system_conformance_missing_adhoc_requirement,
          decl->getName(), C.Id_remoteCallVoid,
          "func remoteCallVoid<Act, Err>(\n"
          "    on actor: Act,\n"
          "    target: RemoteCallTarget,\n"
          "    invocation: inout InvocationEncoder,\n"
          "    throwing: Err.Type\n"
          ") async throws\n"
          "  where Act: DistributedActor,\n"
          "        Act.ID == ActorID,\n"
          "        Err: Error\n");
      return true;
    }

    return false;
  }

  // ==== ----------------------------------------------------------------------
  // Check the ad-hoc requirements of 'DistributedTargetInvocation'
  if (Proto->isSpecificProtocol(KnownProtocolKind::DistributedTargetInvocationDecoder)) {
    // FIXME(distributed): implement finding this the requirements here
    auto anyMissingAdHocRequirements = false;

    if (!C.getRecordArgumentOnDistributedInvocationEncoder(decl)) {
      decl->diagnose(
          diag::distributed_actor_system_conformance_missing_adhoc_requirement,
          decl->getDescriptiveKind(), decl->getName(), C.Id_recordArgument);
      // TODO: add note to add signature
      anyMissingAdHocRequirements = true;
    }

    if (!C.getRecordErrorTypeOnDistributedInvocationEncoder(decl)) {
      decl->diagnose(
          diag::distributed_actor_system_conformance_missing_adhoc_requirement,
          decl->getDescriptiveKind(), decl->getName(), C.Id_recordErrorType);
      // TODO: add note to add signature
      anyMissingAdHocRequirements = true;
    }

    if (!C.getRecordReturnTypeOnDistributedInvocationEncoder(decl)) {
      decl->diagnose(
          diag::distributed_actor_system_conformance_missing_adhoc_requirement,
          decl->getDescriptiveKind(), decl->getName(), C.Id_recordReturnType);
      // TODO: add note to add signature
      anyMissingAdHocRequirements = true;
    }

    if (anyMissingAdHocRequirements)
      return true; // found errors
  }

  // ==== ----------------------------------------------------------------------
  // Check the ad-hoc requirements of 'DistributedTargetInvocationArgumentDecoder'
  if (Proto->isSpecificProtocol(KnownProtocolKind::DistributedTargetInvocationResultHandler)) {
    // FIXME(distributed): implement finding this the requirements here
//
//    return true;
  }

  return false;
}

/// Check whether the function is a proper distributed function
///
/// \param diagnose Whether to emit a diagnostic when a problem is encountered.
///
/// \returns \c true if there was a problem with adding the attribute, \c false
/// otherwise.
bool swift::checkDistributedFunction(FuncDecl *func, bool diagnose) {
  // === All parameters and the result type must be Codable

  auto &C = func->getASTContext();
  auto encodableType = C.getProtocol(KnownProtocolKind::Encodable);
  auto decodableType = C.getProtocol(KnownProtocolKind::Decodable);

  auto module = func->getParentModule();

  // --- Check parameters for 'Codable' conformance
  for (auto param : *func->getParameters()) {
    auto paramTy = func->mapTypeIntoContext(param->getInterfaceType());
    if (TypeChecker::conformsToProtocol(paramTy, encodableType, module).isInvalid() ||
        TypeChecker::conformsToProtocol(paramTy, decodableType, module).isInvalid()) {
      if (diagnose) {
        auto diag = func->diagnose(
            diag::distributed_actor_func_param_not_codable,
            param->getArgumentName().str(), param->getInterfaceType(),
            func->getDescriptiveKind(), "Codable");
        if (auto paramNominalTy = paramTy->getAnyNominal()) {
          addCodableFixIt(paramNominalTy, diag);
        } // else, no nominal type to suggest the fixit for, e.g. a closure
      }
      return true;
    }

    if (param->isInOut()) {
      param->diagnose(
          diag::distributed_actor_func_inout,
          param->getName(),
          func->getDescriptiveKind(), func->getName()
      ).fixItRemove(SourceRange(param->getTypeSourceRangeForDiagnostics().Start,
                                param->getTypeSourceRangeForDiagnostics().Start.getAdvancedLoc(1)));
      // FIXME(distributed): the fixIt should be on param->getSpecifierLoc(), but that Loc is invalid for some reason?
      return true;
    }

    if (param->isVariadic()) {
      param->diagnose(
          diag::distributed_actor_func_variadic,
          param->getName(),
          func->getDescriptiveKind(), func->getName()
      );
    }
  }

  // --- Result type must be either void or a codable type
  auto resultType = func->mapTypeIntoContext(func->getResultInterfaceType());
  if (!resultType->isVoid()) {
    if (TypeChecker::conformsToProtocol(resultType, decodableType, module).isInvalid() ||
        TypeChecker::conformsToProtocol(resultType, encodableType, module).isInvalid()) {
      if (diagnose) {
        auto diag = func->diagnose(
            diag::distributed_actor_func_result_not_codable,
            func->getResultInterfaceType(), func->getDescriptiveKind(),
            "Codable" // Codable is a typealias, easier to diagnose like that
        );
        if (auto resultNominalType = resultType->getAnyNominal()) {
          addCodableFixIt(resultNominalType, diag);
        }
      }
      return true;
    }
  }

  return false;
}

void swift::checkDistributedActorProperties(const ClassDecl *decl) {
  auto &C = decl->getASTContext();

  for (auto member : decl->getMembers()) {
    if (auto prop = dyn_cast<VarDecl>(member)) {
      if (prop->isSynthesized())
        continue;

      auto id = prop->getName();
      if (id == C.Id_actorSystem || id == C.Id_id) {
        prop->diagnose(diag::distributed_actor_user_defined_special_property,
                      id);
      }
    }
  }
}

void swift::checkDistributedActorConstructor(const ClassDecl *decl, ConstructorDecl *ctor) {
  // bail out unless distributed actor, only those have special rules to check here
  if (!decl->isDistributedActor())
    return;

  // Only designated initializers need extra checks
  if (!ctor->isDesignatedInit())
    return;

  // === Designated initializers must accept exactly one actor transport that
  // matches the actor transport type of the actor.
  SmallVector<ParamDecl*, 2> transportParams;
  int transportParamsCount = 0;
  Type actorSystemTy = ctor->mapTypeIntoContext(
      getDistributedActorSystemType(const_cast<ClassDecl *>(decl)));
  for (auto param : *ctor->getParameters()) {
    auto paramTy = ctor->mapTypeIntoContext(param->getInterfaceType());
    if (paramTy->isEqual(actorSystemTy)) {
      transportParamsCount += 1;
      transportParams.push_back(param);
    }
  }

  // missing transport parameter
  if (transportParamsCount == 0) {
    ctor->diagnose(diag::distributed_actor_designated_ctor_missing_transport_param,
                   ctor->getName());
    // TODO(distributed): offer fixit to insert 'transport: DistributedActorSystem'
    return;
  }

  // ok! We found exactly one transport parameter
  if (transportParamsCount == 1)
    return;

  // TODO(distributed): rdar://81824959 report the error on the offending (2nd) matching parameter
  //                    Or maybe we can issue a note about the other offending params?
  ctor->diagnose(diag::distributed_actor_designated_ctor_must_have_one_distributedactorsystem_param,
                 ctor->getName(), transportParamsCount);
}

// ==== ------------------------------------------------------------------------

void TypeChecker::checkDistributedActor(ClassDecl *decl) {
  if (!decl)
    return;

  // ==== Ensure the _Distributed module is available,
  // without it there's no reason to check the decl in more detail anyway.
  if (!swift::ensureDistributedModuleLoaded(decl))
    return;

  // ==== Constructors
  // --- Get the default initializer
  // If applicable, this will create the default 'init(transport:)' initializer
  (void)decl->getDefaultInitializer();

  for (auto member : decl->getMembers()) {
    // --- Check all constructors
    if (auto ctor = dyn_cast<ConstructorDecl>(member))
      checkDistributedActorConstructor(decl, ctor);
  }

  // ==== Properties
  // --- Check for any illegal re-definitions
  checkDistributedActorProperties(decl);
  // --- Synthesize the 'id' property here rather than via derived conformance
  //     because the 'DerivedConformanceDistributedActor' won't trigger for 'id'
  //     because it has a default impl via 'Identifiable' (ObjectIdentifier)
  //     which we do not want.
  (void)decl->getDistributedActorIDProperty();
}

static Type getAssociatedTypeOfDistributedSystem(NominalTypeDecl *actor,
                                                 Identifier member) {
  assert(actor->isDistributedActor());
  auto &ctx = actor->getASTContext();

  auto actorProtocol = ctx.getProtocol(KnownProtocolKind::DistributedActor);
  if (!actorProtocol)
    return ErrorType::get(ctx);

  AssociatedTypeDecl *actorSystemDecl =
      actorProtocol->getAssociatedType(ctx.Id_ActorSystem);
  if (!actorSystemDecl)
    return ErrorType::get(ctx);

  auto actorSystemProtocol = ctx.getProtocol(KnownProtocolKind::DistributedActorSystem);
  if (!actorSystemProtocol)
    return ErrorType::get(ctx);

  AssociatedTypeDecl *assocTypeDecl =
      actorSystemProtocol->getAssociatedType(member);
  if (!assocTypeDecl)
    return ErrorType::get(ctx);

  auto module = actor->getParentModule();
  Type selfType = actor->getSelfInterfaceType();
  auto conformance = module->lookupConformance(selfType, actorProtocol);
  Type dependentType = actorProtocol->getSelfInterfaceType();
  dependentType = DependentMemberType::get(dependentType, actorSystemDecl);
  dependentType = DependentMemberType::get(dependentType, assocTypeDecl);

  return dependentType.subst(SubstitutionMap::getProtocolSubstitutions(
      actorProtocol, selfType, conformance));
}

Type swift::getDistributedActorSystemType(NominalTypeDecl *actor) {
  assert(actor->isDistributedActor());
  auto &ctx = actor->getASTContext();

  auto protocol = ctx.getProtocol(KnownProtocolKind::DistributedActor);
  if (!protocol)
    return ErrorType::get(ctx);

  // Dig out the actor system type.
  auto module = actor->getParentModule();
  Type selfType = actor->getSelfInterfaceType();
  auto conformance = module->lookupConformance(selfType, protocol);
  return conformance.getTypeWitnessByName(selfType, ctx.Id_ActorSystem);
}

Type swift::getDistributedActorIDType(NominalTypeDecl *actor) {
  auto &ctx = actor->getASTContext();
  return getAssociatedTypeOfDistributedSystem(actor, ctx.Id_ActorID);
}

Type ASTContext::getDistributedSerializationRequirementType(
    NominalTypeDecl *nominal) {
  return getAssociatedTypeOfDistributedSystem(nominal,
                                              Id_SerializationRequirement);
}

NominalTypeDecl *
ASTContext::getDistributedActorInvocationDecoder(NominalTypeDecl *actor) {
  if (!actor->isDistributedActor())
    return nullptr;

  return evaluateOrDefault(
      evaluator, GetDistributedActorInvocationDecoderRequest{actor}, nullptr);
}

NominalTypeDecl *
GetDistributedActorInvocationDecoderRequest::evaluate(Evaluator &evaluator,
                                                      NominalTypeDecl *actor) const {
  auto &ctx = actor->getASTContext();
  auto decoderTy =
      getAssociatedTypeOfDistributedSystem(actor, ctx.Id_InvocationDecoder);
  return decoderTy->hasError() ? nullptr : decoderTy->getAnyNominal();
}

FuncDecl *ASTContext::getDistributedActorArgumentDecodingMethod(NominalTypeDecl *actor) {
  if (!actor->isDistributedActor())
    return nullptr;

  return evaluateOrDefault(
    evaluator, GetDistributedActorArgumentDecodingMethodRequest{actor}, nullptr);
}


FuncDecl *
GetDistributedActorArgumentDecodingMethodRequest::evaluate(Evaluator &evaluator,
                                                           NominalTypeDecl *actor) const {
  auto &ctx = actor->getASTContext();

  auto *decoder = ctx.getDistributedActorInvocationDecoder(actor);
  assert(decoder);

  auto decoderTy = decoder->getInterfaceType()->getMetatypeInstanceType();

  auto members = TypeChecker::lookupMember(actor->getDeclContext(), decoderTy,
                                           DeclNameRef(ctx.Id_decodeNextArgument));

  // typealias SerializationRequirement = any ...
  auto serializerType = ctx.getDistributedSerializationRequirementType(actor)
                            ->castTo<ExistentialType>()
                            ->getConstraintType()
                            ->getDesugaredType();

  llvm::SmallPtrSet<ProtocolDecl *, 2> serializationReqs;
  if (auto composition = serializerType->getAs<ProtocolCompositionType>()) {
    for (auto member : composition->getMembers()) {
      if (auto *protocol = member->getAs<ProtocolType>())
        serializationReqs.insert(protocol->getDecl());
    }
  } else {
    auto protocol = serializerType->castTo<ProtocolType>()->getDecl();
    serializationReqs.insert(protocol);
  }

  SmallVector<FuncDecl *, 2> candidates;
  // Looking for `decodeNextArgument<Arg: <SerializationReq>>() throws -> Arg`
  for (auto &member : members) {
    auto *FD = dyn_cast<FuncDecl>(member.getValueDecl());
    if (!FD || FD->hasAsync() || !FD->hasThrows())
      continue;

    auto *params = FD->getParameters();
    // No arguemnts.
    if (params->size() != 0)
      continue;

    auto genericParamList = FD->getGenericParams();
    // A single generic parameter.
    if (genericParamList->size() != 1)
      continue;

    auto paramTy = genericParamList->getParams()[0]
                       ->getInterfaceType()
                       ->getMetatypeInstanceType();

    // `decodeNextArgument` should return its generic parameter value
    if (!FD->getResultInterfaceType()->isEqual(paramTy))
      continue;

    // Let's find out how many serialization requirements does this method cover
    // e.g. `Codable` is two requirements - `Encodable` and `Decodable`.
    unsigned numSerializationReqsCovered = llvm::count_if(
        FD->getGenericRequirements(), [&](const Requirement &requirement) {
          if (!(requirement.getFirstType()->isEqual(paramTy) &&
                requirement.getKind() == RequirementKind::Conformance))
            return 0;

          return serializationReqs.count(requirement.getProtocolDecl()) ? 1 : 0;
        });

    // If the current method covers all of the serialization requirements,
    // it's a match. Note that it might also have other requirements, but
    // we let that go as long as there are no two candidates that differ
    // only in generic requirements.
    if (numSerializationReqsCovered == serializationReqs.size())
      candidates.push_back(FD);
  }

  // Type-checker should reject any definition of invocation decoder
  // that doesn't have a correct version of `decodeNextArgument` declared.
  assert(candidates.size() == 1);
  return candidates.front();
}
