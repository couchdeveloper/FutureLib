//
//  FutureTypeTests.swift
//  FutureLib
//
//  Created by Andreas Grosam on 24/02/16.
//  Copyright © 2016 Andreas Grosam. All rights reserved.
//

import XCTest
import FutureLib

class FutureTypeTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    // MARK: result()
    
    
    func testResultWithSucceededFuture() {
        let future = Future.succeeded(1)
        XCTAssertNotNil(future.result)
        if let result = future.result {
            switch result {
            case .Success(let value):
                XCTAssertEqual(1, value)
            case .Failure(let error):
                XCTFail("unexpected error: \(error)")
            }
        }
    }

    func testResultWithFailedFuture() {
        let future: Future<Int> = Future.failed(TestError.Failed)
        
        XCTAssertNotNil(future.result)
        if let result = future.result {
            switch result {
            case .Success(let value):
                XCTFail("unexpected success: \(value)")
            case .Failure(let error):
                XCTAssertTrue(TestError.Failed == error)
            }
        }
    }
    
    func testResultWithPendingFutureGettingSucceeded() {
        let future = Promise.resolveAfter(0.1) { 1 }.future!
        XCTAssertNil(future.result)
        future.wait()
        if let result = future.result {
            switch result {
            case .Success(let value):
                XCTAssertEqual(1, value)
            case .Failure(let error):
                XCTFail("unexpected error: \(error)")
            }
        } else {
            XCTFail()
        }
    }


    func testResultWithPendingFutureGettingFailed() {
        let future = Promise<Int>.resolveAfter(0.1) { throw TestError.Failed }.future!
        XCTAssertNil(future.result)
        future.wait()
        if let result = future.result {
            switch result {
            case .Success(let value):
                XCTFail("unexpected success: \(value)")
            case .Failure(let error):
                XCTAssertTrue(TestError.Failed == error)
            }
        } else {
            XCTFail()
        }
    }
    
    
    

    // MARK: get()
    
    func testGetWithSucceededFuture() {
        let future = Future.succeeded(1)
        do {
            let value = try future.get()
            XCTAssertEqual(1, value)
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }
    
    
    func testGetWithFailedFuture() {
        let future: Future<Int> = Future.failed(TestError.Failed)
        do {
            let value = try future.get()
            XCTFail("unexpected success: \(value)")
        } catch {
            XCTAssertTrue(TestError.Failed == error)
        }
    }
    
    
    func testGetWithPendingFutureGettingSucceeded() {
        let future = Promise.resolveAfter(0.1) { 1 }.future!
        do {
            let value = try future.get()
            XCTAssertEqual(1, value)
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }
    
    func testGetWithPendingFutureGettingFailed() {
        let future = Promise<Int>.resolveAfter(0.1) { throw TestError.Failed }.future!
        do {
            let value = try future.get()
            XCTFail("unexpected success: \(value)")
        } catch {
            XCTAssertTrue(TestError.Failed == error)
        }
    }
    
    
    

}
