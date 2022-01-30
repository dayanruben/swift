// RUN: %empty-directory(%t)
// RUN: %target-swift-frontend-emit-module -emit-module-path %t/FakeDistributedActorSystems.swiftmodule -module-name FakeDistributedActorSystems -disable-availability-checking %S/../Inputs/FakeDistributedActorSystems.swift
// RUN: %target-build-swift -module-name main -Xfrontend -enable-experimental-distributed -Xfrontend -disable-availability-checking -j2 -parse-as-library -I %t %s %S/../Inputs/FakeDistributedActorSystems.swift -o %t/a.out
// RUN: %target-run %t/a.out | %FileCheck %s --color --dump-input=always

// REQUIRES: executable_test
// REQUIRES: concurrency
// REQUIRES: distributed

// rdar://76038845
// UNSUPPORTED: use_os_stdlib
// UNSUPPORTED: back_deployment_runtime

// FIXME(distributed): Distributed actors currently have some issues on windows, isRemote always returns false. rdar://82593574
// UNSUPPORTED: windows

// FIXME(distributed): remote calls seem to hang on linux - rdar://87240034
// UNSUPPORTED: linux

// rdar://87568630 - segmentation fault on 32-bit WatchOS simulator
// UNSUPPORTED: OS=watchos && CPU=i386

// rdar://88228867 - remoteCall_* tests have been disabled due to random failures
// REQUIRES: rdar88228867

import _Distributed
import FakeDistributedActorSystems

typealias DefaultDistributedActorSystem = FakeRoundtripActorSystem

distributed actor Greeter {
  distributed func echo(name: String) -> String {
    return "Echo: \(name)"
  }
}

func test() async throws {
  let system = DefaultDistributedActorSystem()

  let local = Greeter(system: system)
  let ref = try Greeter.resolve(id: local.id, using: system)

  let reply = try await ref.echo(name: "Caplin")
  // CHECK: >> remoteCall: on:main.Greeter), target:RemoteCallTarget(_mangledName: "$s4main7GreeterC4echo4nameS2S_tFTE"), invocation:FakeInvocationEncoder(genericSubs: [], arguments: ["Caplin"], returnType: Optional(Swift.String), errorType: nil), throwing:Swift.Never, returning:Swift.String

  // CHECK: << remoteCall return: Echo: Caplin
  print("reply: \(reply)")
  // CHECK: reply: Echo: Caplin
}

@main struct Main {
  static func main() async {
    try! await test()
  }
}
