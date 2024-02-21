// RUN: %target-swift-frontend -emit-sil -verify -enable-experimental-feature BorrowingSwitch %s
// RUN: %target-swift-frontend -enable-experimental-feature NoncopyableGenerics -emit-sil -verify -enable-experimental-feature BorrowingSwitch %s

struct Payload: ~Copyable {
    var x: Int
    var y: String
}

enum Foo: ~Copyable {
    case payload(Payload)
    case noPayload
}

enum Bar: ~Copyable {
    case payload(Foo)
    case noPayload
}

struct AOPayload: ~Copyable {
    var x: Any
}

enum AOBar: ~Copyable {
    case loadablePayload(Foo)
    case aoPayload(AOPayload)
}

enum AOBas: ~Copyable {
    case payload(AOBar)
    case noPayload
}

func condition(_: borrowing Payload) -> Bool { fatalError() }
func condition(_: borrowing AOPayload) -> Bool { fatalError() }
func condition(_: borrowing Foo) -> Bool { fatalError() }
func condition(_: borrowing AOBar) -> Bool { fatalError() }
func condition(_: borrowing AOBas) -> Bool { fatalError() }

func hungryCondition(_: consuming Payload) -> Bool { fatalError() }
func hungryCondition(_: consuming AOPayload) -> Bool { fatalError() }
func hungryCondition(_: consuming Foo) -> Bool { fatalError() }
func hungryCondition(_: consuming AOBar) -> Bool { fatalError() }
func hungryCondition(_: consuming AOBas) -> Bool { fatalError() }

func nibble(payload: borrowing Payload) {}
func nibble(payload: borrowing AOPayload) {}
func nibble(payload: borrowing Foo) {}
func nibble(payload: borrowing AOBar) {}
func nibble(payload: borrowing AOBas) {}

func eat(payload: consuming Payload) {}
func eat(payload: consuming AOPayload) {}
func eat(payload: consuming Foo) {}
func eat(payload: consuming AOBar) {}
func eat(payload: consuming AOBas) {}

func test(consuming foo: consuming Bar) { // expected-error{{'foo' used after consume}}
    switch foo {
    case .payload(.payload(_borrowing x))
      where condition(x):
        nibble(payload: x)
    // can't consume _borrowing bindings in either `where` condition 
    // or body
    case .payload(.payload(_borrowing x)) // expected-error{{cannot be consumed}}
      where hungryCondition(x): // expected-note{{consumed here}}
        eat(payload: x) // expected-note{{consumed here}}
    case .payload(.payload(_borrowing x)): // expected-warning{{}}
        break
    case .payload(.noPayload):
        ()
    case .noPayload:
        ()
    }

    switch foo { // expected-note{{consumed here}}
    case .payload(.payload(let x))
      where condition(x):
        nibble(payload: x)
    // can't consume in a `where` condition even if binding is consumable
    case .payload(.payload(let x)) // expected-error{{cannot be consumed}}
      where hungryCondition(x): // expected-note{{consumed here}}
        // consuming in the case block is OK though
        eat(payload: x)
    case .payload(.payload(let x)): // expected-warning{{}}
        break
    case .payload(.noPayload):
        ()
    case .noPayload:
        ()
    }

    switch foo { // expected-note{{used here}}
    case _borrowing x: // expected-warning{{}}
        break
    }
}

@_silgen_name("nibble_bar")
func nibble(bar: borrowing Bar) 

func test(borrowing foo: borrowing Bar) { // expected-error{{'foo' is borrowed and cannot be consumed}}
    // can't use consuming patterns on a borrow
    // TODO: improve diagnostic
    switch foo {
    case .payload(.payload(let x)): // expected-note{{consumed here}} expected-warning{{}}
        break
    case .payload(.noPayload): // expected-note{{consumed here}}
        ()
    case .noPayload:
        ()
    }

    switch foo {
    case .payload(.payload(_borrowing x))
      where condition(x):
        nibble(payload: x)
    case .payload(.payload(_borrowing x)) // expected-error{{'x' is borrowed and cannot be consumed}}
      where hungryCondition(x): // expected-note{{consumed here}}
        eat(payload: x) // expected-note{{consumed here}}
    case .payload(.payload(_borrowing x)): // expected-warning{{}}
        break
    case .payload(.noPayload):
        ()
    case .noPayload:
        ()
    }
}

func testOuterAO(borrowing bas: borrowing AOBas) {
    switch bas {
    case _borrowing x // expected-error{{'x' is borrowed and cannot be consumed}}
      where condition(x):
        nibble(payload: x)
        eat(payload: x) // expected-note {{consumed here}}
    case _borrowing x // expected-error 2 {{'x' is borrowed and cannot be consumed}}
      where hungryCondition(x): // expected-note {{consumed here}}
        nibble(payload: x)
        eat(payload: x) // expected-note {{consumed here}}
    case .payload(_borrowing x)  // expected-error{{'x' is borrowed and cannot be consumed}}
      where condition(x):
        nibble(payload: x)
        eat(payload: x) // expected-note {{consumed here}}
    case .payload(_borrowing x) // expected-error 2 {{'x' is borrowed and cannot be consumed}}
      where hungryCondition(x): // expected-note {{consumed here}}
        nibble(payload: x)
        eat(payload: x)  // expected-note {{consumed here}}
    case .payload(.loadablePayload(_borrowing x)) // expected-error{{'x' is borrowed and cannot be consumed}}
      where condition(x):
        nibble(payload: x)
        eat(payload: x) // expected-note{{consumed here}}
    case .payload(.loadablePayload(.payload(_borrowing x))) // expected-error{{'x' is borrowed and cannot be consumed}}
      where condition(x):
        nibble(payload: x)
        eat(payload: x) // expected-note{{consumed here}}
    case .payload(.aoPayload(_borrowing x)) // expected-error{{'x' is borrowed and cannot be consumed}}
      where condition(x):
        nibble(payload: x)
        eat(payload: x) // expected-note {{consumed here}}
    case .payload(_borrowing x): // expected-error{{'x' is borrowed and cannot be consumed}}
        nibble(payload: x)
        eat(payload: x) // expected-note {{consumed here}}
    case .noPayload:
        break
    }
}

