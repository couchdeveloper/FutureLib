//
//  FutureThenExtensionTests.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import XCTest
import FutureLib


private let timeout: NSTimeInterval = 1000


class FutureThenExtensionTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    
    // MARK: then()
    
    func testPendingFutureInvokesThenHandlerWhenCompletedSuccessfully1() {
        let expect = self.expectationWithDescription("future should be fulfilled")
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
        self.waitForExpectationsWithTimeout(timeout, handler: nil)
    }

    func testPendingFutureDoesNotInvokeThenHandlerWhenCompletedWithError1() {
        let asyncTask: ()-> Future<String> = {
            let promise = Promise<String>()
            schedule_after(0.001) {
                promise.reject(TestError.Failed)
            }
            return promise.future!
        }
        asyncTask().then { value in
            XCTFail("unexpected success")
        }
        usleep(100*1000)
    }
    
    
    func testPendingFutureInvokesThenHandlerWhenCompletedSuccessfully2() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        let asyncTask: ()-> Future<String> = {
            let promise = Promise<String>()
            schedule_after(0.001) {
                promise.fulfill("OK")
            }
            return promise.future!
        }
        let dummyFuture = asyncTask().then { value -> Int in
            XCTAssertEqual("OK", value)
            expect.fulfill()
            return 0
        }
        dummyFuture
        self.waitForExpectationsWithTimeout(timeout, handler: nil)
    }
    
    func testPendingFutureDoesNotInvokeThenHandlerWhenCompletedWithError2() {
        let asyncTask: ()-> Future<String> = {
            let promise = Promise<String>()
            schedule_after(0.001) {
                promise.reject(TestError.Failed)
            }
            return promise.future!
        }
        let dummyFuture = asyncTask().then { value -> Int in
            XCTFail("unexpected success")
            return 0
        }
        dummyFuture
        usleep(100*1000)
    }

    
    func testPendingFutureInvokesThenHandlerWhenCompletedSuccessfully3() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        let asyncTask: ()-> Future<String> = {
            let promise = Promise<String>()
            schedule_after(0.001) {
                promise.fulfill("OK")
            }
            return promise.future!
        }
        let dummyFuture = asyncTask().then { value -> Future<Int> in
            XCTAssertEqual("OK", value)
            expect.fulfill()
            return Promise<Int>(value: 0).future!
        }
        dummyFuture
        self.waitForExpectationsWithTimeout(timeout, handler: nil)
    }
    
    func testPendingFutureDoesNotInvokeThenHandlerWhenCompletedWithError3() {
        let asyncTask: ()-> Future<String> = {
            let promise = Promise<String>()
            schedule_after(0.001) {
                promise.reject(TestError.Failed)
            }
            return promise.future!
        }
        let dummyFuture = asyncTask().then { value -> Future<Int> in
            XCTFail("unexpected success")
            return Promise(value: 0).future!
        }
        dummyFuture
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
