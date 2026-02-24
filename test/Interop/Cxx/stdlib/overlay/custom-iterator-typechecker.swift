// RUN: %target-typecheck-verify-swift -verify-ignore-unrelated -suppress-notes -I %S/Inputs -cxx-interoperability-mode=default -Xcc -std=c++20 -DCPP20 -verify-additional-prefix cpp20-
// RUN: %target-typecheck-verify-swift -verify-ignore-unrelated -suppress-notes -I %S/Inputs -cxx-interoperability-mode=default

// Check whether each of the custom iterator types in Inputs/custom-iterator.h
// conform to the various iterator protocols from the C++ overlay.
//
// Note that we only detect contiguous iterator when C++'20 is enabled.

import CustomIterator

func checkInput<It: UnsafeCxxInputIterator>(_ _: It) {}
func checkRandomAccess<It: UnsafeCxxRandomAccessIterator>(_ _: It) {}
func checkContiguous<It: UnsafeCxxContiguousIterator>(_ _: It) {}
func checkMutableInput<It: UnsafeCxxMutableInputIterator>(_ _: It) {}
func checkMutableRandomAccess<It: UnsafeCxxMutableRandomAccessIterator>(_ _: It) {}
func checkMutableContiguous<It: UnsafeCxxMutableContiguousIterator>(_ _: It) {}

func check(it: ConstIterator) {
  checkInput(it)
  checkRandomAccess(it)         // expected-error {{requires}}
  checkContiguous(it)           // expected-error {{requires}}
  checkMutableInput(it)         // expected-error {{requires}}
  checkMutableRandomAccess(it)  // expected-error {{requires}}
  checkMutableContiguous(it)    // expected-error {{requires}}
}

func check(it: ConstRACIterator) {
  checkInput(it)
  checkRandomAccess(it)
  checkContiguous(it)           // expected-error {{requires}}
  checkMutableInput(it)         // expected-error {{requires}}
  checkMutableRandomAccess(it)  // expected-error {{requires}}
  checkMutableContiguous(it)    // expected-error {{requires}}
}

func check(it: ConstRACIteratorRefPlusEq) {
  checkInput(it)
  checkRandomAccess(it)
  checkContiguous(it)           // expected-error {{requires}}
  checkMutableInput(it)         // expected-error {{requires}}
  checkMutableRandomAccess(it)  // expected-error {{requires}}
  checkMutableContiguous(it)    // expected-error {{requires}}
}

func check(it: ConstIteratorOutOfLineEq) {
  checkInput(it)
  checkRandomAccess(it)         // expected-error {{requires}}
  checkContiguous(it)           // expected-error {{requires}}
  checkMutableInput(it)         // expected-error {{requires}}
  checkMutableRandomAccess(it)  // expected-error {{requires}}
  checkMutableContiguous(it)    // expected-error {{requires}}
}

func check(it: MinimalIterator) {
  checkInput(it)
  checkRandomAccess(it)         // expected-error {{requires}}
  checkContiguous(it)           // expected-error {{requires}}
  checkMutableInput(it)         // expected-error {{requires}}
  checkMutableRandomAccess(it)  // expected-error {{requires}}
  checkMutableContiguous(it)    // expected-error {{requires}}
}

func check(it: ForwardIterator) {
  checkInput(it)
  checkRandomAccess(it)         // expected-error {{requires}}
  checkContiguous(it)           // expected-error {{requires}}
  checkMutableInput(it)         // expected-error {{requires}}
  checkMutableRandomAccess(it)  // expected-error {{requires}}
  checkMutableContiguous(it)    // expected-error {{requires}}
}

func check(it: HasCustomIteratorTag) {
  checkInput(it)
  checkRandomAccess(it)         // expected-error {{requires}}
  checkContiguous(it)           // expected-error {{requires}}
  checkMutableInput(it)         // expected-error {{requires}}
  checkMutableRandomAccess(it)  // expected-error {{requires}}
  checkMutableContiguous(it)    // expected-error {{requires}}
}

func check(it: HasCustomRACIteratorTag) {
  checkInput(it)
  checkRandomAccess(it)
  checkContiguous(it)           // expected-error {{requires}}
  checkMutableInput(it)         // expected-error {{requires}}
  checkMutableRandomAccess(it)  // expected-error {{requires}}
  checkMutableContiguous(it)    // expected-error {{requires}}
}

func check(it: HasCustomInheritedRACIteratorTag) {
  checkInput(it)
  checkRandomAccess(it)
  checkContiguous(it)           // expected-error {{requires}}
  checkMutableInput(it)         // expected-error {{requires}}
  checkMutableRandomAccess(it)  // expected-error {{requires}}
  checkMutableContiguous(it)    // expected-error {{requires}}
}

func check(it: HasCustomIteratorTagInline) {
  checkInput(it)
  checkRandomAccess(it)         // expected-error {{requires}}
  checkContiguous(it)           // expected-error {{requires}}
  checkMutableInput(it)         // expected-error {{requires}}
  checkMutableRandomAccess(it)  // expected-error {{requires}}
  checkMutableContiguous(it)    // expected-error {{requires}}
}

