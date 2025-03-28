// REQUIRES: swift_feature_SafeInteropWrappers
// REQUIRES: swift_feature_LifetimeDependence

// This emits UnsafeMutableBufferPointer until MutableSpan has landed

// RUN: %target-swift-ide-test -print-module -module-to-print=CountedByNoEscapeClang -plugin-path %swift-plugin-dir -I %S/Inputs -source-filename=x -enable-experimental-feature SafeInteropWrappers -enable-experimental-feature LifetimeDependence | %FileCheck %s

// swift-ide-test doesn't currently typecheck the macro expansions, so run the compiler as well
// RUN: %empty-directory(%t)
// RUN: %target-swift-frontend -emit-module -plugin-path %swift-plugin-dir -o %t/CountedByNoEscape.swiftmodule -I %S/Inputs -enable-experimental-feature SafeInteropWrappers %s

// Check that ClangImporter correctly infers and expands @_SwiftifyImport macros for functions with __counted_by __noescape parameters.

import CountedByNoEscapeClang

// CHECK:      @_alwaysEmitIntoClient public func complexExpr(_ len: Int{{.*}}, _ offset: Int{{.*}}, _ p: UnsafeMutableBufferPointer<Int{{.*}}>)
// CHECK-NEXT: @_alwaysEmitIntoClient public func nonnull(_  p: UnsafeMutableBufferPointer<Int{{.*}}>)
// CHECK-NEXT: @_alwaysEmitIntoClient public func nullUnspecified(_  p: UnsafeMutableBufferPointer<Int{{.*}}>)
// CHECK-NEXT: @lifetime(copy p)
// CHECK-NEXT: @_alwaysEmitIntoClient public func returnLifetimeBound(_ len1: Int32, _ p: UnsafeMutableBufferPointer<Int32>) -> UnsafeMutableBufferPointer<Int32>
// CHECK-NEXT: @_alwaysEmitIntoClient @_disfavoredOverload public func returnPointer(_  len: Int{{.*}}) -> UnsafeMutableBufferPointer<Int{{.*}}>
// CHECK-NEXT: @_alwaysEmitIntoClient public func shared(_ len: Int{{.*}}, _ p1: UnsafeMutableBufferPointer<Int{{.*}}>, _ p2: UnsafeMutableBufferPointer<Int{{.*}}>)
// CHECK-NEXT: @_alwaysEmitIntoClient public func simple(_  p: UnsafeMutableBufferPointer<Int{{.*}}>)
// CHECK-NEXT: @_alwaysEmitIntoClient public func swiftAttr(_  p: UnsafeMutableBufferPointer<Int{{.*}}>)

@inlinable
public func callReturnPointer() {
  let a: UnsafeMutableBufferPointer<CInt>? = returnPointer(4) // call wrapper
  let b: UnsafeMutablePointer<CInt>? = returnPointer(4) // call unsafe interop
}