func testOuterAO(consuming bas: consuming AOBas) { // expected-error{{'bas' used after consume}}
    switch bas {
    case _borrowing x // expected-error{{'x' is borrowed and cannot be consumed}}
      where condition(x):
        nibble(payload: x)
        eat(payload: x) // expected-note {{consumed here}}
    case _borrowing x // expected-error 2 {{'x' is borrowed and cannot be consumed}}
      where hungryCondition(x): // expected-note {{consumed here}}
        nibble(payload: x)
        eat(payload: x) // expected-note {{consumed here}}
    case .payload(_borrowing x)  // expected-error{{'x' is borrowed and cannot be consumed}}
      where condition(x):
        nibble(payload: x)
        eat(payload: x) // expected-note {{consumed here}}
    case .payload(_borrowing x) // expected-error 2 {{'x' is borrowed and cannot be consumed}}
      where hungryCondition(x): // expected-note {{consumed here}}
        nibble(payload: x)
        eat(payload: x)  // expected-note {{consumed here}}
    case .payload(.loadablePayload(_borrowing x)) // expected-error{{'x' is borrowed and cannot be consumed}}
      where condition(x):
        nibble(payload: x)
        eat(payload: x) // expected-note{{consumed here}}
    case .payload(.loadablePayload(.payload(_borrowing x))) // expected-error{{'x' is borrowed and cannot be consumed}}
      where condition(x):
        nibble(payload: x)
        eat(payload: x) // expected-note{{consumed here}}
    case .payload(.aoPayload(_borrowing x)) // expected-error{{'x' is borrowed and cannot be consumed}}
      where condition(x):
        nibble(payload: x)
        eat(payload: x) // expected-note {{consumed here}}
    case .payload(_borrowing x): // expected-error{{'x' is borrowed and cannot be consumed}}
        nibble(payload: x)
        eat(payload: x) // expected-note {{consumed here}}
    case .noPayload:
        break
    }

    switch bas { // expected-note {{consumed here}}
    case let x
      where condition(x):
        nibble(payload: x)
        eat(payload: x)
    case let x // expected-error {{borrowed and cannot be consumed}}
      where hungryCondition(x): // expected-note {{consumed here}}
        nibble(payload: x)
        eat(payload: x)
    case .payload(let x)
      where condition(x):
        nibble(payload: x)
        eat(payload: x)
    case .payload(let x) // expected-error {{'unknown' is borrowed and cannot be consumed}}
      where hungryCondition(x): // expected-note {{consumed here}}
        nibble(payload: x)
        eat(payload: x)
    case .payload(.loadablePayload(let x))
      where condition(x):
        nibble(payload: x)
        eat(payload: x)
    case .payload(.loadablePayload(.payload(let x))) // expected-error{{'unknown' is borrowed and cannot be consumed}}
      where hungryCondition(x): // expected-note{{consumed here}}
        nibble(payload: x)
        eat(payload: x)
    case .payload(.aoPayload(let x))
      where condition(x):
        nibble(payload: x)
        eat(payload: x)
    case .payload(let x):
        nibble(payload: x)
        eat(payload: x)
    case .noPayload:
        break
    }

    switch bas {
    case _borrowing x: // expected-warning{{}} expected-note{{used here}}
        break
    }
}

enum E<T>: ~Copyable {
    case a(T)
}

extension E {
    func f() {
        switch self {
        case .a:
            print("a")
        }
    }

    func g() {
        switch self {
        case .a(_borrowing t): // expected-warning{{}}
            print("a")
        }
    }
}

struct Box: ~Copyable {
    let ptr: UnsafeMutablePointer<Int>
}

struct ChonkyBox: ~Copyable {
    let container: Any
}

enum List<Element>: ~Copyable {
    case end
    case more(Element, Box)
}

enum ChonkyList<Element>: ~Copyable {
    case end
    case more(Element, ChonkyBox)
}

extension List {
    var isEmpty: Bool {
        switch self {
        case .end: true
        case .more: false
        }
    }

    var peek: Box {
        _read {
            switch self {
            case .end:
                fatalError()
            case .more(_, _borrowing box):
                yield box
            }
        }
    }

/*
    TODO: type mismatch because of `@moveOnly` wrapper. yield needs to peel it
    off

    var head: Element {
        _read {
            switch self {
            case .end:
                fatalError()
            case .more(_borrowing head, _):
                yield head
            }
        }
    }
*/
}

extension ChonkyList {
    var isEmpty: Bool {
        switch self {
        case .end: true
        case .more: false
        }
    }

    var peek: ChonkyBox {
        _read {
            switch self {
            case .end:
                fatalError()
            case .more(_, _borrowing box):
                yield box
            }
        }
    }

/*
    TODO: type mismatch because of `@moveOnly` wrapper. yield needs to peel it
    off

    var head: Element {
        _read {
            switch self {
            case .end:
                fatalError()
            case .more(_borrowing head, _):
                yield head
            }
        }
    }
*/
}
