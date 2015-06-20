import XCTest
import Nimble

class RaisesExceptionTest: XCTestCase {
    var exception = NSException(name: "laugh", reason: "Lulz", userInfo: ["key": "value"])

    func testPositiveMatches() {
        expect { self.exception.raise() }.to(raiseException())
        expect { self.exception.raise() }.to(raiseException(named: "laugh"))
        expect { self.exception.raise() }.to(raiseException(named: "laugh", reason: "Lulz"))
        expect { self.exception.raise() }.to(raiseException(named: "laugh", reason: "Lulz", userInfo: ["key": "value"]))
    }

    func testPositiveMatchesWithClosures() {
        expect { self.exception.raise() }.to(raiseException { exception in
            expect(exception.name).to(equal("laugh"))
        })
        expect { self.exception.raise() }.to(raiseException(named: "laugh") { exception in
            expect(exception.name).to(beginWith("lau"))
        })
        expect { self.exception.raise() }.to(raiseException(named: "laugh", reason: "Lulz") { exception in
            expect(exception.name).to(beginWith("lau"))
        })
        expect { self.exception.raise() }.to(raiseException(named: "laugh", reason: "Lulz", userInfo: ["key": "value"]) { exception in
            expect(exception.name).to(beginWith("lau"))
        })

        expect { self.exception.raise() }.to(raiseException(named: "laugh") { exception in
            expect(exception.name).toNot(beginWith("as"))
        })
        expect { self.exception.raise() }.to(raiseException(named: "laugh", reason: "Lulz") { exception in
            expect(exception.name).toNot(beginWith("df"))
        })
        expect { self.exception.raise() }.to(raiseException(named: "laugh", reason: "Lulz", userInfo: ["key": "value"]) { exception in
            expect(exception.name).toNot(beginWith("as"))
        })
    }

    func testNegativeMatches() {
        failsWithErrorMessage("expected to raise exception with name <foo>, got NSException { name=laugh, reason='Lulz', userInfo=[key: value] }") {
            expect { self.exception.raise() }.to(raiseException(named: "foo"))
        }

        failsWithErrorMessage("expected to raise exception with name <laugh> with reason <bar>, got NSException { name=laugh, reason='Lulz', userInfo=[key: value] }") {
            expect { self.exception.raise() }.to(raiseException(named: "laugh", reason: "bar"))
        }

        failsWithErrorMessage(
            "expected to raise exception with name <laugh> with reason <Lulz> with userInfo <{k = v;}>, got NSException { name=laugh, reason='Lulz', userInfo=[key: value] }") {
            expect { self.exception.raise() }.to(raiseException(named: "laugh", reason: "Lulz", userInfo: ["k": "v"]))
        }

        failsWithErrorMessage("expected to raise any exception, got no exception") {
            expect { self.exception }.to(raiseException())
        }
        failsWithErrorMessage("expected to not raise any exception, got NSException { name=laugh, reason='Lulz', userInfo=[key: value] }") {
            expect { self.exception.raise() }.toNot(raiseException())
        }
        failsWithErrorMessage("expected to raise exception with name <laugh> with reason <Lulz>, got no exception") {
            expect { self.exception }.to(raiseException(named: "laugh", reason: "Lulz"))
        }

        failsWithErrorMessage("expected to raise exception with name <bar> with reason <Lulz>, got NSException { name=laugh, reason='Lulz', userInfo=[key: value] }") {
            expect { self.exception.raise() }.to(raiseException(named: "bar", reason: "Lulz"))
        }
        failsWithErrorMessage("expected to not raise exception with name <laugh>, got NSException { name=laugh, reason='Lulz', userInfo=[key: value] }") {
            expect { self.exception.raise() }.toNot(raiseException(named: "laugh"))
        }
        failsWithErrorMessage("expected to not raise exception with name <laugh> with reason <Lulz>, got NSException { name=laugh, reason='Lulz', userInfo=[key: value] }") {
            expect { self.exception.raise() }.toNot(raiseException(named: "laugh", reason: "Lulz"))
        }

        failsWithErrorMessage("expected to not raise exception with name <laugh> with reason <Lulz> with userInfo <{key = value;}>, got NSException { name=laugh, reason='Lulz', userInfo=[key: value] }") {
            expect { self.exception.raise() }.toNot(raiseException(named: "laugh", reason: "Lulz", userInfo: ["key": "value"]))
        }
    }

