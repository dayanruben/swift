//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

@available(SwiftStdlib 5.9, *)
public struct ObservationRegistrar: Sendable {
  struct State: @unchecked Sendable {
    struct Observation {
      var properties: Set<AnyKeyPath>
      var observer: @Sendable () -> Void
    }
    
    var id = 0
    var observations = [Int : Observation]()
    var lookups = [AnyKeyPath : Set<Int>]()
    
    mutating func generateId() -> Int {
      defer { id &+= 1 }
      return id
    }
    
    mutating func registerTracking(for properties: Set<AnyKeyPath>, observer: @Sendable @escaping () -> Void) -> Int {
      let id = generateId()
      observations[id] = Observation(properties: properties, observer: observer)
      for keyPath in properties {
        lookups[keyPath, default: []].insert(id)
      }
      return id
    }
    
    mutating func cancel(_ id: Int) {
      if let tracking = observations.removeValue(forKey: id) {
        for keyPath in tracking.properties {
          if var ids = lookups[keyPath] {
            ids.remove(id)
            if ids.count == 0 {
              lookups.removeValue(forKey: keyPath)
            } else {
              lookups[keyPath] = ids
            }
          }
        }
      }
    }
    
    mutating func willSet(keyPath: AnyKeyPath) -> [@Sendable () -> Void] {
      var observers = [@Sendable () -> Void]()
      if let ids = lookups[keyPath] {
        for id in ids {
          if let observation = observations[id] {
            observers.append(observation.observer)
            cancel(id)
          }
        }
      }
      return observers
    }
  }
  
  struct Context: Sendable {
    let state = _ManagedCriticalState(State())
    
    var id: ObjectIdentifier { state.id }
    
    func registerTracking(for properties: Set<AnyKeyPath>, observer: @Sendable @escaping () -> Void) -> Int {
      state.withCriticalRegion { $0.registerTracking(for: properties, observer: observer) }
    }
    
    func cancel(_ id: Int) {
      state.withCriticalRegion { $0.cancel(id) }
    }
    
    func willSet<Subject, Member>(
       _ subject: Subject,
       keyPath: KeyPath<Subject, Member>
    ) {
      let actions = state.withCriticalRegion { $0.willSet(keyPath: keyPath) }
      for action in actions {
        action()
      }
    }
  }
  
  let context = Context()
  
  public init() {
  }

  public func access<Subject: Observable, Member>(
      _ subject: Subject,
      keyPath: KeyPath<Subject, Member>
  ) {
    if let trackingPtr = _ThreadLocal.value?
      .assumingMemoryBound(to: ObservationTracking._AccessList?.self) {
      if trackingPtr.pointee == nil {
        trackingPtr.pointee = ObservationTracking._AccessList()
      }
      trackingPtr.pointee?.addAccess(keyPath: keyPath, context: context)
    }
  }
  
  public func willSet<Subject: Observable, Member>(
      _ subject: Subject,
      keyPath: KeyPath<Subject, Member>
  ) {
    context.willSet(subject, keyPath: keyPath)
  }
  
  public func didSet<Subject: Observable, Member>(
      _ subject: Subject,
      keyPath: KeyPath<Subject, Member>
  ) {
    
  }
  
  public func withMutation<Subject: Observable, Member, T>(
    of subject: Subject,
    keyPath: KeyPath<Subject, Member>,
    _ mutation: () throws -> T
  ) rethrows -> T {
    willSet(subject, keyPath: keyPath)
    defer { didSet(subject, keyPath: keyPath) }
    return try mutation()
  }
}