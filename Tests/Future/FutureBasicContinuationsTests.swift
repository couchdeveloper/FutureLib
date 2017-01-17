//
//  FutureBasixContinuationsTests.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import XCTest
import FutureLib
import Dispatch


private let timeout: Foundation.TimeInterval = 1

class FutureBasicContinuationsTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }




    // MARK: onComplete(_:)
    func testGivenAPendingFutureWithCompletionHandlerWhenFulfilledItShouldExecuteHandler1() {
        let expect = self.expectation(description: "future should be fulfilled")
        let test: ()->Future<String> = {
            let promise = Promise<String>()
            schedule_after(0.01) {
                promise.fulfill("OK")
            }
            return promise.future!
        }
        test().onComplete { r in
            switch (r) {
            case .success(let value): XCTAssert(value=="OK")
            case .failure(let error): XCTFail("unexpected error: \(error)")
            }
            expect.fulfill()
        }
        self.waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGivenAPendingFutureWithCompletionHandlerWhenRejectedItShouldExecuteHandler1() {
        let expect = self.expectation(description: "future should be fulfilled")
        let test: ()->Future<String> = {
            let promise = Promise<String>()
            schedule_after(0.01) {
                promise.reject(TestError.failed)
            }
            return promise.future!
        }
        test().onComplete { r in
            switch (r) {
            case .success: XCTFail("unexpected success")
            case .failure(let error):
                XCTAssertTrue(TestError.failed == error)
            }
            expect.fulfill()
        }
        self.waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGivenAFulfilledFutureWhenRegisteringCompletionHandlerItShouldExecuteHandler1() {
        let expect = self.expectation(description: "future should be fulfilled")
        let test: ()->Future<String> = {
            let promise = Promise<String>(value: "OK")
            return promise.future!
        }
        test().onComplete { r in
            expect.fulfill()
        }
        self.waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGivenARejectedFutureWhenRegisteringCompletionHandlerItShouldExecuteHandler1() {
        let expect = self.expectation(description: "future should be fulfilled")
        let test: ()->Future<String> = {
            let promise = Promise<String>(error: TestError.failed)
            return promise.future!
        }
        test().onComplete { r -> () in
            switch (r) {
            case .success: XCTFail("unexpected success")
            case .failure(let error):
                XCTAssertTrue(TestError.failed == error)
            }
            expect.fulfill()
        }
        self.waitForExpectations(timeout: timeout, handler: nil)
    }

    // MARK: onComplete(cancellationToken:_:)
    func testGivenAPendingFutureWithCompletionHandlerWhenFulfilledItShouldExecutedHandler2() {
        // with cancellation token
        let expect = self.expectation(description: "future should be fulfilled")
        let cr = CancellationRequest()
        let test: ()->Future<String> = {
            let promise = Promise<String>()
            schedule_after(0.01) {
                promise.fulfill("OK")
            }
            return promise.future!
        }
        test().onComplete(ct: cr.token) { r -> () in
            switch (r) {
            case .success(let value): XCTAssert(value=="OK")
            case .failure(let error): XCTFail("unexpected error: \(error)")
            }
            expect.fulfill()
        }
        self.waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGivenAPendingFutureWithCompletionHandlerWhenRejectedItShouldExecuteHandler2() {
        let expect = self.expectation(description: "future should be fulfilled")
        let cr = CancellationRequest()
        let test: ()->Future<String> = {
            let promise = Promise<String>()
            schedule_after(0.01) {
                promise.reject(TestError.failed)
            }
            return promise.future!
        }
        test().onComplete(ct: cr.token) { r -> () in
            switch (r) {
            case .success: XCTFail("unexpected success")
            case .failure(let error):
                XCTAssertTrue(TestError.failed == error)
            }
            expect.fulfill()
        }
        self.waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGivenAFulfilledFutureWhenRegisteringCompletionHandlerItShouldExecuteHandler2() {
        let expect = self.expectation(description: "future should be fulfilled")
        let cr = CancellationRequest()
        let test: ()->Future<String> = {
            let promise = Promise<String>(value: "OK")
            return promise.future!
        }
        test().onComplete(ct: cr.token) { r -> () in
            switch (r) {
            case .success(let value): XCTAssert(value=="OK")
            case .failure(let error): XCTFail("unexpected error: \(error)")
            }
            expect.fulfill()
        }
        self.waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGivenARejectedFutureWhenRegisteringCompletionHandlerItShouldExecuteHandler2() {
        let expect = self.expectation(description: "future should be fulfilled")
        let cr = CancellationRequest()
        let test: ()->Future<String> = {
            let promise = Promise<String>(error: TestError.failed)
            return promise.future!
        }
        test().onComplete(ct: cr.token) { r -> () in
            switch (r) {
            case .success: XCTFail("unexpected success")
            case .failure(let error):
                XCTAssertTrue(TestError.failed == error)
            }
            expect.fulfill()
        }
        self.waitForExpectations(timeout: timeout, handler: nil)
    }


    // MARK: onComplete(cancellationToken:_:) when cancellation requested later

    func testGivenAPendingFutureWithCompletionHandlerAndCancellationTokenWhenCancelledItShouldExecutedHandlerWithCancellationError() {
        // with cancellation token
        let expect = self.expectation(description: "future should be fulfilled")
        let cr = CancellationRequest()
        let test: ()->Future<String> = {
            let promise = Promise<String>()
            schedule_after(0.5) {
                promise.fulfill("OK")
            }
            return promise.future!
        }
        test().onComplete(ct: cr.token) { r -> () in
            switch (r) {
            case .success(let value): XCTFail("unexpected success: \(value)")
            case .failure(let error):
                XCTAssertTrue(error is CancellationError, String(reflecting: error))
            }
            expect.fulfill()
        }
        schedule_after(0.01) {
            cr.cancel()
        }
        self.waitForExpectations(timeout: timeout, handler: nil)
    }


    func testGivenAFulfilledFutureWithCompletionHandlerAndCancellationTokenWhenCancelledItShouldExecuteHandlerWithResult() {
        let expect1 = self.expectation(description: "future should be fulfilled")
        let expect2 = self.expectation(description: "cancellation should be requested")
        let cr = CancellationRequest()
        let test: ()->Future<String> = {
            let promise = Promise<String>(value: "OK")
            return promise.future!
        }
        test().onComplete(ct: cr.token) { r -> () in
            switch (r) {
            case .success(let value): XCTAssert(value=="OK")
            case .failure(let error): XCTFail("unexpected error: \(error)")
            }
            expect1.fulfill()
        }
        schedule_after(0.01) {
            cr.cancel()
            expect2.fulfill()
        }
        self.waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGivenARejectedFutureWithCompletionHandlerAndCancellationTokenWhenCancelledItShouldExecuteHandlerWithResult() {
        let expect1 = self.expectation(description: "future should be fulfilled")
        let expect2 = self.expectation(description: "cancellation should be requested")
        let cr = CancellationRequest()
        let test: ()->Future<String> = {
            let promise = Promise<String>(error: TestError.failed)
            return promise.future!
        }
        test().onComplete(ct: cr.token) { r -> () in
            switch (r) {
            case .success: XCTFail("unexpected success")
            case .failure(let error):
                XCTAssertTrue(TestError.failed == error)
            }
            expect1.fulfill()
        }
        schedule_after(0.01) {
            cr.cancel()
            expect2.fulfill()
        }
        self.waitForExpectations(timeout: timeout, handler: nil)
    }


    // MARK: onComplete(cancellationToken:_:) when cancellation already requested

    func testGivenAPendingFutureWithCompletionHandlerAndCancellationTokenWithCancellationRequestedItShouldExecutedHandlerWithCancellationError() {
        // with cancellation token
        let expect = self.expectation(description: "future should be fulfilled")
        let cr = CancellationRequest()
        cr.cancel()
        let test: ()->Future<String> = {
            let promise = Promise<String>()
            schedule_after(0.5) {
                promise.fulfill("OK")
            }
            return promise.future!
        }
        test().onComplete(ct: cr.token) { r -> () in
            switch (r) {
            case .success(let value): XCTFail("unexpected success: \(value)")
            case .failure(let error):
                XCTAssertTrue(error is CancellationError, String(reflecting: error))
            }
            expect.fulfill()
        }
        self.waitForExpectations(timeout: timeout, handler: nil)
    }


    func testGivenAFulfilledFutureWithCompletionHandlerAndCancellationTokenWithCancellationRequestedItShouldExecutedHandlerWithCancellationError() {
        let expect = self.expectation(description: "future should be fulfilled")
        let cr = CancellationRequest()
        cr.cancel()
        let test: ()->Future<String> = {
            let promise = Promise<String>(value: "OK")
            return promise.future!
        }
        test().onComplete(ct: cr.token) { r -> () in
            switch (r) {
            case .success(let value): XCTFail("unexpected success: \(value)")
            case .failure(let error):
                XCTAssertTrue(error is CancellationError, String(reflecting: error))
            }
            expect.fulfill()
        }
        self.waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGivenARejectedFutureWithCompletionHandlerAndCancellationTokenWithCancellationRequestedItShouldExecutedHandlerWithCancellationError() {
        let expect = self.expectation(description: "future should be fulfilled")
        let cr = CancellationRequest()
        cr.cancel()
        let test: ()->Future<String> = {
            let promise = Promise<String>(error: TestError.failed)
            return promise.future!
        }
        test().onComplete(ct: cr.token) { r -> () in
            switch (r) {
            case .success(let value): XCTFail("unexpected success: \(value)")
            case .failure(let error):
                XCTAssertTrue(error is CancellationError, String(reflecting: error))
            }
            expect.fulfill()
        }
        self.waitForExpectations(timeout: timeout, handler: nil)
    }



    // MARK: onComplete(on:_:)
    func testGivenAPendingFutureWithCompletionHandlerWhenFulfilledItShouldExecutedHandlerOnGivenExecutionContext() {
        // with cancellation token
        let expect = self.expectation(description: "future should be fulfilled")
        let queue = DispatchQueue(label: "test_queue")
        let ec = GCDAsyncExecutionContext(queue)
        let test: ()->Future<String> = {
            let promise = Promise<String>()
            schedule_after(0.01) {
                promise.fulfill("OK")
            }
            return promise.future!
        }
        test().onComplete(ec: ec) { r -> () in
            switch (r) {
            case .success(let value): XCTAssert(value=="OK")
            case .failure(let error): XCTFail("unexpected error: \(error)")
            }
            let label = String.init(cString: __dispatch_queue_get_label(nil))// DispatchQueue.current.label// DispatchQueue.currentLabel()
            
            XCTAssertEqual("test_queue", label)
            expect.fulfill()
        }
        self.waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGivenAPendingFutureWithCompletionHandlerWhenRejectedItShouldExecuteHandlerOnGivenExecutionContext() {
        let expect = self.expectation(description: "future should be fulfilled")
        let queue = DispatchQueue(label: "test_queue")
        let ec = GCDAsyncExecutionContext(queue)
        let test: ()->Future<String> = {
            let promise = Promise<String>()
            schedule_after(0.01) {
                promise.reject(TestError.failed)
            }
            return promise.future!
        }
        test().onComplete(ec: ec) { r -> () in
            switch (r) {
            case .success: XCTFail("unexpected success")
            case .failure(let error):
                XCTAssertTrue(TestError.failed == error)
            }
            let label = String.init(cString: __dispatch_queue_get_label(nil)) // DispatchQueue.currentLabel 
            XCTAssertEqual("test_queue", label)
            expect.fulfill()
        }
        self.waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGivenAFulfilledFutureWhenRegisteringCompletionHandlerItShouldExecuteHandlerOnGivenExecutionContext() {
        let expect = self.expectation(description: "future should be fulfilled")
        let queue = DispatchQueue(label: "test_queue")
        let ec = GCDAsyncExecutionContext(queue)
        let test: ()->Future<String> = {
            let promise = Promise<String>(value: "OK")
            return promise.future!
        }
        test().onComplete(ec: ec) { r -> () in
            let label = String.init(cString: __dispatch_queue_get_label(nil)) // DispatchQueue.currentLabel 
            XCTAssertEqual("test_queue", label)
            expect.fulfill()
        }
        self.waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGivenARejectedFutureWhenRegisteringCompletionHandlerItShouldExecuteHandlerOnGivenExecutionContext() {
        let expect = self.expectation(description: "future should be fulfilled")
        let queue = DispatchQueue(label: "test_queue")
        let ec = GCDAsyncExecutionContext(queue)
        let test: ()->Future<String> = {
            let promise = Promise<String>(error: TestError.failed)
            return promise.future!
        }
        test().onComplete(ec: ec) { r -> () in
            switch (r) {
            case .success: XCTFail("unexpected success")
            case .failure(let error):
                XCTAssertTrue(TestError.failed == error)
            }
            let label = String.init(cString: __dispatch_queue_get_label(nil)) // DispatchQueue.currentLabel
            XCTAssertEqual("test_queue", label)
            expect.fulfill()
        }
        self.waitForExpectations(timeout: timeout, handler: nil)
    }



    // MARK: onSuccess(_:)

    func testGivenAPendingFutureWithSuccessHandlerWhenFulfilledItShouldExecuteHandler1() {
        let expect = self.expectation(description: "future should be fulfilled")
        let test: ()->Future<String> = {
            let promise = Promise<String>()
            schedule_after(0.01) {
                promise.fulfill("OK")
            }
            return promise.future!
        }
        test().onSuccess { value -> () in
            XCTAssertEqual("OK", value)
            expect.fulfill()
        }
        self.waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGivenAPendingFutureWithSuccessHandlerWhenRejectedItShouldNotExecuteHandler1() {
        let test: ()->Future<String> = {
            let promise = Promise<String>()
            schedule_after(0.01) {
                promise.reject(TestError.failed)
            }
            return promise.future!
        }
        test().onSuccess { value -> () in
            XCTFail("unexpected success")
        }
    }

    func testGivenAFulfilledFutureWhenRegisteringSuccessHandlerItShouldExecuteHandler1() {
        let expect = self.expectation(description: "future should be fulfilled")
        let test: ()->Future<String> = {
            let promise = Promise<String>(value: "OK")
            return promise.future!
        }
        test().onSuccess { value -> () in
            XCTAssertEqual("OK", value)
            expect.fulfill()
        }
        self.waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGivenARejectedFutureWhenRegisteringSuccessHandlerItShouldNotExecutedHandler1() {
        let test: ()->Future<String> = {
            let promise = Promise<String>(error: TestError.failed)
            return promise.future!
        }
        test().onSuccess { value -> () in
            XCTFail("unexpected success")
        }
    }


    // MARK: onSuccess(cancellationToken:_:)
    func testGivenAPendingFutureWithSuccessHandlerWhenFulfilledItShouldExecuteHandler2() {
        let expect = self.expectation(description: "future should be fulfilled")
        let cr = CancellationRequest()
        let test: ()->Future<String> = {
            let promise = Promise<String>()
            schedule_after(0.01) {
                promise.fulfill("OK")
            }
            return promise.future!
        }
        test().onSuccess(ct: cr.token) { value -> () in
            XCTAssertEqual("OK", value)
            expect.fulfill()
        }
        self.waitForExpectations(timeout: timeout, handler: nil)
    }

    // FIXME: Thread Sanitizer fails    
    func testGivenAPendingFutureWithSuccessHandlerWhenRejectedItShouldNotExecutedHandler2() {
        let expect = self.expectation(description: "future should be fulfilled")
        let cr = CancellationRequest()
        let test: ()->Future<String> = {
            let promise = Promise<String>()
            schedule_after(0.01) {
                promise.reject(TestError.failed)
            }
            return promise.future!
        }
        let future = test()
        future.onSuccess(ct: cr.token) { value -> () in
            XCTFail("unexpected success")
        }
        future.onComplete { _ in
            expect.fulfill()
        }
        self.waitForExpectations(timeout: 1, handler: nil)
    }

    func testGivenAFulfilledFutureWhenRegisteringSuccessHandlerItShouldExecuteHandler2() {
        let expect = self.expectation(description: "future should be fulfilled")
        let cr = CancellationRequest()
        let test: ()->Future<String> = {
            let promise = Promise<String>(value: "OK")
            return promise.future!
        }
        test().onSuccess(ct: cr.token) { value -> () in
            XCTAssertEqual("OK", value)
            expect.fulfill()
        }
        self.waitForExpectations(timeout: 1, handler: nil)
    }

    func testGivenARejectedFutureWhenRegisteringSuccessHandlerItShouldNotExecuteHandler2() {
        let cr = CancellationRequest()
        let test:()-> Future<String> = {
            let promise = Promise<String>(error: TestError.failed)
            return promise.future!

        }
        test().onSuccess(ct: cr.token) { value -> () in
            XCTFail("unexpected success")
        }
    }





    // MARK: onFailure(on:cancellationToken:_:)

    func testGivenAPendingFutureWithFailureHandlerWhenFulfilledItShouldNotExecuteHandler1() {
        let promise = Promise<String>()
        let test:()->() = {
            let future = promise.future!
            future.onFailure { error -> () in
                XCTFail("unexpected success")
            }
        }
        test()
        promise.fulfill("OK")
    }

    func testGivenAPendingFutureWithFailureHandlerWhenRejectedItShouldExecutedHandler1() {
        let expect = self.expectation(description: "future should be fulfilled")
        let promise = Promise<String>()
        let test:()->() = {
            let future = promise.future!
            future.onFailure { error -> () in
                XCTAssertTrue(TestError.failed == error)
                expect.fulfill()
            }
        }
        test()
        promise.reject(TestError.failed)
        self.waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGivenAFulfilledFutureWhenRegisteringFailureHandlerItShouldNotExecuteHandler1() {
        let promise = Promise<String>(value: "OK")
        let test:()->() = {
            let future = promise.future!
            future.onFailure { value -> () in
                XCTFail("unexpected success")
            }
        }
        test()
    }

    func testGivenARejectedFutureWhenRegisteringFailureHandlerItShouldExecuteHandler1() {
        let expect = self.expectation(description: "future should be fulfilled")
        let promise = Promise<String>(error: TestError.failed)
        let test:()->() = {
            let future = promise.future!
            future.onFailure { error -> () in
                XCTAssertTrue(TestError.failed == error)
                expect.fulfill()
            }
        }
        test()
        self.waitForExpectations(timeout: timeout, handler: nil)
    }


    func testGivenAPendingFutureWithFailureHandlerWhenFulfilledItShouldNotExecuteHandler2() {
        let promise = Promise<String>()
        let cr = CancellationRequest()
        let test:()->() = {
            let future = promise.future!
            future.onFailure(ct: cr.token) { error -> () in
                XCTFail("unexpected success")
            }
        }
        test()
        promise.fulfill("OK")
    }

    func testGivenAPendingFutureWithFailureHandlerWhenRejectedItShouldExecutedHandler2() {
        let expect = self.expectation(description: "future should be fulfilled")
        let promise = Promise<String>()
        let cr = CancellationRequest()
        let test:()->() = {
            let future = promise.future!
            future.onFailure(ct: cr.token) { error -> () in
                XCTAssertTrue(TestError.failed == error)
                expect.fulfill()
            }
        }
        test()
        promise.reject(TestError.failed)
        self.waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGivenAFulfilledFutureWhenRegisteringFailureHandlerItShouldNotExecuteHandler2() {
        let promise = Promise<String>(value: "OK")
        let cr = CancellationRequest()
        let test:()->() = {
            let future = promise.future!
            future.onFailure(ct: cr.token) { error -> () in
                XCTFail("unexpected success")
            }
        }
        test()
    }

    func testGivenARejectedFutureWhenRegisteringFailureHandlerItShouldExecuteHandler2() {
        let expect = self.expectation(description: "future should be fulfilled")
        let promise = Promise<String>(error: TestError.failed)
        let cr = CancellationRequest()
        let test:()->() = {
            let future = promise.future!
            future.onFailure(ct: cr.token) { error -> () in
                XCTAssertTrue(TestError.failed == error)
                expect.fulfill()
            }
        }
        test()
        self.waitForExpectations(timeout: timeout, handler: nil)
    }



}
