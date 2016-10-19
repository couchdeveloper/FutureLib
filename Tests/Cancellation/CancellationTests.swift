//
//  CancellationTests.swift
//
//  Copyright © 2016 Andreas Grosam. All rights reserved.
//

import XCTest

class MyCancelable: Cancelable {

    func cancel() -> () {
    }

    func cancel(_ error: Error) -> () {
    }

}

class CancellationTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testACancellationRequestStartsOutWithNoCancellationRequest() {
        let cr = CancellationRequest()
        XCTAssertFalse(cr.isCancellationRequested)

    }

    func testACancellationRequestTokenStartsOutWithNoCancellationRequest() {
        let cr = CancellationRequest()
        XCTAssertFalse(cr.token.isCancellationRequested)

    }

    func testRequestingCancellation() {
        let cr = CancellationRequest()
        let ct: CancellationTokenType = cr.token
        cr.cancel()
        let crv = cr.isCancellationRequested
        let ctv = ct.isCancellationRequested
        XCTAssertTrue(crv)
        XCTAssertTrue(ctv)
    }

    func testGivenACancelledTokenACancellationHandlerWillRun1a() {
        let cr = CancellationRequest()
        let ct = cr.token
        let expect1 = self.expectation(description: "cancellation handler should be called")
        cr.cancel()
        _ = ct.onCancel {
            expect1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }


    func testGivenACancelledTokenACancellationHandlerWillRun1b() {
        let op = MyCancelable()
        let cr = CancellationRequest()
        let ct = cr.token
        let expect1 = self.expectation(description: "cancellation handler should be called")
        cr.cancel()
        _ = ct.onCancel(cancelable: op) { c in
            expect1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }


    func testRequestingCancellationRunsRegisteredHandler1a() {
        let cr = CancellationRequest()
        let ct = cr.token
        let expect1 = self.expectation(description: "cancellation handler should be called")
        _ = ct.onCancel {
            expect1.fulfill()
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(10)) {
            cr.cancel()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testRequestingCancellationRunsRegisteredHandler1b() {
        let op = MyCancelable()
        let cr = CancellationRequest()
        let ct = cr.token
        let expect1 = self.expectation(description: "cancellation handler should be called")
        _ = ct.onCancel(cancelable: op) { c in
            XCTAssertTrue(op === c)
            expect1.fulfill()
        }
        cr.cancel()
        waitForExpectations(timeout: 1, handler: nil)
    }


    func testRequestingCancellationRunsRegisteredHandler2a() {
        let cr = CancellationRequest()
        let ct = cr.token
        let expect1 = self.expectation(description: "cancellation handler should be called")
        let expect2 = self.expectation(description: "cancellation handler should be called")
        _ = ct.onCancel {
            expect1.fulfill()
        }
        _ = ct.onCancel {
            expect2.fulfill()
        }
        cr.cancel()
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testRequestingCancellationRunsRegisteredHandler2b() {
        let op = MyCancelable()
        let cr = CancellationRequest()
        let ct = cr.token
        let expect1 = self.expectation(description: "cancellation handler should be called")
        let expect2 = self.expectation(description: "cancellation handler should be called")
        _ = ct.onCancel(cancelable: op) { c in
            XCTAssertTrue(op === c)
            expect1.fulfill()
        }
        _ = ct.onCancel(cancelable: op) { c in
            XCTAssertTrue(op === c)
            expect2.fulfill()
        }
        cr.cancel()
        waitForExpectations(timeout: 1, handler: nil)
    }


    func testRequestingCancellationRunsRegisteredHandler3a() {
        let cr = CancellationRequest()
        let expect1 = self.expectation(description: "cancellation handler should be called")
        let expect2 = self.expectation(description: "cancellation handler should be called")
        func f(_ ct: CancellationTokenType)-> () {
            _ = ct.onCancel() {
                expect1.fulfill()
            }
            _ = ct.onCancel {
                expect2.fulfill()
            }
        }
        DispatchQueue.main.async {
            f(cr.token)
        }
        DispatchQueue.main.async {
            cr.cancel()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testRequestingCancellationRunsRegisteredHandler3b() {
        let op = MyCancelable()
        let cr = CancellationRequest()
        let expect1 = self.expectation(description: "cancellation handler should be called")
        let expect2 = self.expectation(description: "cancellation handler should be called")
        func f(_ ct: CancellationTokenType)-> () {
            _ = ct.onCancel(cancelable: op) { c in
                XCTAssertTrue(op === c)
                expect1.fulfill()
            }
            _ = ct.onCancel(cancelable: op) { c in
                XCTAssertTrue(op === c)
                expect2.fulfill()
            }
        }
        DispatchQueue.main.async {
            f(cr.token)
        }
        DispatchQueue.main.async {
            cr.cancel()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }



    func testNotRequestingCancellationMaintainsTokenState1() {
        var cr: CancellationRequest? = CancellationRequest()
        let ct = cr!.token
        _ = ct.onCancel {
            XCTFail("unexpected")
        }
        _ = ct.onCancel {
            XCTFail("unexpected")
        }
        cr = nil
        for _ in 0..<100 {
            usleep(1000)
        }
        XCTAssertFalse(ct.isCancellationRequested)
    }

    func testRequestingCancellationMaintainsTokenState2() {
        var cr: CancellationRequest? = CancellationRequest()
        let expect1 = self.expectation(description: "cancellation handler should be called")
        let expect2 = self.expectation(description: "cancellation handler should be called")
        let ct = cr!.token
        _ = ct.onCancel {
            expect1.fulfill()
        }
        _ = ct.onCancel {
            expect2.fulfill()
        }
        cr!.cancel()
        cr = nil
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertTrue(ct.isCancellationRequested)
    }


    func testNotRequestingCancellationUnregistersRegisteredHandler() {
        class Dummy {
            let _expect: XCTestExpectation
            init(expect: XCTestExpectation) {
                _expect = expect
            }
            deinit {
                _expect.fulfill()
            }
        }

        func f(_ expect: XCTestExpectation, ct: CancellationTokenType)-> () {
            let dummy = Dummy(expect: expect)
            _ = ct.onCancel {
                XCTFail("unexpected")
                _ = dummy
            }
        }

        var cr: CancellationRequest? = CancellationRequest()
        let expect1 = self.expectation(description: "cancellation handler should be unregistered")

        f(expect1, ct: cr!.token)

        cr = nil    // Should deinit cr, and as a consequence unregistering its handlers,
                    // which in turn deinits dummy.

        waitForExpectations(timeout: 1, handler: nil)
    }



}
