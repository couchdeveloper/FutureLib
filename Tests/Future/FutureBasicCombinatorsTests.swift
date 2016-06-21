//
//  FutureBasicCombinatorsTests.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import XCTest
import FutureLib

private let timeout: Foundation.TimeInterval = 1

/**
    Tests the basic combinators `map` and `flatMap`.
*/
class FutureBasicCombinatorsTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }


    // MARK: map(_:) -> Future

    func testAPI_map() {
        // This test will fail to compile if it fails.
        let ec = ConcurrentAsync()
        let ct = CancellationRequest().token
        let future = Future.succeeded(1)
        let f: (Int) -> String = { $0 == 0 ? "OK" : "Fail" }

        let _ = future.map(ec: ec, ct: ct, f: f)
        let _ = future.map(ec: ec, ct: ct) { $0 }

        let _ = future.map(ct: ct, f: f)
        let _ = future.map(ct: ct) { $0 }

        let _ = future.map(ec: ec, f: f)
        let _ = future.map(ec: ec) { $0 }

        let _ = future.map(f: f)
        let _ = future.map { $0 }
    }


    func testGivenAPendingFutureWithMapFunctionWhenFulfilledItShouldExecuteHandler1() {
        let expect1 = self.expectation(withDescription: "future should be fulfilled")
        let expect2 = self.expectation(withDescription: "future should be fulfilled")
        let promise = Promise<String>()
        let test:()->Future<Int> = {
            let future = promise.future!
            return future.map { value -> Int in
                XCTAssertEqual("OK", value)
                expect1.fulfill()
                return 1
            }
        }

        test().onSuccess { value -> () in
            XCTAssertEqual(1, value)
            expect2.fulfill()
        }

        promise.fulfill("OK")
        self.waitForExpectations(withTimeout: timeout, handler: nil)
    }

    func testGivenAPendingFutureWithThrowingMapFunctionWhenFulfilledItShouldExecuteHandler1() {
        let expect1 = self.expectation(withDescription: "future should be fulfilled")
        let expect2 = self.expectation(withDescription: "future should be fulfilled")
        let promise = Promise<String>()
        let test:()->Future<Int> = {
            let future = promise.future!
            return future.map { value -> Int in
                XCTAssertEqual("OK", value)
                expect1.fulfill()
                throw TestError.failed
            }
        }

        test().onFailure{ error -> () in
            XCTAssertTrue(TestError.failed == error)
            expect2.fulfill()
        }

        promise.fulfill("OK")
        self.waitForExpectations(withTimeout: timeout, handler: nil)
    }


    func testGivenAPendingFutureWithMapFunctionWhenRejectedItShouldPropagateError1() {
        let expect2 = self.expectation(withDescription: "future should be fulfilled")
        let promise = Promise<String>()
        let test:()->Future<Int> = {
            let future = promise.future!
            return future.map { value -> Int in
                XCTFail("unexpected success")
                return 1
            }
        }

        test().onFailure { error -> () in
            XCTAssertTrue(TestError.failed == error)
            expect2.fulfill()
        }

        promise.reject(TestError.failed)
        self.waitForExpectations(withTimeout: timeout, handler: nil)
    }

    func testGivenAPendingFutureWithMapFunctionWhenFulfilledItShouldExecuteHandler2() {
        let expect1 = self.expectation(withDescription: "future should be fulfilled")
        let expect2 = self.expectation(withDescription: "future should be fulfilled")
        let cr = CancellationRequest()
        let promise = Promise<String>()
        let test:()->Future<Int> = {
            let future = promise.future!
            return future.map(ct: cr.token) { value -> Int in
                XCTAssertEqual("OK", value)
                expect1.fulfill()
                return 1
            }
        }

        test().onSuccess { value -> () in
            XCTAssertEqual(1, value)
            expect2.fulfill()
        }

        promise.fulfill("OK")
        self.waitForExpectations(withTimeout: timeout, handler: nil)
    }

    func testGivenAPendingFutureWithThrowingMapFunctionWhenFulfilledItShouldExecuteHandler2() {
        let expect1 = self.expectation(withDescription: "future should be fulfilled")
        let expect2 = self.expectation(withDescription: "future should be fulfilled")
        let cr = CancellationRequest()
        let promise = Promise<String>()
        let test:()->Future<Int> = {
            let future = promise.future!
            return future.map(ct: cr.token) { value -> Int in
                XCTAssertEqual("OK", value)
                expect1.fulfill()
                throw TestError.failed
            }
        }

        test().onFailure { error -> () in
            XCTAssertTrue(TestError.failed == error)
            expect2.fulfill()
        }

        promise.fulfill("OK")
        self.waitForExpectations(withTimeout: timeout, handler: nil)
    }

    func testGivenAPendingFutureWithMapFunctionWhenRejectedItShouldPropagateError2() {
        let expect2 = self.expectation(withDescription: "future should be fulfilled")
        let promise = Promise<String>()
        let cr = CancellationRequest()
        let test:()->Future<Int> = {
            let future = promise.future!
            return future.map(ct: cr.token) { value -> Int in
                XCTFail("unexpected success")
                return 1
            }
        }

        test().onFailure { error -> () in
            XCTAssertTrue(TestError.failed == error)
            expect2.fulfill()
        }

        promise.reject(TestError.failed)
        self.waitForExpectations(withTimeout: timeout, handler: nil)
    }


    func testGivenAFulfilledFutureWithMapFunctionItShouldExecuteHandler1() {
        let expect1 = self.expectation(withDescription: "future should be fulfilled")
        let expect2 = self.expectation(withDescription: "future should be fulfilled")
        let promise = Promise<String>(value: "OK")
        let test:()->Future<Int> = {
            let future = promise.future!
            return future.map { value -> Int in
                XCTAssertEqual("OK", value)
                expect1.fulfill()
                return 1
            }
        }

        test().onSuccess { value -> () in
            XCTAssertEqual(1, value)
            expect2.fulfill()
        }

        self.waitForExpectations(withTimeout: timeout, handler: nil)
    }

    func testGivenAFulfilledFutureWithThrowingMapFunctionItShouldExecuteHandler1() {
        let expect1 = self.expectation(withDescription: "future should be fulfilled")
        let expect2 = self.expectation(withDescription: "future should be fulfilled")
        let promise = Promise<String>(value: "OK")
        let test:()->Future<Int> = {
            let future = promise.future!
            return future.map { value -> Int in
                XCTAssertEqual("OK", value)
                expect1.fulfill()
                throw TestError.failed
            }
        }

        test().onFailure { error -> () in
            XCTAssertTrue(TestError.failed == error)
            expect2.fulfill()
        }

        self.waitForExpectations(withTimeout: timeout, handler: nil)
    }

    func testGivenARejectededFutureWithMapFunctionItShouldPropagateError1() {
        let expect2 = self.expectation(withDescription: "future should be fulfilled")
        let promise = Promise<String>(error: TestError.failed)
        let test:()->Future<Int> = {
            let future = promise.future!
            return future.map { value -> Int in
                XCTFail("unexpected success")
                return 1
            }
        }

        test().onFailure { error -> () in
            XCTAssertTrue(TestError.failed == error)
            expect2.fulfill()
        }

        self.waitForExpectations(withTimeout: timeout, handler: nil)
    }

    func testGivenAFulfilledFutureWithMapFunctionItShouldExecuteHandler2() {
        let expect1 = self.expectation(withDescription: "future should be fulfilled")
        let expect2 = self.expectation(withDescription: "future should be fulfilled")
        let cr = CancellationRequest()
        let promise = Promise<String>(value: "OK")
        let test:()->Future<Int> = {
            let future = promise.future!
            return future.map(ct: cr.token) { value -> Int in
                XCTAssertEqual("OK", value)
                expect1.fulfill()
                return 1
            }
        }

        test().onSuccess { value -> () in
            XCTAssertEqual(1, value)
            expect2.fulfill()
        }

        self.waitForExpectations(withTimeout: timeout, handler: nil)
    }

    func testGivenAFulfilledFutureWithThrowingMapFunctionItShouldExecuteHandler2() {
        let expect1 = self.expectation(withDescription: "future should be fulfilled")
        let expect2 = self.expectation(withDescription: "future should be fulfilled")
        let cr = CancellationRequest()
        let promise = Promise<String>(value: "OK")
        let test:()->Future<Int> = {
            let future = promise.future!
            return future.map(ct: cr.token) { value -> Int in
                XCTAssertEqual("OK", value)
                expect1.fulfill()
                throw TestError.failed
            }
        }

        test().onFailure { error -> () in
            XCTAssertTrue(TestError.failed == error)
            expect2.fulfill()
        }

        self.waitForExpectations(withTimeout: timeout, handler: nil)
    }

    func testGivenARejectedFutureWithMapFunctionItShouldPropagateError2() {
        let expect2 = self.expectation(withDescription: "future should be fulfilled")
        let promise = Promise<String>(error: TestError.failed)
        let cr = CancellationRequest()
        let test:()->Future<Int> = {
            let future = promise.future!
            return future.map(ct: cr.token) { value -> Int in
                XCTFail("unexpected success")
                return 1
            }
        }

        test().onFailure { error -> () in
            XCTAssertTrue(TestError.failed == error)
            expect2.fulfill()
        }

        self.waitForExpectations(withTimeout: timeout, handler: nil)
    }



    // MARK: flatMap(_:) -> Future
    
    func testAPI_flatMap() {
        // This test will fail to compile if it fails.
        let ec = ConcurrentAsync()
        let ct = CancellationRequest().token
        let future = Future.succeeded(1)
        let f: (Int) -> Future<String> = { $0 == 0 ? Future.succeeded("OK") : Future.succeeded("Fail") }
        
        let _ = future.flatMap(ec: ec, ct: ct, f: f)
        let _ = future.flatMap(ec: ec, ct: ct) { Future.succeeded($0) }
        
        let _ = future.flatMap(ct: ct, f: f)
        let _ = future.flatMap(ct: ct) { Future.succeeded($0) }
        
        let _ = future.flatMap(ec: ec, f: f)
        let _ = future.flatMap(ec: ec) { Future.succeeded($0) }
        
        let _ = future.flatMap(f: f)
        let _ = future.flatMap { Future.succeeded($0) }
    }
    


    func testGivenAPendingFutureWithFlatMapFunctionWhenFulfilledItShouldExecuteHandler1() {
        let expect1 = self.expectation(withDescription: "future should be fulfilled")
        let expect2 = self.expectation(withDescription: "future should be fulfilled")
        let promise = Promise<String>()
        promise.future!.flatMap { value -> Future<Int> in
            XCTAssertEqual("OK", value)
            expect1.fulfill()
            return Future.succeeded(1)
        }
        .onSuccess { value -> () in
            XCTAssertEqual(1, value)
            expect2.fulfill()
        }

        promise.fulfill("OK")
        self.waitForExpectations(withTimeout: timeout, handler: nil)
    }

    func testGivenAPendingFutureWithFlatMapFunctionWhenRejectedItShouldPropagateError1() {
        let expect2 = self.expectation(withDescription: "future should be fulfilled")
        let promise = Promise<String>()
        promise.future!.flatMap { value -> Future<Int> in
            XCTFail("unexpected success")
            return Future.succeeded(1)
        }
        .onFailure { error -> () in
            XCTAssertTrue(TestError.failed == error)
            expect2.fulfill()
        }

        promise.reject(TestError.failed)
        self.waitForExpectations(withTimeout: timeout, handler: nil)
    }

    func testGivenAPendingFutureWithFlatMapFunctionWhenFulfilledItShouldExecuteHandler2() {
        let expect1 = self.expectation(withDescription: "future should be fulfilled")
        let expect2 = self.expectation(withDescription: "future should be fulfilled")
        let cr = CancellationRequest()
        let promise = Promise<String>()
        promise.future!.flatMap(ct: cr.token) { value -> Future<Int> in
            XCTAssertEqual("OK", value)
            expect1.fulfill()
            return Future.succeeded(1)
        }
        .onSuccess { value -> () in
            XCTAssertEqual(1, value)
            expect2.fulfill()
        }

        promise.fulfill("OK")
        self.waitForExpectations(withTimeout: timeout, handler: nil)
    }

    func testGivenAPendingFutureWithFlatMapFunctionWhenRejectedItShouldPropagateError2() {
        let expect2 = self.expectation(withDescription: "future should be fulfilled")
        let promise = Promise<String>()
        let cr = CancellationRequest()
        promise.future!.flatMap(ct: cr.token) { value -> Future<Int> in
            XCTFail("unexpected success")
            return Future.succeeded(1)
        }
        .onFailure { error -> () in
            XCTAssertTrue(TestError.failed == error)
            expect2.fulfill()
        }

        promise.reject(TestError.failed)
        self.waitForExpectations(withTimeout: timeout, handler: nil)
    }


    func testGivenAFulfilledFutureWithFlatMapFunctionItShouldExecuteHandler1() {
        let expect1 = self.expectation(withDescription: "future should be fulfilled")
        let expect2 = self.expectation(withDescription: "future should be fulfilled")
        let promise = Promise<String>(value: "OK")
        promise.future!.flatMap { value -> Future<Int> in
            XCTAssertEqual("OK", value)
            expect1.fulfill()
            return Future.succeeded(1)
        }
        .onSuccess { value -> () in
            XCTAssertEqual(1, value)
            expect2.fulfill()
        }

        self.waitForExpectations(withTimeout: timeout, handler: nil)
    }

    func testGivenARejectededFutureWithFlatMapFunctionItShouldPropagateError1() {
        let expect2 = self.expectation(withDescription: "future should be fulfilled")
        let promise = Promise<String>(error: TestError.failed)
        promise.future!.flatMap { value -> Future<Int> in
            XCTFail("unexpected success")
            return Future.succeeded(1)
        }
        .onFailure { error -> () in
            XCTAssertTrue(TestError.failed == error)
            expect2.fulfill()
        }

        self.waitForExpectations(withTimeout: timeout, handler: nil)
    }

    func testGivenAFulfilledFutureWithFlatMapFunctionItShouldExecuteHandler2() {
        let expect1 = self.expectation(withDescription: "future should be fulfilled")
        let expect2 = self.expectation(withDescription: "future should be fulfilled")
        let cr = CancellationRequest()
        let promise = Promise<String>(value: "OK")
        promise.future!.flatMap(ct: cr.token) { value -> Future<Int> in
            XCTAssertEqual("OK", value)
            expect1.fulfill()
            return Future.succeeded(1)
        }
        .onSuccess { value -> () in
            XCTAssertEqual(1, value)
            expect2.fulfill()
        }

        self.waitForExpectations(withTimeout: timeout, handler: nil)
    }

    func testGivenARejectedFutureWithFlatMapFunctionItShouldPropagateError2() {
        let expect2 = self.expectation(withDescription: "future should be fulfilled")
        let promise = Promise<String>(error: TestError.failed)
        let cr = CancellationRequest()
        promise.future!.flatMap(ct: cr.token) { value -> Future<Int> in
            XCTFail("unexpected success")
            return Future.succeeded(1)
        }
        .onFailure { error -> () in
            XCTAssertTrue(TestError.failed == error)
            expect2.fulfill()
        }

        self.waitForExpectations(withTimeout: timeout, handler: nil)
    }



}
