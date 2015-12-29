//
//  FutureBasixContinuationsTests.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import XCTest
import FutureLib
import Dispatch


private let timeout: NSTimeInterval = 1

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
        let expect = self.expectationWithDescription("future should be fulfilled")
        let test: ()->Future<String> = {
            let promise = Promise<String>()
            schedule_after(0.01) {
                promise.fulfill("OK")
            }
            return promise.future!
        }
        test().onComplete { r in
            switch (r) {
            case .Success(let value): XCTAssert(value=="OK")
            case .Failure(let error): XCTFail("unexpected error: \(error)")
            }
            expect.fulfill()
        }
        self.waitForExpectationsWithTimeout(timeout, handler: nil)
    }

    func testGivenAPendingFutureWithCompletionHandlerWhenRejectedItShouldExecuteHandler1() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        let test: ()->Future<String> = {
            let promise = Promise<String>()
            schedule_after(0.01) {
                promise.reject(TestError.Failed)
            }
            return promise.future!
        }
        test().onComplete { r in
            switch (r) {
            case .Success: XCTFail("unexpected success")
            case .Failure(let error):
                XCTAssertTrue(TestError.Failed == error)
            }
            expect.fulfill()
        }
        self.waitForExpectationsWithTimeout(timeout, handler: nil)
    }

    func testGivenAFulfilledFutureWhenRegisteringCompletionHandlerItShouldExecuteHandler1() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        let test: ()->Future<String> = {
            let promise = Promise<String>(value: "OK")
            return promise.future!
        }
        test().onComplete { r in
            expect.fulfill()
        }
        self.waitForExpectationsWithTimeout(timeout, handler: nil)
    }

    func testGivenARejectedFutureWhenRegisteringCompletionHandlerItShouldExecuteHandler1() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        let test: ()->Future<String> = {
            let promise = Promise<String>(error: TestError.Failed)
            return promise.future!
        }
        test().onComplete { r -> () in
            switch (r) {
            case .Success: XCTFail("unexpected success")
            case .Failure(let error):
                XCTAssertTrue(TestError.Failed == error)
            }
            expect.fulfill()
        }
        self.waitForExpectationsWithTimeout(timeout, handler: nil)
    }

    // MARK: onComplete(cancellationToken:_:)
    func testGivenAPendingFutureWithCompletionHandlerWhenFulfilledItShouldExecutedHandler2() {
        // with cancellation token
        let expect = self.expectationWithDescription("future should be fulfilled")
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
            case .Success(let value): XCTAssert(value=="OK")
            case .Failure(let error): XCTFail("unexpected error: \(error)")
            }
            expect.fulfill()
        }
        self.waitForExpectationsWithTimeout(timeout, handler: nil)
    }

    func testGivenAPendingFutureWithCompletionHandlerWhenRejectedItShouldExecuteHandler2() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        let cr = CancellationRequest()
        let test: ()->Future<String> = {
            let promise = Promise<String>()
            schedule_after(0.01) {
                promise.reject(TestError.Failed)
            }
            return promise.future!
        }
        test().onComplete(ct: cr.token) { r -> () in
            switch (r) {
            case .Success: XCTFail("unexpected success")
            case .Failure(let error):
                XCTAssertTrue(TestError.Failed == error)
            }
            expect.fulfill()
        }
        self.waitForExpectationsWithTimeout(timeout, handler: nil)
    }

    func testGivenAFulfilledFutureWhenRegisteringCompletionHandlerItShouldExecuteHandler2() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        let cr = CancellationRequest()
        let test: ()->Future<String> = {
            let promise = Promise<String>(value: "OK")
            return promise.future!
        }
        test().onComplete(ct: cr.token) { r -> () in
            switch (r) {
            case .Success(let value): XCTAssert(value=="OK")
            case .Failure(let error): XCTFail("unexpected error: \(error)")
            }
            expect.fulfill()
        }
        self.waitForExpectationsWithTimeout(timeout, handler: nil)
    }

    func testGivenARejectedFutureWhenRegisteringCompletionHandlerItShouldExecuteHandler2() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        let cr = CancellationRequest()
        let test: ()->Future<String> = {
            let promise = Promise<String>(error: TestError.Failed)
            return promise.future!
        }
        test().onComplete(ct: cr.token) { r -> () in
            switch (r) {
            case .Success: XCTFail("unexpected success")
            case .Failure(let error):
                XCTAssertTrue(TestError.Failed == error)
            }
            expect.fulfill()
        }
        self.waitForExpectationsWithTimeout(timeout, handler: nil)
    }


    // MARK: onComplete(cancellationToken:_:) when cancellation requested later

    func testGivenAPendingFutureWithCompletionHandlerAndCancellationTokenWhenCancelledItShouldExecutedHandlerWithCancellationError() {
        // with cancellation token
        let expect = self.expectationWithDescription("future should be fulfilled")
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
            case .Success(let value): XCTFail("unexpected success: \(value)")
            case .Failure(let error):
                XCTAssertTrue(CancellationError.Cancelled == error)
            }
            expect.fulfill()
        }
        schedule_after(0.01) {
            cr.cancel()
        }
        self.waitForExpectationsWithTimeout(timeout, handler: nil)
    }


    func testGivenAFulfilledFutureWithCompletionHandlerAndCancellationTokenWhenCancelledItShouldExecuteHandlerWithResult() {
        let expect1 = self.expectationWithDescription("future should be fulfilled")
        let expect2 = self.expectationWithDescription("cancellation should be requested")
        let cr = CancellationRequest()
        let test: ()->Future<String> = {
            let promise = Promise<String>(value: "OK")
            return promise.future!
        }
        test().onComplete(ct: cr.token) { r -> () in
            switch (r) {
            case .Success(let value): XCTAssert(value=="OK")
            case .Failure(let error): XCTFail("unexpected error: \(error)")
            }
            expect1.fulfill()
        }
        schedule_after(0.01) {
            cr.cancel()
            expect2.fulfill()
        }
        self.waitForExpectationsWithTimeout(timeout, handler: nil)
    }

    func testGivenARejectedFutureWithCompletionHandlerAndCancellationTokenWhenCancelledItShouldExecuteHandlerWithResult() {
        let expect1 = self.expectationWithDescription("future should be fulfilled")
        let expect2 = self.expectationWithDescription("cancellation should be requested")
        let cr = CancellationRequest()
        let test: ()->Future<String> = {
            let promise = Promise<String>(error: TestError.Failed)
            return promise.future!
        }
        test().onComplete(ct: cr.token) { r -> () in
            switch (r) {
            case .Success: XCTFail("unexpected success")
            case .Failure(let error):
                XCTAssertTrue(TestError.Failed == error)
            }
            expect1.fulfill()
        }
        schedule_after(0.01) {
            cr.cancel()
            expect2.fulfill()
        }
        self.waitForExpectationsWithTimeout(timeout, handler: nil)
    }


    // MARK: onComplete(cancellationToken:_:) when cancellation already requested

    func testGivenAPendingFutureWithCompletionHandlerAndCancellationTokenWithCancellationRequestedItShouldExecutedHandlerWithCancellationError() {
        // with cancellation token
        let expect = self.expectationWithDescription("future should be fulfilled")
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
            case .Success(let value): XCTFail("unexpected success: \(value)")
            case .Failure(let error):
                XCTAssertTrue(CancellationError.Cancelled == error)
            }
            expect.fulfill()
        }
        self.waitForExpectationsWithTimeout(timeout, handler: nil)
    }


    func testGivenAFulfilledFutureWithCompletionHandlerAndCancellationTokenWithCancellationRequestedItShouldExecutedHandlerWithCancellationError() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        let cr = CancellationRequest()
        cr.cancel()
        let test: ()->Future<String> = {
            let promise = Promise<String>(value: "OK")
            return promise.future!
        }
        test().onComplete(ct: cr.token) { r -> () in
            switch (r) {
            case .Success(let value): XCTFail("unexpected success: \(value)")
            case .Failure(let error):
                XCTAssertTrue(CancellationError.Cancelled == error)
            }
            expect.fulfill()
        }
        self.waitForExpectationsWithTimeout(timeout, handler: nil)
    }

    func testGivenARejectedFutureWithCompletionHandlerAndCancellationTokenWithCancellationRequestedItShouldExecutedHandlerWithCancellationError() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        let cr = CancellationRequest()
        cr.cancel()
        let test: ()->Future<String> = {
            let promise = Promise<String>(error: TestError.Failed)
            return promise.future!
        }
        test().onComplete(ct: cr.token) { r -> () in
            switch (r) {
            case .Success(let value): XCTFail("unexpected success: \(value)")
            case .Failure(let error):
                XCTAssertTrue(CancellationError.Cancelled == error)
            }
            expect.fulfill()
        }
        self.waitForExpectationsWithTimeout(timeout, handler: nil)
    }



    // MARK: onComplete(on:_:)
    func testGivenAPendingFutureWithCompletionHandlerWhenFulfilledItShouldExecutedHandlerOnGivenExecutionContext() {
        // with cancellation token
        let expect = self.expectationWithDescription("future should be fulfilled")
        let queue = dispatch_queue_create("test_queue", DISPATCH_QUEUE_SERIAL)
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
            case .Success(let value): XCTAssert(value=="OK")
            case .Failure(let error): XCTFail("unexpected error: \(error)")
            }
            let label = String.fromCString(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL))!
            XCTAssertEqual("test_queue", label)
            expect.fulfill()
        }
        self.waitForExpectationsWithTimeout(timeout, handler: nil)
    }

    func testGivenAPendingFutureWithCompletionHandlerWhenRejectedItShouldExecuteHandlerOnGivenExecutionContext() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        let queue = dispatch_queue_create("test_queue", DISPATCH_QUEUE_SERIAL)
        let ec = GCDAsyncExecutionContext(queue)
        let test: ()->Future<String> = {
            let promise = Promise<String>()
            schedule_after(0.01) {
                promise.reject(TestError.Failed)
            }
            return promise.future!
        }
        test().onComplete(ec: ec) { r -> () in
            switch (r) {
            case .Success: XCTFail("unexpected success")
            case .Failure(let error):
                XCTAssertTrue(TestError.Failed == error)
            }
            let label = String.fromCString(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL))!
            XCTAssertEqual("test_queue", label)
            expect.fulfill()
        }
        self.waitForExpectationsWithTimeout(timeout, handler: nil)
    }

    func testGivenAFulfilledFutureWhenRegisteringCompletionHandlerItShouldExecuteHandlerOnGivenExecutionContext() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        let queue = dispatch_queue_create("test_queue", DISPATCH_QUEUE_SERIAL)
        let ec = GCDAsyncExecutionContext(queue)
        let test: ()->Future<String> = {
            let promise = Promise<String>(value: "OK")
            return promise.future!
        }
        test().onComplete(ec: ec) { r -> () in
            let label = String.fromCString(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL))!
            XCTAssertEqual("test_queue", label)
            expect.fulfill()
        }
        self.waitForExpectationsWithTimeout(timeout, handler: nil)
    }

    func testGivenARejectedFutureWhenRegisteringCompletionHandlerItShouldExecuteHandlerOnGivenExecutionContext() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        let queue = dispatch_queue_create("test_queue", DISPATCH_QUEUE_SERIAL)
        let ec = GCDAsyncExecutionContext(queue)
        let test: ()->Future<String> = {
            let promise = Promise<String>(error: TestError.Failed)
            return promise.future!
        }
        test().onComplete(ec: ec) { r -> () in
            switch (r) {
            case .Success: XCTFail("unexpected success")
            case .Failure(let error):
                XCTAssertTrue(TestError.Failed == error)
            }
            let label = String.fromCString(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL))!
            XCTAssertEqual("test_queue", label)
            expect.fulfill()
        }
        self.waitForExpectationsWithTimeout(timeout, handler: nil)
    }



    // MARK: onSuccess(_:)

    func testGivenAPendingFutureWithSuccessHandlerWhenFulfilledItShouldExecuteHandler1() {
        let expect = self.expectationWithDescription("future should be fulfilled")
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
        self.waitForExpectationsWithTimeout(timeout, handler: nil)
    }

    func testGivenAPendingFutureWithSuccessHandlerWhenRejectedItShouldNotExecuteHandler1() {
        let test: ()->Future<String> = {
            let promise = Promise<String>()
            schedule_after(0.01) {
                promise.reject(TestError.Failed)
            }
            return promise.future!
        }
        test().onSuccess { value -> () in
            XCTFail("unexpected success")
        }
        usleep(100000)
    }

    func testGivenAFulfilledFutureWhenRegisteringSuccessHandlerItShouldExecuteHandler1() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        let test: ()->Future<String> = {
            let promise = Promise<String>(value: "OK")
            return promise.future!
        }
        test().onSuccess { value -> () in
            XCTAssertEqual("OK", value)
            expect.fulfill()
        }
        self.waitForExpectationsWithTimeout(timeout, handler: nil)
    }

    func testGivenARejectedFutureWhenRegisteringSuccessHandlerItShouldNotExecutedHandler1() {
        let test: ()->Future<String> = {
            let promise = Promise<String>(error: TestError.Failed)
            return promise.future!
        }
        test().onSuccess { value -> () in
            XCTFail("unexpected success")
        }
        usleep(100000)
    }


    // MARK: onSuccess(cancellationToken:_:)
    func testGivenAPendingFutureWithSuccessHandlerWhenFulfilledItShouldExecuteHandler2() {
        let expect = self.expectationWithDescription("future should be fulfilled")
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
        self.waitForExpectationsWithTimeout(timeout, handler: nil)
    }

    func testGivenAPendingFutureWithSuccessHandlerWhenRejectedItShouldNotExecutedHandler2() {
        let cr = CancellationRequest()
        let test: ()->Future<String> = {
            let promise = Promise<String>()
            schedule_after(0.01) {
                promise.reject(TestError.Failed)
            }
            return promise.future!
        }
        test().onSuccess(ct: cr.token) { value -> () in
            XCTFail("unexpected success")
        }
        usleep(100000)
    }

    func testGivenAFulfilledFutureWhenRegisteringSuccessHandlerItShouldExecuteHandler2() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        let cr = CancellationRequest()
        let test: ()->Future<String> = {
            let promise = Promise<String>(value: "OK")
            return promise.future!
        }
        test().onSuccess(ct: cr.token) { value -> () in
            XCTAssertEqual("OK", value)
            expect.fulfill()
        }
        self.waitForExpectationsWithTimeout(timeout, handler: nil)
    }

    func testGivenARejectedFutureWhenRegisteringSuccessHandlerItShouldNotExecuteHandler2() {
        let cr = CancellationRequest()
        let test:()-> Future<String> = {
            let promise = Promise<String>(error: TestError.Failed)
            return promise.future!

        }
        test().onSuccess(ct: cr.token) { value -> () in
            XCTFail("unexpected success")
        }
        usleep(100000)
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
        usleep(100000)
    }

    func testGivenAPendingFutureWithFailureHandlerWhenRejectedItShouldExecutedHandler1() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        let promise = Promise<String>()
        let test:()->() = {
            let future = promise.future!
            future.onFailure { error -> () in
                XCTAssertTrue(TestError.Failed == error)
                expect.fulfill()
            }
        }
        test()
        promise.reject(TestError.Failed)
        self.waitForExpectationsWithTimeout(timeout, handler: nil)
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
        usleep(100000)
    }

    func testGivenARejectedFutureWhenRegisteringFailureHandlerItShouldExecuteHandler1() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        let promise = Promise<String>(error: TestError.Failed)
        let test:()->() = {
            let future = promise.future!
            future.onFailure { error -> () in
                XCTAssertTrue(TestError.Failed == error)
                expect.fulfill()
            }
        }
        test()
        self.waitForExpectationsWithTimeout(timeout, handler: nil)
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
        usleep(100000)
    }

    func testGivenAPendingFutureWithFailureHandlerWhenRejectedItShouldExecutedHandler2() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        let promise = Promise<String>()
        let cr = CancellationRequest()
        let test:()->() = {
            let future = promise.future!
            future.onFailure(ct: cr.token) { error -> () in
                XCTAssertTrue(TestError.Failed == error)
                expect.fulfill()
            }
        }
        test()
        promise.reject(TestError.Failed)
        self.waitForExpectationsWithTimeout(timeout, handler: nil)
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
        usleep(100000)
    }

    func testGivenARejectedFutureWhenRegisteringFailureHandlerItShouldExecuteHandler2() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        let promise = Promise<String>(error: TestError.Failed)
        let cr = CancellationRequest()
        let test:()->() = {
            let future = promise.future!
            future.onFailure(ct: cr.token) { error -> () in
                XCTAssertTrue(TestError.Failed == error)
                expect.fulfill()
            }
        }
        test()
        self.waitForExpectationsWithTimeout(timeout, handler: nil)
    }



}
