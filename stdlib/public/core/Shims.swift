//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//
///
/// Additions to 'SwiftShims' that can be written in Swift.
///
//===----------------------------------------------------------------------===//

import SwiftShims

#if _runtime(_ObjC)
@inlinable
internal func _makeSwiftNSFastEnumerationState()
   -> _SwiftNSFastEnumerationState {
  return _SwiftNSFastEnumerationState(
    state: 0, itemsPtr: nil, mutationsPtr: nil,
    extra: (0, 0, 0, 0, 0))
}

/// A dummy value to be used as the target for `mutationsPtr` in fast
/// enumeration implementations.
@usableFromInline
internal var _fastEnumerationStorageMutationsTarget: CUnsignedLong = 0

/// A dummy pointer to be used as `mutationsPtr` in fast enumeration
/// implementations.
@usableFromInline
internal let _fastEnumerationStorageMutationsPtr =
  UnsafeMutablePointer<CUnsignedLong>(Builtin.addressof(&_fastEnumerationStorageMutationsTarget))
#endif

@usableFromInline @_alwaysEmitIntoClient
internal func _mallocSize(ofAllocation ptr: UnsafeRawPointer) -> Int? {
  return _swift_stdlib_has_malloc_size() ? _swift_stdlib_malloc_size(ptr) : nil
}

/*
 Invariant:
 malloc_size(malloc(malloc_good_size(size))) >= malloc_good_size(size)
 
 Usually:
 malloc_size(malloc(malloc_good_size(size))) == malloc_good_size(size)
 */
@_effects(readnone) @inline(__always)
internal func _mallocGoodSize(for size: Int) -> Int {
  precondition(size >= 0)
  // Not all allocators will see benefits from rounding up to 16/32 byte aligned
  // but it'll never cause misbehavior, and many reasonable ones will benefit
  if (size <= 128) {
    return (size &+ 15) & ~15;
  }
  if (size <= 256) {
    return (size &+ 31) & ~31;
  }
  return _mallocGoodSizeLarge(for: size)
}

@_effects(readnone)
internal func _mallocGoodSizeLarge(for size: Int) -> Int {
  let goodSize = _swift_stdlib_malloc_good_size(size)
  precondition(goodSize >= size)
  return goodSize
}