    func testNegativeMatchesDoNotCallClosureWithoutException() {
        failsWithErrorMessage("expected to raise exception that satisfies block, got no exception") {
            expect { self.exception }.to(raiseException { exception in
                expect(exception.name).to(equal("foo"))
            })
        }
        
        failsWithErrorMessage("expected to raise exception with name <foo> that satisfies block, got no exception") {
            expect { self.exception }.to(raiseException(named: "foo") { exception in
                expect(exception.name).to(equal("foo"))
            })
        }

        failsWithErrorMessage("expected to raise exception with name <foo> with reason <ha> that satisfies block, got no exception") {
            expect { self.exception }.to(raiseException(named: "foo", reason: "ha") { exception in
                expect(exception.name).to(equal("foo"))
            })
        }

        failsWithErrorMessage("expected to raise exception with name <foo> with reason <Lulz> with userInfo <{}> that satisfies block, got no exception") {
            expect { self.exception }.to(raiseException(named: "foo", reason: "Lulz", userInfo: [:]) { exception in
                expect(exception.name).to(equal("foo"))
                })
        }

        failsWithErrorMessage("expected to not raise any exception, got NSException { name=laugh, reason='Lulz', userInfo=[key: value] }") {
            expect { self.exception.raise() }.toNot(raiseException())
        }
    }

    func testNegativeMatchesWithClosure() {
        failsWithErrorMessage("expected to raise exception that satisfies block, got NSException { name=laugh, reason='Lulz', userInfo=[key: value] }") {
            expect { self.exception.raise() }.to(raiseException { exception in
                expect(exception.name).to(equal("foo"))
            })
        }

        let innerFailureMessage = "expected to begin with <fo>, got <laugh>"

        failsWithErrorMessage([innerFailureMessage, "expected to raise exception with name <laugh> that satisfies block, got NSException { name=laugh, reason='Lulz', userInfo=[key: value] }"]) {
            expect { self.exception.raise() }.to(raiseException(named: "laugh") { exception in
                expect(exception.name).to(beginWith("fo"))
            })
        }

        failsWithErrorMessage([innerFailureMessage, "expected to raise exception with name <lol> that satisfies block, got NSException { name=laugh, reason='Lulz', userInfo=[key: value] }"]) {
            expect { self.exception.raise() }.to(raiseException(named: "lol") { exception in
                expect(exception.name).to(beginWith("fo"))
            })
        }

        failsWithErrorMessage([innerFailureMessage, "expected to raise exception with name <laugh> with reason <Lulz> that satisfies block, got NSException { name=laugh, reason='Lulz', userInfo=[key: value] }"]) {
            expect { self.exception.raise() }.to(raiseException(named: "laugh", reason: "Lulz") { exception in
                expect(exception.name).to(beginWith("fo"))
            })
        }

        failsWithErrorMessage([innerFailureMessage, "expected to raise exception with name <lol> with reason <wrong> that satisfies block, got NSException { name=laugh, reason='Lulz', userInfo=[key: value] }"]) {
            expect { self.exception.raise() }.to(raiseException(named: "lol", reason: "wrong") { exception in
                expect(exception.name).to(beginWith("fo"))
            })
        }

        failsWithErrorMessage([innerFailureMessage, "expected to raise exception with name <laugh> with reason <Lulz> with userInfo <{key = value;}> that satisfies block, got NSException { name=laugh, reason='Lulz', userInfo=[key: value] }"]) {
            expect { self.exception.raise() }.to(raiseException(named: "laugh", reason: "Lulz", userInfo: ["key": "value"]) { exception in
                expect(exception.name).to(beginWith("fo"))
            })
        }

        failsWithErrorMessage([innerFailureMessage, "expected to raise exception with name <lol> with reason <Lulz> with userInfo <{}> that satisfies block, got NSException { name=laugh, reason='Lulz', userInfo=[key: value] }"]) {
            expect { self.exception.raise() }.to(raiseException(named: "lol", reason: "Lulz", userInfo: [:]) { exception in
                expect(exception.name).to(beginWith("fo"))
            })
        }
    }
}