func check(it: HasTypedefIteratorTag) {
  checkInput(it)
  checkRandomAccess(it)         // expected-error {{requires}}
  checkContiguous(it)           // expected-error {{requires}}
  checkMutableInput(it)         // expected-error {{requires}}
  checkMutableRandomAccess(it)  // expected-error {{requires}}
  checkMutableContiguous(it)    // expected-error {{requires}}
}

func check(it: MutableRACIterator) {
  checkInput(it)
  checkRandomAccess(it)
  checkContiguous(it)           // expected-error {{requires}}
  checkMutableInput(it)
  checkMutableRandomAccess(it)
  checkMutableContiguous(it)    // expected-error {{requires}}
}

func check(it: NonReferenceDereferenceOperator) {
  checkInput(it)
  checkRandomAccess(it)         // expected-error {{requires}}
  checkContiguous(it)           // expected-error {{requires}}
  checkMutableInput(it)         // expected-error {{requires}}
  checkMutableRandomAccess(it)  // expected-error {{requires}}
  checkMutableContiguous(it)    // expected-error {{requires}}
}

#if CPP20

func check(it: ConstContiguousIterator) {
  checkInput(it)
  checkRandomAccess(it)
  checkContiguous(it)
  checkMutableInput(it)         // expected-cpp20-error {{requires}}
  checkMutableRandomAccess(it)  // expected-cpp20-error {{requires}}
  checkMutableContiguous(it)    // expected-cpp20-error {{requires}}
}

func check(it: HasCustomContiguousIteratorTag) {
  checkInput(it)
  checkRandomAccess(it)
  checkContiguous(it)
  checkMutableInput(it)         // expected-cpp20-error {{requires}}
  checkMutableRandomAccess(it)  // expected-cpp20-error {{requires}}
  checkMutableContiguous(it)    // expected-cpp20-error {{requires}}
}

func check(it: MutableContiguousIterator) {
  checkInput(it)
  checkRandomAccess(it)
  checkContiguous(it)
  checkMutableInput(it)
  checkMutableRandomAccess(it)
  checkMutableContiguous(it)
}

func check(it: HasNoContiguousIteratorConcept) {
  checkInput(it)
  checkRandomAccess(it)
  checkContiguous(it)           // expected-cpp20-error {{requires}}
  checkMutableInput(it)         // expected-cpp20-error {{requires}}
  checkMutableRandomAccess(it)  // expected-cpp20-error {{requires}}
  checkMutableContiguous(it)    // expected-cpp20-error {{requires}}
}

#endif

func check(it: HasNoIteratorCategory) {
  checkInput(it)                // expected-error {{requires}}
  checkRandomAccess(it)         // expected-error {{requires}}
  checkContiguous(it)           // expected-error {{requires}}
  checkMutableInput(it)         // expected-error {{requires}}
  checkMutableRandomAccess(it)  // expected-error {{requires}}
  checkMutableContiguous(it)    // expected-error {{requires}}
}

func check(it: HasInvalidIteratorCategory) {
  checkInput(it)                // expected-error {{requires}}
  checkRandomAccess(it)         // expected-error {{requires}}
  checkContiguous(it)           // expected-error {{requires}}
  checkMutableInput(it)         // expected-error {{requires}}
  checkMutableRandomAccess(it)  // expected-error {{requires}}
  checkMutableContiguous(it)    // expected-error {{requires}}
}

func check(it: HasNoEqualEqual) {
  checkInput(it)                // expected-error {{requires}}
  checkRandomAccess(it)         // expected-error {{requires}}
  checkContiguous(it)           // expected-error {{requires}}
  checkMutableInput(it)         // expected-error {{requires}}
  checkMutableRandomAccess(it)  // expected-error {{requires}}
  checkMutableContiguous(it)    // expected-error {{requires}}
}

func check(it: HasInvalidEqualEqual) {
  checkInput(it)                // expected-error {{requires}}
  checkRandomAccess(it)         // expected-error {{requires}}
  checkContiguous(it)           // expected-error {{requires}}
  checkMutableInput(it)         // expected-error {{requires}}
  checkMutableRandomAccess(it)  // expected-error {{requires}}
  checkMutableContiguous(it)    // expected-error {{requires}}
}

func check(it: HasNoIncrementOperator) {
  checkInput(it)                // expected-error {{requires}}
  checkRandomAccess(it)         // expected-error {{requires}}
  checkContiguous(it)           // expected-error {{requires}}
  checkMutableInput(it)         // expected-error {{requires}}
  checkMutableRandomAccess(it)  // expected-error {{requires}}
  checkMutableContiguous(it)    // expected-error {{requires}}
}

func check(it: HasNoPreIncrementOperator) {
  checkInput(it)                // expected-error {{requires}}
  checkRandomAccess(it)         // expected-error {{requires}}
  checkContiguous(it)           // expected-error {{requires}}
  checkMutableInput(it)         // expected-error {{requires}}
  checkMutableRandomAccess(it)  // expected-error {{requires}}
  checkMutableContiguous(it)    // expected-error {{requires}}
}

