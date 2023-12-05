//===--- SequenceUtilities.swift ------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Basic

/// Types conforming to `HasName` will be displayed by their name (instead of the
/// full object) in collection descriptions.
///
/// This is useful to make collections, e.g. of BasicBlocks or Functions, readable.
public protocol HasShortDescription {
  var shortDescription: String { get }
}

private struct CustomMirrorChild : CustomStringConvertible, NoReflectionChildren {
  public var description: String
  
  public init(description: String) { self.description = description }
}

/// Makes a Sequence's `description` and `customMirror` formatted like Array, e.g. [a, b, c].
public protocol FormattedLikeArray : Sequence, CustomStringConvertible, CustomReflectable {
}

extension FormattedLikeArray {
  /// Display a Sequence in an array like format, e.g. [a, b, c]
  public var description: String {
    "[" + map {
      if let named = $0 as? HasShortDescription {
        return named.shortDescription
      }
      return String(describing: $0)
    }.joined(separator: ", ") + "]"
  }
  
  /// The mirror which adds the children of a Sequence, similar to `Array`.
  public var customMirror: Mirror {
    // If the one-line description is not too large, print that instead of the
    // children in separate lines.
    if description.count <= 80 {
      return Mirror(self, children: [])
    }
    let c: [Mirror.Child] = map {
      let val: Any
      if let named = $0 as? HasShortDescription {
        val = CustomMirrorChild(description: named.shortDescription)
      } else {
        val = $0
      }
      return (label: nil, value: val)
    }
    return Mirror(self, children: c, displayStyle: .collection)
  }
}

/// RandomAccessCollection which bridges to some C++ array.
///
/// It fixes the default reflection for bridged random access collections, which usually have a
/// `bridged` stored property.
/// Conforming to this protocol displays the "real" children  not just `bridged`.
public protocol BridgedRandomAccessCollection : RandomAccessCollection, CustomReflectable {
}

extension BridgedRandomAccessCollection {
  public var customMirror: Mirror {
    Mirror(self, children: self.map { (label: nil, value: $0 as Any) })
  }
}

/// A Sequence which is not consuming and therefore behaves like a Collection.
///
/// Many sequences in SIL and the optimizer should be collections but cannot
/// because their Index cannot conform to Comparable. Those sequences conform
/// to CollectionLikeSequence.
///
/// For convenience it also inherits from FormattedLikeArray.
public protocol CollectionLikeSequence : FormattedLikeArray {
}

public extension CollectionLikeSequence {
  var isEmpty: Bool { !contains(where: { _ in true }) }
}

// Also make the lazy sequences a CollectionLikeSequence if the underlying sequence is one.

extension LazySequence : CollectionLikeSequence,
                         FormattedLikeArray, CustomStringConvertible, CustomReflectable
                         where Base: CollectionLikeSequence {}

extension FlattenSequence : CollectionLikeSequence,
                            FormattedLikeArray, CustomStringConvertible, CustomReflectable
                            where Base: CollectionLikeSequence {}

extension LazyMapSequence : CollectionLikeSequence,
                            FormattedLikeArray, CustomStringConvertible, CustomReflectable
                            where Base: CollectionLikeSequence {}

extension LazyFilterSequence : CollectionLikeSequence,
                               FormattedLikeArray, CustomStringConvertible, CustomReflectable
                               where Base: CollectionLikeSequence {}
