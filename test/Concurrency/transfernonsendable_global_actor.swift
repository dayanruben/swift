// RUN: %target-swift-frontend -emit-sil -strict-concurrency=complete -disable-availability-checking -verify -verify-additional-prefix complete- %s -o /dev/null -parse-as-library
// RUN: %target-swift-frontend -emit-sil -strict-concurrency=complete -enable-upcoming-feature RegionBasedIsolation -disable-availability-checking -verify -verify-additional-prefix tns-  %s -o /dev/null -parse-as-library

// REQUIRES: concurrency
// REQUIRES: asserts

////////////////////////
// MARK: Declarations //
////////////////////////

class NonSendableKlass {}
final class SendableKlass : Sendable {}

actor GlobalActorInstance {}

@globalActor
struct GlobalActor {
  static let shared = GlobalActorInstance()
}

func transferToNonIsolated<T>(_ t: T) async {}
@MainActor func transferToMainActor<T>(_ t: T) async {}
@GlobalActor func transferToGlobalActor<T>(_ t: T) async {}
func useValue<T>(_ t: T) {}

var booleanFlag: Bool { false }

/////////////////
// MARK: Tests //
/////////////////

private class NonSendableLinkedList<T> { // expected-complete-note 5{{}}
  var listHead: NonSendableLinkedListNode<T>?

  init() { listHead = nil }
}

private class NonSendableLinkedListNode<T> { // expected-complete-note 3{{}}
  var next: NonSendableLinkedListNode?
  var data: T?

  init() { next = nil }
}

@GlobalActor private var firstList = NonSendableLinkedList<Int>()
@GlobalActor private var secondList = NonSendableLinkedList<Int>()

@GlobalActor func useGlobalActor1() async {
  let x = firstList

  await transferToMainActor(x) // expected-tns-warning {{transferring 'x' may cause a race}}
  // expected-tns-note @-1 {{transferring global actor 'GlobalActor'-isolated 'x' to main actor-isolated callee could cause races between main actor-isolated and global actor 'GlobalActor'-isolated uses}}
  // expected-complete-warning @-2 {{passing argument of non-sendable type 'NonSendableLinkedList<Int>' into main actor-isolated context may introduce data races}}

  let y = secondList.listHead!.next!

  await transferToMainActor(y) // expected-tns-warning {{transferring 'y' may cause a race}}
  // expected-tns-note @-1 {{transferring global actor 'GlobalActor'-isolated 'y' to main actor-isolated callee could cause races between main actor-isolated and global actor 'GlobalActor'-isolated uses}}
  // expected-complete-warning @-2 {{passing argument of non-sendable type 'NonSendableLinkedListNode<Int>' into main actor-isolated context may introduce data races}}
}

@GlobalActor func useGlobalActor2() async {
  var x = NonSendableLinkedListNode<Int>()

  if booleanFlag {
    x = secondList.listHead!.next!
  }

  await transferToMainActor(x) // expected-tns-warning {{transferring 'x' may cause a race}}
  // expected-tns-note @-1 {{transferring global actor 'GlobalActor'-isolated 'x' to main actor-isolated callee could cause races between main actor-isolated and global actor 'GlobalActor'-isolated uses}}
  // expected-complete-warning @-2 {{passing argument of non-sendable type 'NonSendableLinkedListNode<Int>' into main actor-isolated context may introduce data races}}
}

@GlobalActor func useGlobalActor3() async {
  var x = NonSendableLinkedListNode<Int>()

  if booleanFlag {
    x = secondList.listHead!.next!
  }

  await transferToGlobalActor(x)
}

@GlobalActor func useGlobalActor4() async {
  let x = NonSendableLinkedListNode<Int>()

  await transferToGlobalActor(x)

  useValue(x)
}

@GlobalActor func useGlobalActor5() async {
  let x = NonSendableLinkedListNode<Int>()

  await transferToNonIsolated(x) // expected-tns-warning {{transferring 'x' may cause a race}}
  // expected-tns-note @-1 {{transferring disconnected 'x' to nonisolated callee could cause races in between callee nonisolated and local global actor 'GlobalActor'-isolated uses}}
  // expected-complete-warning @-2 {{passing argument of non-sendable type 'NonSendableLinkedListNode<Int>' outside of global actor 'GlobalActor'-isolated context may introduce data races}}

  useValue(x) // expected-tns-note {{use here could race}}
}

