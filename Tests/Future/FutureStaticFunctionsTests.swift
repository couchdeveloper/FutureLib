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
        let future = Future<Int>.failed(TestError.failed)
        XCTAssertTrue(future.isCompleted)
        XCTAssert(future.isFailure)
        XCTAssertNotNil(future.result)
        if let r = future.result {
            XCTAssertTrue(r.isFailure)
            do {
                let v = try r.get()
                print("\(v)")
            }
            catch TestError.failed {
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
        let future = Future.completed(Try<Int>(error: TestError.failed))
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

    func testClassMethodSucceededReturnsFulfilledFuture3() {
        let expect1 = self.expectation(description: "continuation should be called")
        let a = 1
        let future = Future.succeeded(a)
        future.onComplete { result in
            XCTAssertTrue(result.isSuccess)
            expect1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }


    // MARK: Future<T>.failedAfter(delay:, error:) -> Future<T>

    // FIXME: Thread Sanitizer fails    
    func testClassMethodFailedAfterReturnsAFutureWhichBecomesFailedAfterTheDelay() {
        let expect1 = self.expectation(description: "continuation should be called")
        func test() {
            let future = Future<Int>.failedAfter(1, error: TestError.failed)
            //sleep(2)
            future.onComplete { _ in
//                do {
//                    let _ = try result.get()
//                    XCTFail("unexpected success")
//                }
//                catch TestError.failed {
//                }
//                catch {
//                    XCTFail("unexpected error")
//                }
                expect1.fulfill()
            }
        }
        test()
        waitForExpectations(timeout: 10000, handler: nil)
    }


    // MARK: Future<T>.succeededAfter(delay:, value:) -> Future<T>

    func testClassMethodSucceededAfterReturnsAFutureWhichBecomesSucceededAfterTheDelay1() {
        let expect1 = self.expectation(description: "continuation should be called")
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
        waitForExpectations(timeout: 1, handler: nil)
    }


    // MARK: Future<T>.failedAfter(delay:, cancellationToken:, error:) -> Future<T>

    func testClassMethodSucceededAfterReturnsAFutureWhichBecomesSucceededAfterTheDelay2() {
        let expect1 = self.expectation(description: "continuation should be called")

        func test() {
            let cr1 = CancellationRequest()
            let future = Future<Int>.failedAfter(0.1, cancellationToken: cr1.token, error: TestError.failed)
            future.onComplete { r in
                if let r = future.result {
                    XCTAssertTrue(r.isFailure)
                    do {
                        let _ = try r.get()
                        XCTFail("unexpected success")
                    }
                    catch is CancellationError {
                        XCTFail("unexpected error")
                    }
                    catch {
                    }
                }
                expect1.fulfill()
            }
        }
        test()

        waitForExpectations(timeout: 10000, handler: nil)
    }


    // FIXME: Thread Sanitizer fails    
    func testCancellingClassMethodFailedAfterReturnsAFutureWhichBecomesRejectedWithACancellationError2() {
        let expect1 = self.expectation(description: "continuation should be called")
        let cr1 = CancellationRequest()
        let future = Future<Int>.failedAfter(10, cancellationToken: cr1.token, error: TestError.failed)
        future.onComplete { r in
            if let r = future.result {
                XCTAssertTrue(r.isFailure)
                do {
                    let _ = try r.get()
                    XCTFail("unexpected success")
                }
                catch is CancellationError {
                }
                catch {
                    XCTFail("unexpected error")
                }
            }
            expect1.fulfill()
        }
        cr1.cancel()
        waitForExpectations(timeout: 10000, handler: nil)
    }


    // MARK: Future<T>.succeededAfter(delay:, cancellationToken:, value:) -> Future<T>
    // FIXME: Thread Sanitizer fails    
    func testCancellingClassMethodSucceededAfterReturnsAFutureWhichBecomesRejectedWithACancellationError() {
        let expect1 = self.expectation(description: "continuation should be called")
        let cr1 = CancellationRequest()
        let future = Future<Int>.succeededAfter(10, cancellationToken: cr1.token, value: 1)
        future.onComplete { r in
            if let r = future.result {
                XCTAssertTrue(r.isFailure)
                do {
                    let _ = try r.get()
                    XCTFail("unexpected success")
                }
                catch is CancellationError {
                }
                catch {
                    XCTFail("unexpected error")
                }
            }
            expect1.fulfill()
        }
        cr1.cancel()
        waitForExpectations(timeout: 0.1, handler: nil)
    }



    // MARK: Future<T>.apply(_:f:) -> Future<T>

    
    func testApply() {
        let expect = self.expectation(description: "future should be fulfilled")
        let future = Future<String>.apply { "OK" }
        future.onComplete { result in
            switch result {
            case .success(let value):
                XCTAssertEqual("OK", value)
            case .failure(let error):
                XCTFail("unexpected error: \(error)")
            }
            expect.fulfill()
        }
        self.waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testApply2() {
        let expect = self.expectation(description: "future should be fulfilled")
        let cr = CancellationRequest()
        let future = Future<String>.apply { "OK" }
        future.onComplete(ct: cr.token) { result in
            switch result {
            case .success(let value):
                XCTAssertEqual("OK", value)
            case .failure(let error):
                XCTFail("unexpected error: \(error)")
            }
            expect.fulfill()
        }
        self.waitForExpectations(timeout: 1, handler: nil)
    }



    func testApplyWithThrowingFunction() {
        let expect = self.expectation(description: "future should be fulfilled")
        let future: Future<String> = Future<String>.apply { throw TestError.failed }
        future.onComplete { result in
            switch result {
            case .success(let value):
                XCTFail("unexpected success: \(value)")
            case .failure(let error):
                XCTAssertTrue(TestError.failed == error)
            }
            expect.fulfill()
        }
        self.waitForExpectations(timeout: 1, handler: nil)
    }


}
