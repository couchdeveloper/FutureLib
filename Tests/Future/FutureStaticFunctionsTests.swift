//
//  FutureStaticFunctionsTests.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import XCTest
import FutureLib

class FutureExtensionsTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }


    // MARK: Future<T>.failed(error:) -> Future<T>


    func testClassMethodFailedReturnsRejectedFuture() {
        let future = Future<Int>.failed(TestError.Failed)
        XCTAssertTrue(future.isCompleted)
        XCTAssert(future.isFailure)
        XCTAssertNotNil(future.result)
        if let r = future.result {
            XCTAssertTrue(r.isFailure)
            do {
                let v = try r.get()
                print("\(v)")
            }
            catch TestError.Failed {
            }
            catch {
                XCTFail("unexpected error")
            }
        }
    }


    // MARK: Future<T>.succeeded(value:) -> Future<T>


    func testClassMethodSucceededReturnsFulfilledFuture() {
        let future = Future.succeeded(1)
        XCTAssertTrue(future.isCompleted)
        XCTAssert(future.isSuccess)
        XCTAssertNotNil(future.result)
        if let r = future.result {
            XCTAssertTrue(r.isSuccess)
            do {
                let v = try r.get()
                XCTAssertEqual(1, v)
            }
            catch {
                XCTFail("unexpected error")
            }
        }
    }


    // MARK: Future<T>.completed(result:) -> Future<T>
    
    
    func testClassMethodCompletedReturnsFulfilledFuture() {
        let future = Future.completed(Try(1))
        XCTAssertTrue(future.isCompleted)
        XCTAssert(future.isSuccess)
        XCTAssertNotNil(future.result)
        if let r = future.result {
            XCTAssertTrue(r.isSuccess)
            do {
                let v = try r.get()
                XCTAssertEqual(1, v)
            }
            catch {
                XCTFail("unexpected error")
            }
        }
    }
    
    func testClassMethodCompletedReturnsFailedFuture() {
        let future = Future.completed(Try<Int>(error: TestError.Failed))
        XCTAssertTrue(future.isCompleted)
        XCTAssert(future.isFailure)
        XCTAssertNotNil(future.result)
        if let r = future.result {
            XCTAssertTrue(r.isFailure)
        } else {
            XCTFail()
        }
    }
    
    
    
    func testClassMethodSucceededReturnsFulfilledFuture2() {
        let a = [1,2,3]
        let future = Future.succeeded(a)
        XCTAssertTrue(future.isCompleted)
        XCTAssert(future.isSuccess)
        XCTAssertNotNil(future.result)
        if let r = future.result {
            XCTAssertTrue(r.isSuccess)
            do {
                let v = try r.get()
                XCTAssertEqual(a, v)
            }
            catch {
                XCTFail("unexpected error")
            }
        }
    }


    // MARK: Future<T>.failedAfter(delay:, error:) -> Future<T>

    func testClassMethodFailedAfterReturnsAFutureWhichBecomesFailedAfterTheDelay() {
        let expect1 = self.expectationWithDescription("continuation should be called")
        let future = Future<Int>.failedAfter(0.1, error: TestError.Failed)
        future.onComplete { r in
            if let r = future.result {
                XCTAssertTrue(r.isFailure)
                do {
                    let v = try r.get()
                    print("\(v)")
                }
                catch TestError.Failed {
                }
                catch {
                    XCTFail("unexpected error")
                }
            }
            expect1.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }


    // MARK: Future<T>.succeededAfter(delay:, value:) -> Future<T>

    func testClassMethodSucceededAfterReturnsAFutureWhichBecomesSucceededAfterTheDelay() {
        let expect1 = self.expectationWithDescription("continuation should be called")
        let future = Future<Int>.succeededAfter(0.1, value: 1)
        future.onComplete { r in
            if let r = future.result {
                XCTAssertTrue(r.isSuccess)
                do {
                    let v = try r.get()
                    XCTAssertEqual(1, v)
                }
                catch {
                    XCTFail("unexpected error")
                }
            }
            expect1.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }


    // MARK: Future<T>.failedAfter(delay:, cancellationToken:, error:) -> Future<T>

    func testCancellingClassMethodFailedAfterReturnsAFutureWhichBecomesRejectedWithACancellationError() {
        let expect1 = self.expectationWithDescription("continuation should be called")
        let cr1 = CancellationRequest()
        let future = Future<Int>.failedAfter(10, cancellationToken: cr1.token, error: TestError.Failed)
        future.onComplete { r in
            if let r = future.result {
                XCTAssertTrue(r.isFailure)
                do {
                    let _ = try r.get()
                    XCTFail("unexpected success")
                }
                catch CancellationError.Cancelled {
                }
                catch {
                    XCTFail("unexpected error")
                }
            }
            expect1.fulfill()
        }
        cr1.cancel()
        waitForExpectationsWithTimeout(0.1, handler: nil)
    }


    // MARK: Future<T>.succeededAfter(delay:, cancellationToken:, value:) -> Future<T>

    func testCancellingClassMethodSucceededAfterReturnsAFutureWhichBecomesRejectedWithACancellationError() {
        let expect1 = self.expectationWithDescription("continuation should be called")
        let cr1 = CancellationRequest()
        let future = Future<Int>.succeededAfter(10, cancellationToken: cr1.token, value: 1)
        future.onComplete { r in
            if let r = future.result {
                XCTAssertTrue(r.isFailure)
                do {
                    let _ = try r.get()
                    XCTFail("unexpected success")
                }
                catch CancellationError.Cancelled {
                }
                catch {
                    XCTFail("unexpected error")
                }
            }
            expect1.fulfill()
        }
        cr1.cancel()
        waitForExpectationsWithTimeout(0.1, handler: nil)
    }



    // MARK: Future<T>.apply(_:f:) -> Future<T>

    
    func testApply() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        let future = Future<String>.apply { "OK" }
        future.onComplete { result in
            switch result {
            case .Success(let value):
                XCTAssertEqual("OK", value)
            case .Failure(let error):
                XCTFail("unexpected error: \(error)")
            }
            expect.fulfill()
        }
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testApplyWithThrowingFunction() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        let future: Future<String> = Future<String>.apply { throw TestError.Failed }
        future.onComplete { result in
            switch result {
            case .Success(let value):
                XCTFail("unexpected success: \(value)")
            case .Failure(let error):
                XCTAssertTrue(TestError.Failed == error)
            }
            expect.fulfill()
        }
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }


}
