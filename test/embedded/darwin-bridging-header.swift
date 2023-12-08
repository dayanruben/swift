// RUN: %empty-directory(%t)
// RUN: %{python} %utils/split_file.py -o %t %s

// RUN: %target-swift-frontend %t/Main.swift %S/Inputs/print.swift -import-bridging-header %t/BridgingHeader.h -enable-experimental-feature Embedded -c -o %t/main.o
// RUN: %target-clang %t/main.o -o %t/a.out -dead_strip
// RUN: %target-run %t/a.out | %FileCheck %s

// REQUIRES: swift_in_compiler
// REQUIRES: executable_test
// REQUIRES: optimized_stdlib
// REQUIRES: VENDOR=apple
// REQUIRES: OS=macosx

// Temporarily disabled:
// REQUIRES: rdar119283700

// BEGIN BridgingHeader.h

#include <unistd.h>

// BEGIN Main.swift

@main
struct Main {
  static func main() {
    let x = getuid()
    print("User id: ")
    print(x)
  }
}

// CHECK: User id:
