//===----------------------------------------------------------------------===//
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

public protocol CxxSet<Element> {
  associatedtype Element
  associatedtype Size: BinaryInteger
  associatedtype InsertionResult // std::pair<iterator, bool>

  init()

  @discardableResult
  mutating func __insertUnsafe(_ element: Element) -> InsertionResult

  func count(_ element: Element) -> Size
}

extension CxxSet {
  /// Creates a C++ set containing the elements of a Swift Sequence.
  ///
  /// This initializes the set by copying every element of the sequence.
  ///
  /// - Complexity: O(*n*), where *n* is the number of elements in the Swift
  ///   sequence
  @inlinable
  public init<S: Sequence>(_ sequence: S) where S.Element == Element {
    self.init()
    for item in sequence {
      self.__insertUnsafe(item)
    }
  }

  @inlinable
  public func contains(_ element: Element) -> Bool {
    return count(element) > 0
  }
}
