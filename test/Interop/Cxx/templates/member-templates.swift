// RUN: %target-run-simple-swift(-I %S/Inputs -Xfrontend -enable-cxx-interop)
//
// REQUIRES: executable_test
//
// We can't yet call member functions correctly on Windows (SR-13129).
// XFAIL: OS=windows-msvc

import MemberTemplates
import StdlibUnittest

var TemplatesTestSuite = TestSuite("Member Templates")

TemplatesTestSuite.test("Set value - IntWrapper") {
  var w = IntWrapper(11)
  w.setValue(42)
  expectEqual(w.value, 42)
}

TemplatesTestSuite.test("Templated Add") {
  var h = HasMemberTemplates()
  expectEqual(h.addSameTypeParams(2, 1), 3)
  expectEqual(h.addMixedTypeParams(2, 1), 3)
}

TemplatesTestSuite.test("Returns other specialization") {
  let t = TemplateClassWithMemberTemplates<CInt>(42)
  var _5 = 5
  let o = t.toOtherSpec(&_5)
  // TODO: why is "o" Void here? rdar://88443730
}

runAllTests()
