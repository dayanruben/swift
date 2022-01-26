// RUN: %target-typecheck-verify-swift -enable-requirement-machine-merged-associated-types
// RUN: not %target-swift-frontend -typecheck -debug-generic-signatures %s -enable-requirement-machine-merged-associated-types 2>&1 | %FileCheck %s

// A very elaborate invalid example (see comment in mergeP1AndP2())
struct G<T> {}

protocol P {}
extension G : P where T : P {}

protocol P1 {
  associatedtype T
  associatedtype U where U == G<T>
  associatedtype R : P1
}

protocol P2 {
  associatedtype U : P
  associatedtype R : P2
}

func takesP<T : P>(_: T.Type) {}
// expected-note@-1 {{where 'T' = 'T.R.T'}}
// expected-note@-2 {{where 'T' = 'T.R.R.T'}}
// expected-note@-3 {{where 'T' = 'T.R.R.R.T'}}

// CHECK: Generic signature: <T where T : P1, T : P2>
func mergeP1AndP2<T : P1 & P2>(_: T) {
  // P1 implies that T.(R)*.U == G<T.(R)*.T>, and P2 implies that T.(R)*.U : P.
  //
  // These together would seem to imply that G<T.(R)*.T> : P, therefore
  // the conditional conformance G : P should imply that T.(R)*.T : P.
  //
  // However, this would require us to infer an infinite number of
  // conformance requirements in the signature of mergeP1AndP2() of the
  // form T.(R)*.T : P.
  //
  // Since we're unable to represent that, make sure that a) we don't crash,
  // b) we reject the conformance T.(R)*.T : P.

  takesP(T.T.self)
  takesP(T.R.T.self) // expected-error {{global function 'takesP' requires that 'T.R.T' conform to 'P'}}
  takesP(T.R.R.T.self) // expected-error {{global function 'takesP' requires that 'T.R.R.T' conform to 'P'}}
  takesP(T.R.R.R.T.self) // expected-error {{global function 'takesP' requires that 'T.R.R.R.T' conform to 'P'}}
}