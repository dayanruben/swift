// RUN: %target-typecheck-verify-swift
// RUN: %target-swift-frontend -emit-silgen %s -parse-as-library -module-name Test -experimental-lazy-typecheck

// This file should type check successfully.

// rdar://117442510
public protocol P1 {
  associatedtype Value

  func makeValue() -> Value
  func useProducedValue(_ produceValue: () -> Value)
}

public typealias A1 = S1.Value

public struct S1: P1 {
  public func makeValue() -> Int { return 1 }
  public func useProducedValue(_ produceValue: () -> Value) {
    _ = produceValue()
  }
}

// rdar://56672411
public protocol P2 {
  associatedtype X = Int
  func foo(_ x: X)
}

public typealias A2 = S2.X

public struct S2: P2 {
  public func bar(_ x: X) {}
  public func foo(_ x: X) {}
}

// https://github.com/apple/swift/issues/57355
public protocol P3 {
  associatedtype T
  var a: T { get }
  var b: T { get }
  var c: T { get }
}

public typealias A3 = S3.T

public struct S3: P3 {
  public let a: Int
  public let b: T
  public let c: T
}

// Regression tests
public protocol P4 {
  associatedtype A
  func f(_: A)
}

public typealias A = Int

public typealias A4 = S4.A

public struct S4: P4 {
  public func f(_: A) {}
}

public typealias A5 = OuterGeneric<Int>.Inner.A

public struct OuterGeneric<A> {
  public struct Inner: P4 {
    public func f(_: A) {  }
  }
}

public typealias A6 = OuterNested.Inner.A

public struct OuterNested {
  public struct A {}

  public struct Inner: P4 {
    public func f(_: A) {}
  }
}

public protocol CaseProtocol {
  associatedtype A = Int
  static func a(_: A) -> Self
  static func b(_: A) -> Self
  static func c(_: A) -> Self
}

public typealias A7 = CaseWitness.A

public enum CaseWitness: CaseProtocol {
  case a(_: A)
  case b(_: A)
  case c(_: A)
}
