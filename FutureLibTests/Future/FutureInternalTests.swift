//
//  FutureInternalTests.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import XCTest
@testable import FutureLib


/**
A helper execution context which synchronously executes a given closure on the
_current_ execution context. This class is used to test private behavior of Future.
*/
struct SyncCurrent : ExecutionContext {

    internal func execute(f:()->()) {
        f()
    }
}


class FutureInternalTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    //
    // Test if internal future methods are synchronized with the synchronization context.
    //

    func testFutureInternalsExecuteOnTheSynchronizationQueue1() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        let promise = Promise<String>()
        let test:()->() = {
            let future = promise.future!
            future.onComplete(ec: SyncCurrent()) { r -> () in
                XCTAssertTrue(future.sync().isSynchronized())
                expect.fulfill()
            }
        }
        test()
        promise.fulfill("OK")
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }




    func testFutureInternalsExecuteOnTheSynchronizationQueue2() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        let promise = Promise<String>()
        let cr = CancellationRequest()
        let test:()->() = {
            let future = promise.future!
            future.onComplete(ec: SyncCurrent(), ct: cr.token) { r -> () in
                XCTAssertTrue(future.sync().isSynchronized())
                expect.fulfill()
            }
        }
        test()
        promise.fulfill("OK")
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }

}
