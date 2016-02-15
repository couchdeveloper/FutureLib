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
    
    

    // MARK: transform
    
    func testTransform1WithSucceedFuture() {
        let expect = self.expectationWithDescription("future should be completed")
        
        let future = Future.succeeded(0)
        
        future.transform(s: {_ in 1}, f:{_ in TestError.Failed2}).onSuccess { value in
            XCTAssertEqual(1, value)
            expect.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    
    func testTransform1WithFailedFuture() {
        let expect = self.expectationWithDescription("future should be completed")
        
        let future = Future<Int>.failed(TestError.Failed)
        
        future.transform(s: {_ in 1}, f:{_ in TestError.Failed2}).onFailure { error in
            XCTAssertTrue(TestError.Failed2 == error)
            expect.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    
    func testTransform2WithSucceedFuture() {
        let expect = self.expectationWithDescription("future should be completed")
        
        let future = Future.succeeded(0)
        
        future.transform { result -> Try<String> in
            switch result {
            case .Success(let value) where value == 0: return Try("OK")
            default: return Try(error: TestError.Failed)
            }
        }.map { value in
            XCTAssertEqual("OK", value)
            expect.fulfill()
        }.onFailure { error in
            XCTFail("unexpected error \(error)")
            expect.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    
    func testTransform2WithFailedFuture() {
        let expect = self.expectationWithDescription("future should be completed")
        
        let future = Future<Int>.failed(TestError.Failed)
        
        future.transform { result -> Try<String> in
            switch result {
            case .Success(let value) where value == 0: return Try("OK")
            default: return Try(error: TestError.Failed2)
            }
        }.map { value in
            XCTFail("unexpected success")
            expect.fulfill()
        }.onFailure { error in
            XCTAssertTrue(TestError.Failed2 == error)
            expect.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    
    func testTransformWith_WithSucceedFuture() {
        let expect = self.expectationWithDescription("future should be completed")
        
        let future = Future.succeeded(0)
        
        future.transformWith { result -> Future<String> in
            switch result {
            case .Success(let value) where value == 0: return Future.succeeded("OK")
            default: return Future.failed(TestError.Failed)
            }
            }.map { value in
                XCTAssertEqual("OK", value)
                expect.fulfill()
            }.onFailure { error in
                XCTFail("unexpected error \(error)")
                expect.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    
    func testTransformWith_WithFailedFuture() {
        let expect = self.expectationWithDescription("future should be completed")
        
        let future = Future<Int>.failed(TestError.Failed)
        
        future.transformWith { result -> Future<String> in
            switch result {
            case .Success(let value) where value == 0: return Future.succeeded("OK")
            default: return Future.failed(TestError.Failed2)
            }
            }.map { value in
                XCTFail("unexpected success")
                expect.fulfill()
            }.onFailure { error in
                XCTAssertTrue(TestError.Failed2 == error)
                expect.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    
    

}
