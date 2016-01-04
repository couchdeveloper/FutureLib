//
//  CancellationTests.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import XCTest
import FutureLib


class MyCancelable : Cancelable {

    func cancel() -> () {
    }

    func cancel(error: ErrorType) -> () {
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
        let ct = cr.token
        cr.cancel()
        let crv = cr.isCancellationRequested
        let ctv = ct.isCancellationRequested
        XCTAssertTrue(crv)
        XCTAssertTrue(ctv)
    }

    func testGivenACancelledTokenACancellationHandlerWillRun1a() {
        let cr = CancellationRequest()
        let ct = cr.token
        let expect1 = self.expectationWithDescription("cancellation handler should be called")
        cr.cancel()
        _ = ct.onCancel {
            expect1.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }


    func testGivenACancelledTokenACancellationHandlerWillRun1b() {
        let op = MyCancelable()
        let cr = CancellationRequest()
        let ct = cr.token
        let expect1 = self.expectationWithDescription("cancellation handler should be called")
        cr.cancel()
        _ = ct.onCancel(cancelable: op) { c in
            expect1.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }


    func testRequestingCancellationRunsRegisteredHandler1a() {
        let cr = CancellationRequest()
        let ct = cr.token
        let expect1 = self.expectationWithDescription("cancellation handler should be called")
        _ = ct.onCancel {
            expect1.fulfill()
        }
        cr.cancel()
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testRequestingCancellationRunsRegisteredHandler1b() {
        let op = MyCancelable()
        let cr = CancellationRequest()
        let ct = cr.token
        let expect1 = self.expectationWithDescription("cancellation handler should be called")
        _ = ct.onCancel(cancelable: op) { c in
            XCTAssertTrue(op === c)
            expect1.fulfill()
        }
        cr.cancel()
        waitForExpectationsWithTimeout(1, handler: nil)
    }


    func testRequestingCancellationRunsRegisteredHandler2a() {
        let cr = CancellationRequest()
        let ct = cr.token
        let expect1 = self.expectationWithDescription("cancellation handler should be called")
        let expect2 = self.expectationWithDescription("cancellation handler should be called")
        _ = ct.onCancel {
            expect1.fulfill()
        }
        _ = ct.onCancel {
            expect2.fulfill()
        }
        cr.cancel()
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testRequestingCancellationRunsRegisteredHandler2b() {
        let op = MyCancelable()
        let cr = CancellationRequest()
        let ct = cr.token
        let expect1 = self.expectationWithDescription("cancellation handler should be called")
        let expect2 = self.expectationWithDescription("cancellation handler should be called")
        _ = ct.onCancel(cancelable: op) { c in
            XCTAssertTrue(op === c)
            expect1.fulfill()
        }
        _ = ct.onCancel(cancelable: op) { c in
            XCTAssertTrue(op === c)
            expect2.fulfill()
        }
        cr.cancel()
        waitForExpectationsWithTimeout(1, handler: nil)
    }


    func testRequestingCancellationRunsRegisteredHandler3a() {
        let cr = CancellationRequest()
        let expect1 = self.expectationWithDescription("cancellation handler should be called")
        let expect2 = self.expectationWithDescription("cancellation handler should be called")
        func f(ct: CancellationToken)-> () {
            _ = ct.onCancel() {
                expect1.fulfill()
            }
            _ = ct.onCancel {
                expect2.fulfill()
            }
        }
        dispatch_async(dispatch_get_main_queue()) {
            f(cr.token)
        }
        dispatch_async(dispatch_get_main_queue()) {
            cr.cancel()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testRequestingCancellationRunsRegisteredHandler3b() {
        let op = MyCancelable()
        let cr = CancellationRequest()
        let expect1 = self.expectationWithDescription("cancellation handler should be called")
        let expect2 = self.expectationWithDescription("cancellation handler should be called")
        func f(ct: CancellationToken)-> () {
            _ = ct.onCancel(cancelable: op) { c in
                XCTAssertTrue(op === c)
                expect1.fulfill()
            }
            _ = ct.onCancel(cancelable: op) { c in
                XCTAssertTrue(op === c)
                expect2.fulfill()
            }
        }
        dispatch_async(dispatch_get_main_queue()) {
            f(cr.token)
        }
        dispatch_async(dispatch_get_main_queue()) {
            cr.cancel()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
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
        let expect1 = self.expectationWithDescription("cancellation handler should be called")
        let expect2 = self.expectationWithDescription("cancellation handler should be called")
        let ct = cr!.token
        _ = ct.onCancel {
            expect1.fulfill()
        }
        _ = ct.onCancel {
            expect2.fulfill()
        }
        cr!.cancel()
        cr = nil
        waitForExpectationsWithTimeout(1, handler: nil)
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

        func f(expect: XCTestExpectation, ct: CancellationToken)-> () {
            let dummy = Dummy(expect: expect)
            _ = ct.onCancel {
                XCTFail("unexpected")
                dummy
            }
        }

        var cr: CancellationRequest? = CancellationRequest()
        let expect1 = self.expectationWithDescription("cancellation handler should be unregistered")

        f(expect1, ct: cr!.token)

        cr = nil    // Should deinit cr, and as a consequence unregistering its handlers,
                    // which in turn deinits dummy.

        waitForExpectationsWithTimeout(1, handler: nil)
    }





}