func check(it: HasNoDereferenceOperator) {
  checkInput(it)                // expected-error {{requires}}
  checkRandomAccess(it)         // expected-error {{requires}}
  checkContiguous(it)           // expected-error {{requires}}
  checkMutableInput(it)         // expected-error {{requires}}
  checkMutableRandomAccess(it)  // expected-error {{requires}}
  checkMutableContiguous(it)    // expected-error {{requires}}
}

func check(it: TemplatedIteratorInt) {
  checkInput(it)
  checkRandomAccess(it)         // expected-error {{requires}}
  checkContiguous(it)           // expected-error {{requires}}
  checkMutableInput(it)         // expected-error {{requires}}
  checkMutableRandomAccess(it)  // expected-error {{requires}}
  checkMutableContiguous(it)    // expected-error {{requires}}
}


func check(it: TemplatedIteratorOutOfLineEqInt) {
  checkInput(it)
  checkRandomAccess(it)         // expected-error {{requires}}
  checkContiguous(it)           // expected-error {{requires}}
  checkMutableInput(it)         // expected-error {{requires}}
  checkMutableRandomAccess(it)  // expected-error {{requires}}
  checkMutableContiguous(it)    // expected-error {{requires}}
}


func check(it: TemplatedRACIteratorOutOfLineEqInt) {
  checkInput(it)
  checkRandomAccess(it)
  checkContiguous(it)           // expected-error {{requires}}
  checkMutableInput(it)         // expected-error {{requires}}
  checkMutableRandomAccess(it)  // expected-error {{requires}}
  checkMutableContiguous(it)    // expected-error {{requires}}
}

func check(it: BaseIntIterator) {
  checkInput(it)                // expected-error {{requires}}
  checkRandomAccess(it)         // expected-error {{requires}}
  checkContiguous(it)           // expected-error {{requires}}
  checkMutableInput(it)         // expected-error {{requires}}
  checkMutableRandomAccess(it)  // expected-error {{requires}}
  checkMutableContiguous(it)    // expected-error {{requires}}
}

func check(it: InheritedConstIterator) {
  checkInput(it)
  checkRandomAccess(it)         // expected-error {{requires}}
  checkContiguous(it)           // expected-error {{requires}}
  checkMutableInput(it)         // expected-error {{requires}}
  checkMutableRandomAccess(it)  // expected-error {{requires}}
  checkMutableContiguous(it)    // expected-error {{requires}}
}

func check(it: InheritedTemplatedConstIteratorInt) {
  checkInput(it)
  checkRandomAccess(it)         // expected-error {{requires}}
  checkContiguous(it)           // expected-error {{requires}}
  checkMutableInput(it)         // expected-error {{requires}}
  checkMutableRandomAccess(it)  // expected-error {{requires}}
  checkMutableContiguous(it)    // expected-error {{requires}}
}

func check(it: InheritedTemplatedConstRACIteratorInt) {
  checkInput(it)
  checkRandomAccess(it)
  checkContiguous(it)           // expected-error {{requires}}
  checkMutableInput(it)         // expected-error {{requires}}
  checkMutableRandomAccess(it)  // expected-error {{requires}}
  checkMutableContiguous(it)    // expected-error {{requires}}
}

func check(it: InheritedTemplatedConstRACIteratorOutOfLineOpsInt) {
  checkInput(it)
  checkRandomAccess(it)
  checkContiguous(it)           // expected-error {{requires}}
  checkMutableInput(it)         // expected-error {{requires}}
  checkMutableRandomAccess(it)  // expected-error {{requires}}
  checkMutableContiguous(it)    // expected-error {{requires}}
}

func check(it: InputOutputIterator) {
  checkInput(it)
  checkRandomAccess(it)         // expected-error {{requires}}
  checkContiguous(it)           // expected-error {{requires}}
  checkMutableInput(it)
  checkMutableRandomAccess(it)  // expected-error {{requires}}
  checkMutableContiguous(it)    // expected-error {{requires}}
}

func check(it: InputOutputConstIterator) {
  checkInput(it)
  checkRandomAccess(it)         // expected-error {{requires}}
  checkContiguous(it)           // expected-error {{requires}}
  checkMutableInput(it)
  checkMutableRandomAccess(it)  // expected-error {{requires}}
  checkMutableContiguous(it)    // expected-error {{requires}}
}

func check(it: ProtectedIteratorBase) {
  checkInput(it)                // expected-error {{requires}}
  checkRandomAccess(it)         // expected-error {{requires}}
  checkContiguous(it)           // expected-error {{requires}}
  checkMutableInput(it)         // expected-error {{requires}}
  checkMutableRandomAccess(it)  // expected-error {{requires}}
  checkMutableContiguous(it)    // expected-error {{requires}}
}

func check(it: HasInheritedProtectedCopyConstructor) {
  checkInput(it)                // expected-error {{requires}} // FIXME
  checkRandomAccess(it)         // expected-error {{requires}}
  checkContiguous(it)           // expected-error {{requires}}
  checkMutableInput(it)         // expected-error {{requires}} // FIXME
  checkMutableRandomAccess(it)  // expected-error {{requires}}
  checkMutableContiguous(it)    // expected-error {{requires}}
}