private struct StructContainingValue { // expected-complete-note 2{{}}
  var x = NonSendableLinkedList<Int>()
  var y = SendableKlass()
}

@GlobalActor func useGlobalActor6() async {
  var x = StructContainingValue()
  x = StructContainingValue()

  await transferToNonIsolated(x) // expected-tns-warning {{transferring 'x' may cause a race}}
  // expected-tns-note @-1 {{transferring disconnected 'x' to nonisolated callee could cause races in between callee nonisolated and local global actor 'GlobalActor'-isolated uses}}
  // expected-complete-warning @-2 {{passing argument of non-sendable type 'StructContainingValue' outside of global actor 'GlobalActor'-isolated context may introduce data races}}

  useValue(x) // expected-tns-note {{use here could race}}
}

@GlobalActor func useGlobalActor7() async {
  var x = StructContainingValue()
  x.x = firstList

  await transferToNonIsolated(x) // expected-tns-warning {{transferring 'x' may cause a race}}
  // expected-tns-note @-1 {{transferring global actor 'GlobalActor'-isolated 'x' to nonisolated callee could cause races between nonisolated and global actor 'GlobalActor'-isolated uses}}
  // expected-complete-warning @-2 {{passing argument of non-sendable type 'StructContainingValue' outside of global actor 'GlobalActor'-isolated context may introduce data races}}

  useValue(x)
}

@GlobalActor func useGlobalActor8() async {
  var x = (NonSendableLinkedList<Int>(), NonSendableLinkedList<Int>())
  x = (NonSendableLinkedList<Int>(), NonSendableLinkedList<Int>())

  await transferToNonIsolated(x) // expected-tns-warning {{transferring 'x' may cause a race}}
  // expected-tns-note @-1 {{transferring disconnected 'x' to nonisolated callee could cause races in between callee nonisolated and local global actor 'GlobalActor'-isolated uses}}
  // expected-complete-warning @-2 {{passing argument of non-sendable type '(NonSendableLinkedList<Int>, NonSendableLinkedList<Int>)' outside of global actor 'GlobalActor'-isolated context may introduce data races}}
  // expected-complete-warning @-3 {{passing argument of non-sendable type '(NonSendableLinkedList<Int>, NonSendableLinkedList<Int>)' outside of global actor 'GlobalActor'-isolated context may introduce data races}}

  useValue(x) // expected-tns-note {{use here could race}}
}

@GlobalActor func useGlobalActor9() async {
  var x = (NonSendableLinkedList<Int>(), NonSendableLinkedList<Int>())

  x.1 = firstList

  await transferToNonIsolated(x) // expected-tns-warning {{transferring 'x' may cause a race}}
  // expected-tns-note @-1 {{transferring global actor 'GlobalActor'-isolated 'x' to nonisolated callee could cause races between nonisolated and global actor 'GlobalActor'-isolated uses}}
  // expected-complete-warning @-2 {{passing argument of non-sendable type '(NonSendableLinkedList<Int>, NonSendableLinkedList<Int>)' outside of global actor 'GlobalActor'-isolated context may introduce data races}}
  // expected-complete-warning @-3 {{passing argument of non-sendable type '(NonSendableLinkedList<Int>, NonSendableLinkedList<Int>)' outside of global actor 'GlobalActor'-isolated context may introduce data races}}

  useValue(x)
}

struct Clock {
  public func measure<T>(
    _ work: () async throws -> T
  ) async rethrows -> T {
    try await work()
  }

  public func sleep<T>() async throws -> T { fatalError() }
}

// We used to crash when inferring the type for the diagnostic below.
@MainActor func testIndirectParametersHandledCorrectly() async {
  let c = Clock()
  let _: Int = await c.measure { // expected-tns-warning {{main actor-isolated value of type '() async -> Int' transferred to nonisolated context}}
    // expected-complete-warning @-1 {{passing argument of non-sendable type '() async -> Int' outside of main actor-isolated context may introduce data races}}
    // expected-complete-note @-2 {{a function type must be marked '@Sendable' to conform to 'Sendable'}}
    try! await c.sleep()
  }
}
