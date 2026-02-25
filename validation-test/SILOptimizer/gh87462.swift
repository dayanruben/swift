// RUN: %target-swift-frontend -target %target-cpu-apple-macos14 -parse-as-library -c -O %s

// REQUIRES: VENDOR=apple
// REQUIRES: OS=macosx

@MainActor
final class Foo<T> {
  isolated deinit {}
}
