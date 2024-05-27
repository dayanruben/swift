// RUN: %target-swift-frontend  -disable-availability-checking %s -emit-sil -o /dev/null -verify -verify-additional-prefix without-transferring-
// RUN: %target-swift-frontend  -disable-availability-checking %s -emit-sil -o /dev/null -verify -strict-concurrency=targeted -verify-additional-prefix without-transferring-
// RUN: %target-swift-frontend  -disable-availability-checking %s -emit-sil -o /dev/null -verify -strict-concurrency=complete -disable-region-based-isolation-with-strict-concurrency -verify-additional-prefix without-transferring- -disable-transferring-args-and-results-with-region-based-isolation -disable-sending-args-and-results-with-region-based-isolation
// RUN: %target-swift-frontend  -disable-availability-checking %s -emit-sil -o /dev/null -verify -strict-concurrency=complete -disable-transferring-args-and-results-with-region-based-isolation -disable-sending-args-and-results-with-region-based-isolation -verify-additional-prefix without-transferring-
// RUN: %target-swift-frontend  -disable-availability-checking %s -emit-sil -o /dev/null -verify -strict-concurrency=complete

// REQUIRES: concurrency
// REQUIRES: asserts

actor MyActor {
  let immutable: Int = 17
  var text: [String] = []

  func synchronous() -> String { text.first ?? "nothing" }
  func asynchronous() async -> String { synchronous() }

  func testAsyncLetIsolation() async {
    async let x = self.synchronous()

    async let y = await self.asynchronous()

    async let z = synchronous()

    var localText = text
    async let w = localText.removeLast() // expected-without-transferring-warning {{mutation of captured var 'localText' in concurrently-executing code}}

    _ = await x
    _ = await y
    _ = await z
    _ = await w
  }
}

func outside() async {
  let a = MyActor()
  async let x = a.synchronous() // okay, await is implicit
  async let y = await a.synchronous()
  _ = await x
  _ = await y
}
