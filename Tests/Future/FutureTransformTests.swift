//
//  FutureTransformTests.swift
//  FutureLib
//
//  Created by Andreas Grosam on 15/02/16.
//  Copyright © 2016 Andreas Grosam. All rights reserved.
//

import XCTest
import FutureLib


class FutureTransformTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    

    // MARK: transform(ec:ct:s:f:)
    
    func testTransform1WithSucceedFuture() {
        let expect = self.expectation(description: "future should be completed")
        
        let future = Future.succeeded(0)
        
        future.transform(s: {_ in 1}, f:{_ in TestError.failed2}).onSuccess { value in
            XCTAssertEqual(1, value)
            expect.fulfill()
        }
        
        self.waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    
    func testTransform1WithFailedFuture() {
        let expect = self.expectation(description: "future should be completed")
        
        let future = Future<Int>.failed(TestError.failed)
        
        future.transform(s: {_ in 1}, f:{_ in TestError.failed2}).onFailure { error in
            XCTAssertTrue(TestError.failed2 == error)
            expect.fulfill()
        }
        
        self.waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    func testTransform1WithSucceedFutureWithThrowingFunction() {
        let expect = self.expectation(description: "future should be completed")
        
        let future = Future.succeeded(0)
        
        future.transform(s: {_ in throw TestError.failed}, f:{_ in TestError.failed2}).map { value in
            XCTFail("unexpected success")
            expect.fulfill()
        }.onFailure { error in
            XCTAssertTrue(TestError.failed == error)
            expect.fulfill()
        }
        
        self.waitForExpectations(withTimeout: 1, handler: nil)
    }
    

    func testTransform1WithPendingFutureWithCancellation() {
        let expect = self.expectation(description: "future should be completed")
        let cr = CancellationRequest()
        schedule_after(0.1) {
            cr.cancel()
        }
        
        let future = Promise.resolveAfter(1.0) { 0 }.future!
        
        future.transform(ct: cr.token, s: {_ in 1}, f:{ $0 }).map { value in
            XCTFail("unexpected success")
            expect.fulfill()
        }.onFailure { error in
            XCTAssertTrue(CancellationError.cancelled == error, "Error: \(String(reflecting: error))")
            expect.fulfill()
        }
        
        self.waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    

    // MARK: transform(ec:ct:f:)
    
    func testTransform2WithSucceedFuture() {
        let expect = self.expectation(description: "future should be completed")
        
        let future = Future.succeeded(0)
        
        future.transform { result -> Try<String> in
            switch result {
            case .success(let value) where value == 0: return Try("OK")
            default: return Try(error: TestError.failed)
            }
        }.map { value in
            XCTAssertEqual("OK", value)
            expect.fulfill()
        }.onFailure { error in
            XCTFail("unexpected error \(error)")
            expect.fulfill()
        }
        
        self.waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    
    func testTransform2WithFailedFuture() {
        let expect = self.expectation(description: "future should be completed")
        
        let future = Future<Int>.failed(TestError.failed)
        
        future.transform { result -> Try<String> in
            switch result {
            case .success(let value) where value == 0: return Try("OK")
            default: return Try(error: TestError.failed2)
            }
        }.map { value in
            XCTFail("unexpected success")
            expect.fulfill()
        }.onFailure { error in
            XCTAssertTrue(TestError.failed2 == error)
            expect.fulfill()
        }
        
        self.waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    
    func testTransform2WithSucceedFutureWithThrowingFunction() {
        let expect = self.expectation(withDescription: "future should be completed")
        
        let future = Future.succeeded(0)
        
        future.transform { result -> Try<String> in
            switch result {
            case .success(let value) where value == 0:
                throw TestError.failed
            default:
                return Try(error: TestError.failed2)
            }
        }.map { value in
            XCTFail("unexpected success: \(value)")
            expect.fulfill()
        }.onFailure { error in
            XCTAssertTrue(TestError.failed == error)
            expect.fulfill()
        }
        
        self.waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    func testTransform2WithPendingFutureWithCancellation() {
        let expect = self.expectation(description: "future should be completed")
        let cr = CancellationRequest()
        schedule_after(0.1) {
            cr.cancel()
        }
        
        let future = Promise.resolveAfter(1.0) { 0 }.future!
        
        future.transform(ct: cr.token) {result -> Try<String> in
            switch result {
            case .success(let value) where value == 0:
                throw TestError.failed
            case .failure(let error) where CancellationError.cancelled == error:
                return Try(error: error)
            default:
                return Try(error: TestError.failed2)
            }
        }
        .map { value in
            XCTFail("unexpected success")
            expect.fulfill()
        }.onFailure { error in
            XCTAssertTrue(CancellationError.cancelled == error, "Error: \(String(reflecting: error))")
            expect.fulfill()
        }
        
        self.waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    

    
    // MARK: transformWith(ec:ct:f:)
    
    func testTransformWith_WithSucceedFuture() {
        let expect = self.expectation(description: "future should be completed")
        
        let future = Future.succeeded(0)
        
        future.transformWith { result -> Future<String> in
            switch result {
            case .success(let value) where value == 0: return Future.succeeded("OK")
            default: return Future.failed(TestError.failed)
            }
            }.map { value in
                XCTAssertEqual("OK", value)
                expect.fulfill()
            }.onFailure { error in
                XCTFail("unexpected error \(error)")
                expect.fulfill()
        }
        
        self.waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    
    func testTransformWith_WithFailedFuture() {
        let expect = self.expectation(description: "future should be completed")
        
        let future = Future<Int>.failed(TestError.failed)
        
        future.transformWith { result -> Future<String> in
            switch result {
            case .success(let value) where value == 0: return Future.succeeded("OK")
            default: return Future.failed(TestError.failed2)
            }
        }.map { value in
            XCTFail("unexpected success")
            expect.fulfill()
        }.onFailure { error in
            XCTAssertTrue(TestError.failed2 == error)
            expect.fulfill()
        }
        
        self.waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    
    func testTransformWith_WithSucceedFutureWithThrowingFunction() {
        let expect = self.expectation(withDescription: "future should be completed")
        
        let future = Future.succeeded(0)
        
        future.transformWith { result -> Future<String> in
            switch result {
            case .success(let value) where value == 0:
                throw TestError.failed
            default:
                return Future.failed(TestError.failed2)
            }
        }.map { value in
            XCTFail("unexpected success")
            expect.fulfill()
        }.onFailure { error in
            XCTAssertTrue(TestError.failed == error)
            expect.fulfill()
        }
        
        self.waitForExpectations(withTimeout: 1, handler: nil)
    }
    

    func testTransformWith_WithPendingFutureWithPrematureCancellation() {
        let expect = self.expectation(description: "future should be completed")
        
        let future = Promise.resolveAfter(1.0) { 0 }.future!
        let cr = CancellationRequest()
        schedule_after(0.1) {
            cr.cancel()
        }
        
        future.transformWith(ct: cr.token) { result -> Future<String> in
            switch result {
            case .success(let value) where value == 0:
                throw TestError.failed
            case .failure(let error) where CancellationError.cancelled == error:
                return Future.failed(error)
            default:
                return Future.failed(TestError.failed2)
            }
        }.map { value in
            XCTFail("unexpected success")
            expect.fulfill()
        }.onFailure { error in
            XCTAssertTrue(CancellationError.cancelled == error, "Error: \(String(reflecting: error))")
            expect.fulfill()
        }
        
        self.waitForExpectations(withTimeout: 1, handler: nil)
    }
    

    

}
