// RUN: %target-swift-frontend %s -emit-ir -g -o - \
// RUN:    -module-name M -enable-experimental-concurrency \
// RUN:    -parse-as-library | %FileCheck %s
// REQUIRES: concurrency
// UNSUPPORTED: CPU=arm64e

func use<T>(_ t: T) {}
func forceSplit() async {
}
func withGenericArg<T>(_ msg: T) async {
  // This odd debug info is part of a contract with CoroSplit/CoroFrame to fix
  // this up after coroutine splitting.
  // CHECK-LABEL: {{^define .*}} @"$s1M14withGenericArgyyxYlF"(%swift.task* %0, %swift.executor* %1, %swift.context* swiftasync %2)
  // CHECK: call void @llvm.dbg.declare(metadata %swift.context* %2,
  // CHECK-SAME:   metadata ![[MSG:[0-9]+]], metadata !DIExpression(
  // CHECK-SAME:     DW_OP_plus_uconst, {{[0-9]+}}, DW_OP_deref))
  // CHECK: call void @llvm.dbg.declare(metadata %swift.context* %2,
  // CHECK-SAME:   metadata ![[TAU:[0-9]+]], metadata !DIExpression(
  // CHECK-SAME:     DW_OP_plus_uconst, {{[0-9]+}}))

  await forceSplit()
  // CHECK-LABEL: {{^define .*}} @"$s1M14withGenericArgyyxYlF.resume.0"(i8* %0, i8* %1, i8* swiftasync %2)
  // CHECK: call void @llvm.dbg.declare(metadata i8* %2,
  // CHECK-SAME:   metadata ![[TAU_R:[0-9]+]], metadata !DIExpression(
  // CHECK-SAME:     DW_OP_plus_uconst, [[OFFSET:[0-9]+]],
  // CHECK-SAME:     DW_OP_plus_uconst, {{[0-9]+}}))
  // CHECK: call void @llvm.dbg.declare(metadata i8* %2,
  // CHECK-SAME:   metadata ![[MSG_R:[0-9]+]], metadata !DIExpression(
  // CHECK-SAME:     DW_OP_plus_uconst, [[OFFSET]],
  // CHECK-SAME:     DW_OP_plus_uconst, {{[0-9]+}}, DW_OP_deref))

  use(msg)
}
// CHECK-LABEL: {{^define }}
@main struct Main {
  static func main() async {
    await withGenericArg("hello (asynchronously)")
  }
}
// CHECK: ![[MSG]] = !DILocalVariable(name: "msg", arg: 1,
// CHECK: ![[TAU]] = !DILocalVariable(name: "$\CF\84_0_0",
// CHECK: ![[TAU_R]] = !DILocalVariable(name: "$\CF\84_0_0",
// CHECK: ![[MSG_R]] = !DILocalVariable(name: "msg", arg: 1,

