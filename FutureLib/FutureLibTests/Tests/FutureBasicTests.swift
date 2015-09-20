//
//  FutureBaseTests.swift
//  FutureLib
//
//  Created by Andreas Grosam on 04/08/15.
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import XCTest
import FutureLib

class FutureBasicTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    
    
    //
    // OnComplete
    //
    
    func testGivenAPendingFutureWithCompletionHandlerWhenFulfilledItShouldExecuteHandler1() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        let promise = Promise<String>()
        let test:()->() = {
            let future = promise.future!
            future.onComplete { r -> () in
                switch (r) {
                case .Success(let value): XCTAssert(value=="OK")
                case .Failure(let error): XCTFail("unexpected error: \(error)")
                }
                expect.fulfill()
            }
        }
        test()
        promise.fulfill("OK")
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testGivenAPendingFutureWithCompletionHandlerWhenRejectedItShouldExecuteHandler1() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        let promise = Promise<String>()
        let test:()->() = {
            let future = promise.future!
            future.onComplete { r -> () in
                switch (r) {
                case .Success: XCTFail("unexpected success")
                case .Failure(let error):
                    XCTAssertTrue(TestError.Failed.isEqual(error))
                }
                expect.fulfill()
            }
        }
        test()
        promise.reject(TestError.Failed)
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testGivenAFulfilledFutureWhenRegisteringCompletionHandlerItShouldExecuteHandler1() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        let promise = Promise<String>(value: "OK")
        let test:()->() = {
            let future = promise.future!
            future.onComplete { r -> () in
                expect.fulfill()
            }
        }
        test()
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testGivenARejectedFutureWhenRegisteringCompletionHandlerItShouldExecuteHandler1() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        let promise = Promise<String>(error: TestError.Failed)
        let test:()->() = {
            let future = promise.future!
            future.onComplete { r -> () in
                switch (r) {
                case .Success: XCTFail("unexpected success")
                case .Failure(let error):
                    XCTAssertTrue(TestError.Failed.isEqual(error))
                }
                expect.fulfill()
            }
        }
        test()
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    
    func testGivenAPendingFutureWithCompletionHandlerWhenFulfilledItShouldExecutedHandler2() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        let promise = Promise<String>()
        let cr = CancellationRequest()
        let test:()->() = {
            let future = promise.future!
            future.onComplete(cancellationToken: cr.token) { r -> () in
                switch (r) {
                case .Success(let value): XCTAssert(value=="OK")
                case .Failure(let error): XCTFail("unexpected error: \(error)")
                }
                expect.fulfill()
            }
        }
        test()
        promise.fulfill("OK")
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testGivenAPendingFutureWithCompletionHandlerWhenRejectedItShouldExecuteHandler2() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        let promise = Promise<String>()
        let cr = CancellationRequest()
        let test:()->() = {
            let future = promise.future!
            future.onComplete(cancellationToken: cr.token) { r -> () in
                switch (r) {
                case .Success: XCTFail("unexpected success")
                case .Failure(let error):
                    XCTAssertTrue(TestError.Failed.isEqual(error))
                }
                expect.fulfill()
            }
        }
        test()
        promise.reject(TestError.Failed)
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testGivenAFulfilledFutureWhenRegisteringCompletionHandlerItShouldExecuteHandler2() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        let promise = Promise<String>(value: "OK")
        let cr = CancellationRequest()
        let test:()->() = {
            let future = promise.future!
            future.onComplete(cancellationToken: cr.token) { r -> () in
                expect.fulfill()
            }
        }
        test()
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testGivenARejectedFutureWhenRegisteringCompletionHandlerItShouldExecuteHandler2() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        let promise = Promise<String>(error: TestError.Failed)
        let cr = CancellationRequest()
        let test:()->() = {
            let future = promise.future!
            future.onComplete(cancellationToken: cr.token) { r -> () in
                switch (r) {
                case .Success: XCTFail("unexpected success")
                case .Failure(let error):
                    XCTAssertTrue(TestError.Failed.isEqual(error))
                }
                expect.fulfill()
            }
        }
        test()
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    

    
    //
    // OnSucess
    //
    
    func testGivenAPendingFutureWithSuccessHandlerWhenFulfilledItShouldExecuteHandler1() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        let promise = Promise<String>()
        let test:()->() = {
            let future = promise.future!
            future.onSuccess { value -> () in
                XCTAssertEqual("OK", value)
                expect.fulfill()
            }
        }
        test()
        promise.fulfill("OK")
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testGivenAPendingFutureWithSuccessHandlerWhenRejectedItShouldNotExecuteHandler1() {
        let promise = Promise<String>()
        let test:()->() = {
            let future = promise.future!
            future.onSuccess { value -> () in
                XCTFail("unexpected success")
            }
        }
        test()
        promise.reject(TestError.Failed)
        usleep(100000)
    }
    
    func testGivenAFulfilledFutureWhenRegisteringSuccessHandlerItShouldExecuteHandler1() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        let promise = Promise<String>(value: "OK")
        let test:()->() = {
            let future = promise.future!
            future.onSuccess { value -> () in
                XCTAssertEqual("OK", value)
                expect.fulfill()
            }
        }
        test()
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testGivenARejectedFutureWhenRegisteringSuccessHandlerItShouldNotExecutedHandler1() {
        let promise = Promise<String>(error: TestError.Failed)
        let test:()->() = {
            let future = promise.future!
            future.onSuccess { value -> () in
                XCTFail("unexpected success")
            }
        }
        test()
        usleep(100000)
    }
    
    
    func testGivenAPendingFutureWithSuccessHandlerWhenFulfilledItShouldExecuteHandler2() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        let promise = Promise<String>()
        let cr = CancellationRequest()
        let test:()->() = {
            let future = promise.future!
            future.onComplete(cancellationToken: cr.token) { value -> () in
                let future = promise.future!
                future.onSuccess { value -> () in
                    XCTAssertEqual("OK", value)
                    expect.fulfill()
                }
            }
        }
        test()
        promise.fulfill("OK")
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testGivenAPendingFutureWithSuccessHandlerWhenRejectedItShouldNotExecutedHandler2() {
        let promise = Promise<String>()
        let cr = CancellationRequest()
        let test:()->() = {
            let future = promise.future!
            future.onSuccess(cancellationToken: cr.token) { value -> () in
                XCTFail("unexpected success")
            }
        }
        test()
        promise.reject(TestError.Failed)
        usleep(100000)
    }
    
    func testGivenAFulfilledFutureWhenRegisteringSuccessHandlerItShouldExecuteHandler2() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        let promise = Promise<String>(value: "OK")
        let cr = CancellationRequest()
        let test:()->() = {
            let future = promise.future!
            future.onSuccess(cancellationToken: cr.token) { value -> () in
                XCTAssertEqual("OK", value)
                expect.fulfill()
            }
        }
        test()
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testGivenARejectedFutureWhenRegisteringSuccessHandlerItShouldNotExecuteHandler2() {
        let promise = Promise<String>(error: TestError.Failed)
        let cr = CancellationRequest()
        let test:()->() = {
            let future = promise.future!
            future.onSuccess(cancellationToken: cr.token) { value -> () in
                XCTFail("unexpected success")
            }
        }
        test()
        usleep(100000)
    }
    
    
    
    

    //
    // OnFailure
    //

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
                XCTAssertTrue(TestError.Failed.isEqual(error))
                expect.fulfill()
            }
        }
        test()
        promise.reject(TestError.Failed)
        self.waitForExpectationsWithTimeout(1, handler: nil)
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
                XCTAssertTrue(TestError.Failed.isEqual(error))
                expect.fulfill()
            }
        }
        test()
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    
    func testGivenAPendingFutureWithFailureHandlerWhenFulfilledItShouldNotExecuteHandler2() {
        let promise = Promise<String>()
        let cr = CancellationRequest()
        let test:()->() = {
            let future = promise.future!
            future.onFailure(cancellationToken: cr.token) { error -> () in
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
            future.onFailure(cancellationToken: cr.token) { error -> () in
                XCTAssertTrue(TestError.Failed.isEqual(error))
                expect.fulfill()
            }
        }
        test()
        promise.reject(TestError.Failed)
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testGivenAFulfilledFutureWhenRegisteringFailureHandlerItShouldNotExecuteHandler2() {
        let promise = Promise<String>(value: "OK")
        let cr = CancellationRequest()
        let test:()->() = {
            let future = promise.future!
            future.onFailure(cancellationToken: cr.token) { error -> () in
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
            future.onFailure(cancellationToken: cr.token) { error -> () in
                XCTAssertTrue(TestError.Failed.isEqual(error))
                expect.fulfill()
            }
        }
        test()
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    
    
    
    
    //
    // map
    //
    
    func testGivenAPendingFutureWithMapFunctionWhenFulfilledItShouldExecuteHandler1() {
        let expect1 = self.expectationWithDescription("future should be fulfilled")
        let expect2 = self.expectationWithDescription("future should be fulfilled")
        let promise = Promise<String>()
        let test:()->Future<Int> = {
            let future = promise.future!
            return future.map { value -> Result<Int> in
                XCTAssertEqual("OK", value)
                expect1.fulfill()
                return Result(1)
            }
        }
        
        test().onSuccess { value -> () in
            XCTAssertEqual(1, value)
            expect2.fulfill()
        }
    
        promise.fulfill("OK")
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testGivenAPendingFutureWithMapFunctionWhenRejectedItShouldPropagateError1() {
        let expect2 = self.expectationWithDescription("future should be fulfilled")
        let promise = Promise<String>()
        let test:()->Future<Int> = {
            let future = promise.future!
            return future.map { value -> Result<Int> in
                XCTFail("unexpected success")
                return Result(1)
            }
        }
        
        test().onFailure { error -> () in
            XCTAssertTrue(TestError.Failed.isEqual(error))
            expect2.fulfill()
        }
        
        promise.reject(TestError.Failed)
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testGivenAPendingFutureWithMapFunctionWhenFulfilledItShouldExecuteHandler2() {
        let expect1 = self.expectationWithDescription("future should be fulfilled")
        let expect2 = self.expectationWithDescription("future should be fulfilled")
        let cr = CancellationRequest()
        let promise = Promise<String>()
        let test:()->Future<Int> = {
            let future = promise.future!
            return future.map(cancellationToken: cr.token) { value -> Result<Int> in
                XCTAssertEqual("OK", value)
                expect1.fulfill()
                return Result(1)
            }
        }
        
        test().onSuccess { value -> () in
            XCTAssertEqual(1, value)
            expect2.fulfill()
        }
        
        promise.fulfill("OK")
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testGivenAPendingFutureWithMapFunctionWhenRejectedItShouldPropagateError2() {
        let expect2 = self.expectationWithDescription("future should be fulfilled")
        let promise = Promise<String>()
        let cr = CancellationRequest()
        let test:()->Future<Int> = {
            let future = promise.future!
            return future.map(cancellationToken: cr.token) { value -> Result<Int> in
                XCTFail("unexpected success")
                return Result(1)
            }
        }
        
        test().onFailure { error -> () in
            XCTAssertTrue(TestError.Failed.isEqual(error))
            expect2.fulfill()
        }
        
        promise.reject(TestError.Failed)
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    

    func testGivenAFulfilledFutureWithMapFunctionItShouldExecuteHandler1() {
        let expect1 = self.expectationWithDescription("future should be fulfilled")
        let expect2 = self.expectationWithDescription("future should be fulfilled")
        let promise = Promise<String>(value: "OK")
        let test:()->Future<Int> = {
            let future = promise.future!
            return future.map { value -> Result<Int> in
                XCTAssertEqual("OK", value)
                expect1.fulfill()
                return Result(1)
            }
        }
        
        test().onSuccess { value -> () in
            XCTAssertEqual(1, value)
            expect2.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testGivenARejectededFutureWithMapFunctionItShouldPropagateError1() {
        let expect2 = self.expectationWithDescription("future should be fulfilled")
        let promise = Promise<String>(error: TestError.Failed)
        let test:()->Future<Int> = {
            let future = promise.future!
            return future.map { value -> Result<Int> in
                XCTFail("unexpected success")
                return Result(1)
            }
        }
        
        test().onFailure { error -> () in
            XCTAssertTrue(TestError.Failed.isEqual(error))
            expect2.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testGivenAFulfilledFutureWithMapFunctionItShouldExecuteHandler2() {
        let expect1 = self.expectationWithDescription("future should be fulfilled")
        let expect2 = self.expectationWithDescription("future should be fulfilled")
        let cr = CancellationRequest()
        let promise = Promise<String>(value: "OK")
        let test:()->Future<Int> = {
            let future = promise.future!
            return future.map(cancellationToken: cr.token) { value -> Result<Int> in
                XCTAssertEqual("OK", value)
                expect1.fulfill()
                return Result(1)
            }
        }
        
        test().onSuccess { value -> () in
            XCTAssertEqual(1, value)
            expect2.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testGivenARejectedFutureWithMapFunctionItShouldPropagateError2() {
        let expect2 = self.expectationWithDescription("future should be fulfilled")
        let promise = Promise<String>(error: TestError.Failed)
        let cr = CancellationRequest()
        let test:()->Future<Int> = {
            let future = promise.future!
            return future.map(cancellationToken: cr.token) { value -> Result<Int> in
                XCTFail("unexpected success")
                return Result(1)
            }
        }
        
        test().onFailure { error -> () in
            XCTAssertTrue(TestError.Failed.isEqual(error))
            expect2.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    

    
    //
    // flatMap
    //
    
    func testGivenAPendingFutureWithFlatMapFunctionWhenFulfilledItShouldExecuteHandler1() {
        let expect1 = self.expectationWithDescription("future should be fulfilled")
        let expect2 = self.expectationWithDescription("future should be fulfilled")
        let promise = Promise<String>()
        promise.future!.flatMap { value -> Future<Int> in
            XCTAssertEqual("OK", value)
            expect1.fulfill()
            return future {1}
        }
        .onSuccess { value -> () in
            XCTAssertEqual(1, value)
            expect2.fulfill()
        }
        
        promise.fulfill("OK")
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testGivenAPendingFutureWithFlatMapFunctionWhenRejectedItShouldPropagateError1() {
        let expect2 = self.expectationWithDescription("future should be fulfilled")
        let promise = Promise<String>()
        promise.future!.flatMap { value -> Future<Int> in
            XCTFail("unexpected success")
            return future {1}
        }
        .onFailure { error -> () in
            XCTAssertTrue(TestError.Failed.isEqual(error))
            expect2.fulfill()
        }
        
        promise.reject(TestError.Failed)
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testGivenAPendingFutureWithFlatMapFunctionWhenFulfilledItShouldExecuteHandler2() {
        let expect1 = self.expectationWithDescription("future should be fulfilled")
        let expect2 = self.expectationWithDescription("future should be fulfilled")
        let cr = CancellationRequest()
        let promise = Promise<String>()
        promise.future!.flatMap(cancellationToken: cr.token) { value -> Future<Int> in
            XCTAssertEqual("OK", value)
            expect1.fulfill()
            return future {1}
        }.onSuccess { value -> () in
            XCTAssertEqual(1, value)
            expect2.fulfill()
        }
        
        promise.fulfill("OK")
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testGivenAPendingFutureWithFlatMapFunctionWhenRejectedItShouldPropagateError2() {
        let expect2 = self.expectationWithDescription("future should be fulfilled")
        let promise = Promise<String>()
        let cr = CancellationRequest()
        promise.future!.flatMap(cancellationToken: cr.token) { value -> Future<Int> in
            XCTFail("unexpected success")
            return future {1}
            }
            .onFailure { error -> () in
                XCTAssertTrue(TestError.Failed.isEqual(error))
                expect2.fulfill()
        }
        
        promise.reject(TestError.Failed)
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    

    func testGivenAFulfilledFutureWithFlatMapFunctionItShouldExecuteHandler1() {
        let expect1 = self.expectationWithDescription("future should be fulfilled")
        let expect2 = self.expectationWithDescription("future should be fulfilled")
        let promise = Promise<String>(value: "OK")
        promise.future!.flatMap { value -> Future<Int> in
            XCTAssertEqual("OK", value)
            expect1.fulfill()
            return future {1}
        }
        .onSuccess { value -> () in
            XCTAssertEqual(1, value)
            expect2.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testGivenARejectededFutureWithFlatMapFunctionItShouldPropagateError1() {
        let expect2 = self.expectationWithDescription("future should be fulfilled")
        let promise = Promise<String>(error: TestError.Failed)
        promise.future!.flatMap { value -> Future<Int> in
            XCTFail("unexpected success")
            return future {1}
        }.onFailure { error -> () in
            XCTAssertTrue(TestError.Failed.isEqual(error))
            expect2.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testGivenAFulfilledFutureWithFlatMapFunctionItShouldExecuteHandler2() {
        let expect1 = self.expectationWithDescription("future should be fulfilled")
        let expect2 = self.expectationWithDescription("future should be fulfilled")
        let cr = CancellationRequest()
        let promise = Promise<String>(value: "OK")
        promise.future!.flatMap(cancellationToken: cr.token) { value -> Future<Int> in
            XCTAssertEqual("OK", value)
            expect1.fulfill()
            return future {1}
        }.onSuccess { value -> () in
            XCTAssertEqual(1, value)
            expect2.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testGivenARejectedFutureWithFlatMapFunctionItShouldPropagateError2() {
        let expect2 = self.expectationWithDescription("future should be fulfilled")
        let promise = Promise<String>(error: TestError.Failed)
        let cr = CancellationRequest()
        promise.future!.flatMap(cancellationToken: cr.token) { value -> Future<Int> in
            XCTFail("unexpected success")
            return future {1}
        }.onFailure { error -> () in
            XCTAssertTrue(TestError.Failed.isEqual(error))
            expect2.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    
// =================================
    

}
