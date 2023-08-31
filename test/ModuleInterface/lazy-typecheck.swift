// RUN: %empty-directory(%t)

// RUN: %target-swift-frontend -swift-version 5 %S/../Inputs/lazy_typecheck.swift -module-name lazy_typecheck -emit-module -emit-module-path /dev/null -emit-module-interface-path %t/lazy_typecheck.swiftinterface -enable-library-evolution -parse-as-library -package-name Package -experimental-lazy-typecheck -experimental-skip-all-function-bodies -experimental-serialize-external-decls-only
// RUN: %FileCheck %s < %t/lazy_typecheck.swiftinterface

// CHECK: import Swift

// CHECK:       public func publicFunc() -> Swift.Int
// CHECK:       publicFuncWithDefaultArg(_ x: Swift.Int = 1) -> Swift.Int
// CHECK:       @inlinable internal func inlinableFunc() -> Swift.Int {
// CHECK-NEXT:    return true // expected-error {{[{][{]}}cannot convert return expression of type 'Bool' to return type 'Int'{{[}][}]}}
// CHECK-NEXT:  }
// CHECK:       public func constrainedGenericPublicFunction<T>(_ t: T) where T : lazy_typecheck.PublicProto
// CHECK:       @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
// CHECK-NEXT:  public func publicFuncWithOpaqueReturnType() -> some lazy_typecheck.PublicProto

// CHECK:       @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
// CHECK-NEXT:  @_alwaysEmitIntoClient public func publicAEICFuncWithOpaqueReturnType() -> some Any {
// CHECK-NEXT:    if #available(macOS 20, *) {
// CHECK-NEXT:      return 3
// CHECK-NEXT:    } else {
// CHECK-NEXT:      return "hi"
// CHECK-NEXT:    }
// CHECK-NEXT:  }

// CHECK:       public protocol PublicProto {
// CHECK:         func req() -> Swift.Int
// CHECK:       }

// CHECK:       public struct PublicStruct {
// CHECK:         public func publicMethod() -> Swift.Int
// CHECK:       }
