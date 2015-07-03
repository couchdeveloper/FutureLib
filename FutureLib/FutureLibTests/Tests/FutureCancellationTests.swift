//
//  FutureCancellationTests.swift
//  FutureTests
//
//  Created by Andreas Grosam on 27/06/15.
//
//

import XCTest
import FutureLib

class FutureCancellationTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testCancellation1() {
        let promise = Promise<String>()
        let future = promise.future!
        
        let cancellationRequest1 = CancellationRequest()
        let cancellationRequest2 = CancellationRequest()
        let expect1 = self.expectationWithDescription("continuation1 should be called")
        let expect2 = self.expectationWithDescription("continuation2 should be called")
        let expect3 = self.expectationWithDescription("continuation3 should be called")
        future.onComplete { result -> () in
            expect1.fulfill()
        }
        future.onComplete(cancellationRequest1.token) { result -> () in
            expect2.fulfill()
        }
        future.onComplete(cancellationRequest2.token) { result -> () in
            expect3.fulfill()
        }
        
        
        promise.fulfill("OK")
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    
    func testCancellation2() {
        let promise = Promise<String>()
        let future = promise.future!
        
        let cancellationRequest1 = CancellationRequest()
        let cancellationRequest2 = CancellationRequest()
        let expect1 = self.expectationWithDescription("continuation1 should be called")
        let expect2 = self.expectationWithDescription("continuation2 should be called")
        future.onComplete { result -> () in
            expect1.fulfill()
        }
        future.onComplete(cancellationRequest1.token) { result -> () in
            XCTFail("unexpected")
        }
        future.onComplete(cancellationRequest2.token) { result -> () in
            expect2.fulfill()
        }
        
        cancellationRequest1.cancel()
        promise.fulfill("OK")
        waitForExpectationsWithTimeout(1, handler: nil)
        usleep(1000) // give the unexpected handler a chance to be called (if any)
    }
    
    
    
    func testCancellation3() {
        let promise = Promise<String>()
        let future = promise.future!
        
        let cancellationRequest1 = CancellationRequest()
        let cancellationRequest2 = CancellationRequest()
        let cancellationRequest3 = CancellationRequest()
        future.onComplete(cancellationRequest1.token) { result -> () in
            XCTFail("unexpected")
        }
        future.onComplete(cancellationRequest2.token) { result -> () in
            XCTFail("unexpected")
        }
        future.onComplete(cancellationRequest3.token) { result -> () in
            XCTFail("unexpected")
        }
        
        cancellationRequest1.cancel()
        cancellationRequest2.cancel()
        cancellationRequest3.cancel()
        for _ in 1..<10 {
            usleep(1000) // give the cancellation handlers a chance to be called
        }
        promise.fulfill("OK")
        for _ in 1..<10 {
            usleep(1000) // give the unexpected handlers a chance to be called (if any)
        }
    }
    
    
    func testCancellation4() {
        let promise = Promise<String>()
        let future = promise.future!
        
        let cancellationRequest = CancellationRequest()
        
        future.onComplete(cancellationRequest.token) { result -> () in
            XCTFail("unexpected")
        }
        future.onComplete(cancellationRequest.token) { result -> () in
            XCTFail("unexpected")
        }
        future.onComplete(cancellationRequest.token) { result -> () in
            XCTFail("unexpected")
        }
        
        cancellationRequest.cancel()
        for _ in 1..<10 {
            usleep(1000) // give the cancellation handlers a chance to be called
        }
        promise.fulfill("OK")
        for _ in 1..<10 {
            usleep(1000) // give the unexpected handlers a chance to be called (if any)
        }
    }
    
    
    func testCancellation5() {
        let promise = Promise<String>()
        let future = promise.future!
        
        let cancellationRequest = CancellationRequest()
        
        future.onComplete(cancellationRequest.token) { result -> () in
            XCTFail("unexpected")
        }
        future.onComplete(cancellationRequest.token) { result -> () in
            XCTFail("unexpected")
        }
        future.onComplete(cancellationRequest.token) { result -> () in
            XCTFail("unexpected")
        }
        
        cancellationRequest.cancel()
        for _ in 1..<10 {
            usleep(1000) // give the cancellation handlers a chance to be called
        }
        future.onComplete(cancellationRequest.token) { result -> () in
            XCTFail("unexpected")
        }
        promise.fulfill("OK")
        for _ in 1..<10 {
            usleep(1000) // give the unexpected handlers a chance to be called (if any)
        }
    }
    
    
    
    
    

}
