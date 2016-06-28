//
//  FutureThenExtensionTests.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import XCTest
import FutureLib


private let timeout: Foundation.TimeInterval = 1000


class FutureThenExtensionTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
    func testGivenAPendingFutureWithRegisteredSuccessHandlerWhenFulfilledItShouldRunItsSuccessHandler() {
        let expect = self.expectation(withDescription: "future should be fulfilled")
        let test: ()->Future<String> = {
            let promise = Promise<String>()
            schedule_after(0.1) {
                promise.fulfill("OK")
            }
            return promise.future!
        }
        test().then { str in
            XCTAssertEqual("OK", str)
            expect.fulfill()
        }
        self.waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    
    func testGivenAFulfilledFutureWithRegisteredSuccessHandlerItShouldExecuteItsSuccessHandler() {
        let expect = self.expectation(withDescription: "future should be fulfilled")
        let test: ()->Future<String> = {
            let promise = Promise<String>(value: "OK")
            return promise.future!
        }
        test().then { str in
            XCTAssertEqual("OK", str)
            expect.fulfill()
        }
        self.waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    
    func testGivenAPendingFutureWithRegisteredFailureHandlerWhenRejectedItShouldRunItsFailureHandler() {
        let expect = self.expectation(withDescription: "future should be rejected")
        let test: ()->Future<String> = {
            let promise = Promise<String>()
            schedule_after(0.1) {
                promise.reject(TestError.failed)
            }
            return promise.future!
        }
        test().onFailure { error -> () in
            XCTAssertTrue(TestError.failed == error)
            expect.fulfill()
        }
        self.waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    func testGivenARejectedFutureWhenRegisteringFailureHandlerItShouldRunItsFailureHandler() {
        let expect = self.expectation(withDescription: "future should be rejected")
        let test:()->Future<String> = {
            let promise = Promise<String>(error: TestError.failed)
            return promise.future!
        }
        test().onFailure { error -> () in
            XCTAssertTrue(TestError.failed == error)
            expect.fulfill()
        }
        self.waitForExpectations(withTimeout: 10, handler: nil)
    }
    
    
    func testGivenAPendingFutureWithRegisteredSuccessHandlerItShouldExecuteItsSuccessHandlerOnTheMainThread() {
        let expect = self.expectation(withDescription: "future should be fulfilled")
        let test: ()->Future<String> = {
            let promise = Promise<String>()
            schedule_after(0.1) {
                promise.fulfill("OK")
            }
            return promise.future!
        }
        test().then(ec: GCDAsyncExecutionContext(DispatchQueue.main)) { str in
            XCTAssertTrue(Thread.isMainThread())
            expect.fulfill()
        }
        self.waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    func testGivenAFulfilledFutureWithRegisteredSuccessHandlerItShouldExecuteItsSuccessHandlerOnTheMainThread() {
        let expect = self.expectation(withDescription: "future should be fulfilled")
        let test: ()->Future<String> = {
            let promise = Promise<String>(value: "OK")
            return promise.future!
        }
        test().then(ec: GCDAsyncExecutionContext(DispatchQueue.main)) { str in
            XCTAssertTrue(Thread.isMainThread())
            expect.fulfill()
        }
        self.waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    
    
    func testExample3() {
        let expect1 = self.expectation(withDescription: "future1 should be fulfilled")
        let expect2 = self.expectation(withDescription: "future2 should be fulfilled")
        let expect3 = self.expectation(withDescription: "future3 should be fulfilled")
        let expect4 = self.expectation(withDescription: "future4 should be fulfilled")
        let expect5 = self.expectation(withDescription: "future5 should be fulfilled")
        let promise = Promise<String>()
        let future = promise.future!
        future.then { str -> Int in
            XCTAssertEqual("OK", str)
            expect1.fulfill()
            return 1
            }
            .then { x -> Int in
                XCTAssertEqual(1, x)
                expect2.fulfill()
                return 2
            }
            .then { x -> Int in
                XCTAssertEqual(2, x)
                expect3.fulfill()
                return 3
            }
            .then { x -> String in
                XCTAssertEqual(3, x)
                expect4.fulfill()
                return "done"
            }
            .then { _ in
                0
            }
            .then { x in
                XCTAssertEqual(0, x)
                expect5.fulfill()
        }
        
        promise.fulfill("OK")
        waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    
    func testExample5() {
        let expect = self.expectation(withDescription: "future should be rejected")
        let promise = Promise<String>()
        let future = promise.future!
        future.then { str -> Int in
            XCTAssertEqual("OK", str)
            return 1
            }
            .then { x -> Int in
                XCTAssertEqual(1, x)
                if x != 0 {
                    throw TestError.failed
                }
                else {
                    return x
                }
            }
            .recover { err -> Int in
                XCTAssertTrue(TestError.failed == err)
                return -1
            }
            .then { x -> String in
                XCTAssertEqual(-1, x)
                return "unused"
            }
            .finally { _ -> () in
                expect.fulfill()
        }
        promise.fulfill("OK")
        waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    
    func testExample6() {
        let expect = self.expectation(withDescription: "future should be fulfilled")
        let promise = Promise<String>()
        let future = promise.future!
        future.then { str -> Int in
            XCTAssertEqual("OK", str)
            return 1
            }
            .then { x -> Int in
                XCTAssertEqual(1, x)
                return 2
            }
            .recover { err -> Int in
                XCTFail("unexpected")
                return -1
            }
            .then { x -> String in
                XCTAssertEqual(2, x)
                return "unused"
            }
            .finally { _ -> () in
                expect.fulfill()
        }
        promise.fulfill("OK")
        waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    
    func testExample7() {
        let expect = self.expectation(withDescription: "future should be fulfilled")
        let promise = Promise<String>()
        let future = promise.future!
        future.then { str -> Int in
            XCTAssertEqual("OK", str)
            return 1
            }
            .then { x -> Future<Int> in
                XCTAssertEqual(1, x)
                let promise = Promise(value: 2)
                return promise.future!
            }
            .then { x -> String in
                XCTAssertEqual(2, x)
                return "unused"
            }
            .finally { _ -> () in
                expect.fulfill()
        }
        promise.fulfill("OK")
        waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    
    func testExample8() {
        let expect = self.expectation(withDescription: "future should be fulfilled")
        let promise = Promise<String>()
        let future = promise.future!
        future.then { str -> Int in
            return 1
            }
            .then { x -> Future<Int> in
                XCTAssertEqual(1, x)
                let promise = Promise<Int>()
                DispatchQueue.main.async {
                    promise.fulfill(2)
                }
                return promise.future!
            }
            .then { x -> String in
                XCTAssertEqual(2, x)
                return "unused"
            }
            .finally { _ -> () in
                expect.fulfill()
        }
        promise.fulfill("OK")
        waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    
    func testPromiseFulfillingAPromiseShouldInvokeSuccessHandler() {
        let promise = Promise<String>()
        let future = promise.future!
        let expect = self.expectation(withDescription: "future should be fulfilled")
        future.then { str -> () in
            XCTAssertEqual("OK", str, "Input value should be equal \"OK\"")
            expect.fulfill()
        }
        promise.fulfill("OK")
        waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    func testPromiseFulfillingAPromiseShouldNotInvokeFailureHandler() {
        let promise = Promise<String>()
        let future = promise.future!
        let expect = self.expectation(withDescription: "future should be fulfilled")
        future.recover { str -> String in
            XCTFail("Not expected")
            expect.fulfill()
            return "Fail"
            }
            .then { str -> () in
                XCTAssertEqual("OK", str, "Input value should be equal \"OK\"")
                expect.fulfill()
        }
        promise.fulfill("OK")
        waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    func testContinuationReturnsFulfilledResultAndThenInvokesNextContinuation() {
        let promise = Promise<String>()
        let future = promise.future!
        let expect = self.expectation(withDescription: "future should be fulfilled")
        let _ = future.then { result -> String in
            if result == "OK" {
                return "OK"
            }
            else {
                throw TestError.failed
            }
            }
            .then { str -> Int in
                XCTAssertEqual("OK", str, "Input value should be equal \"OK\"")
                expect.fulfill()
                return 0
            }
            .recover { err -> Int in
                return -1
        }
        
        promise.fulfill("OK")
        waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    


    // MARK: then()

    func testPendingFutureInvokesThenHandlerWhenCompletedSuccessfully1() {
        let expect = self.expectation(withDescription: "future should be fulfilled")
        let asyncTask: ()-> Future<String> = {
            let promise = Promise<String>()
            schedule_after(0.001) {
                promise.fulfill("OK")
            }
            return promise.future!
        }
        asyncTask().then { value in
            XCTAssertEqual("OK", value)
            expect.fulfill()
        }
        self.waitForExpectations(withTimeout: timeout, handler: nil)
    }

    func testPendingFutureDoesNotInvokeThenHandlerWhenCompletedWithError1() {
        let asyncTask: ()-> Future<String> = {
            let promise = Promise<String>()
            schedule_after(0.001) {
                promise.reject(TestError.failed)
            }
            return promise.future!
        }
        asyncTask().then { value in
            XCTFail("unexpected success")
        }
        usleep(100*1000)
    }


    func testPendingFutureInvokesThenHandlerWhenCompletedSuccessfully2() {
        let expect = self.expectation(withDescription: "future should be fulfilled")
        let asyncTask: ()-> Future<String> = {
            let promise = Promise<String>()
            schedule_after(0.001) {
                promise.fulfill("OK")
            }
            return promise.future!
        }
        _ = asyncTask().then { value -> Int in
            XCTAssertEqual("OK", value)
            expect.fulfill()
            return 0
        }
        self.waitForExpectations(withTimeout: timeout, handler: nil)
    }

    func testPendingFutureDoesNotInvokeThenHandlerWhenCompletedWithError2() {
        let asyncTask: ()-> Future<String> = {
            let promise = Promise<String>()
            schedule_after(0.001) {
                promise.reject(TestError.failed)
            }
            return promise.future!
        }
        _ = asyncTask().then { value -> Int in
            XCTFail("unexpected success")
            return 0
        }
        usleep(100*1000)
    }


    func testPendingFutureInvokesThenHandlerWhenCompletedSuccessfully3() {
        // TODO: remove sleep
        sleep(1)
        let expect = self.expectation(withDescription: "future should be fulfilled")
        let asyncTask: ()-> Future<String> = {
            let promise = Promise<String>()
            schedule_after(0.001) {
                promise.fulfill("OK")
            }
            return promise.future!
        }
        _ = asyncTask().then { value -> Future<Int> in
            XCTAssertEqual("OK", value)
            expect.fulfill()
            return Promise<Int>(value: 0).future!
        }
        self.waitForExpectations(withTimeout: timeout, handler: nil)
    }

    func testPendingFutureDoesNotInvokeThenHandlerWhenCompletedWithError3() {
        let asyncTask: ()-> Future<String> = {
            let promise = Promise<String>()
            schedule_after(0.001) {
                promise.reject(TestError.failed)
            }
            return promise.future!
        }
        _ = asyncTask().then { value -> Future<Int> in
            XCTFail("unexpected success")
            return Promise(value: 0).future!
        }
        usleep(100*1000)
    }


//    // MARK: then(:onSuccess:onFailure)
//
//    func testPendingFutureInvokesOnSuccessHandlerWhenCompletedSuccessfully1() {
//        let expect = self.expectationWithDescription("future should be fulfilled")
//        let asyncTask: ()-> Future<String> = {
//            let promise = Promise<String>()
//            schedule_after(0.001) {
//                promise.fulfill("OK")
//            }
//            return promise.future!
//        }
//        asyncTask().then(onSuccess: { value in
//            XCTAssertEqual("OK", value)
//            expect.fulfill()
//        }, onFailure: { error in
//            XCTFail("unexpected failure")
//        })
//        self.waitForExpectationsWithTimeout(timeout, handler: nil)
//    }



//    func testPendingFutureInvokesOnFailureHandlerWhenCompletedWithError() {
//        let expect = self.expectationWithDescription("future should be fulfilled")
//        let asyncTask: ()-> Future<String> = {
//            let promise = Promise<String>()
//            schedule_after(0.001) {
//                promise.reject(TestError.Failed)
//            }
//            return promise.future!
//        }
//        asyncTask().then(onSuccess: { value in
//            XCTFail("unexpected success")
//        }, onFailure: { error in
//            XCTAssertTrue(TestError.Failed.isEqual(error))
//            expect.fulfill()
//        })
//        self.waitForExpectationsWithTimeout(timeout, handler: nil)
//    }

}
