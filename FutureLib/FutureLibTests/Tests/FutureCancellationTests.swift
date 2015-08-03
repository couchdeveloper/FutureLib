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
        future.onComplete(cancellationToken: cancellationRequest1.token) { result -> () in
            expect2.fulfill()
        }
        future.onComplete(cancellationToken: cancellationRequest2.token) { result -> () in
            expect3.fulfill()
        }
        
        
        promise.fulfill("OK")
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    
    func testCancellation2() {
        let promise = Promise<String>()
        let future = promise.future!
        
        let cr1 = CancellationRequest()
        let cr2 = CancellationRequest()
        let expect1 = self.expectationWithDescription("continuation1 should be called")
        let expect2 = self.expectationWithDescription("continuation2 should be called")
        let expect3 = self.expectationWithDescription("continuation3 should be called")
        
        future.onComplete { result -> () in
            result.map { s -> () in
                expect1.fulfill()
                return ()
            }
        }
        
        future.onComplete(cancellationToken: cr1.token) { result -> () in
            result.map { s -> () in
                XCTFail("unexpected")
                return ()
            }
            expect2.fulfill()
        }
        
        future.onComplete(cancellationToken: cr2.token) { result -> () in
            result.map { s -> () in
                expect3.fulfill()
                return ()
            }
        }
        
        cr1.cancel()
        // Note: cancellation may be slower than the subsequent fulfill. Thus, get 
        // the cancellation handler some time to become effective:
        usleep(1000)
        promise.fulfill("OK")
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    
    
    func testCancellation3() {
        let promise = Promise<String>()
        let future = promise.future!
        
        let cr1 = CancellationRequest()
        let cr2 = CancellationRequest()
        let cr3 = CancellationRequest()
        
        let expect1 = self.expectationWithDescription("continuation1 should be called")
        let expect2 = self.expectationWithDescription("continuation2 should be called")
        let expect3 = self.expectationWithDescription("continuation3 should be called")
        
        future.onComplete(cancellationToken: cr1.token) { result -> () in
            result.map { s -> () in
                XCTFail("unexpected")
                return ()
            }
            expect1.fulfill()
        }
        future.onComplete(cancellationToken: cr2.token) { result -> () in
            result.map { s -> () in
                XCTFail("unexpected")
                return ()
            }
            expect2.fulfill()
        }
        future.onComplete(cancellationToken: cr3.token) { result -> () in
            result.map { s -> () in
                XCTFail("unexpected")
                return ()
            }
            expect3.fulfill()
        }
        
        cr1.cancel()
        cr2.cancel()
        cr3.cancel()
        for _ in 1..<10 {
            usleep(1000) // give the cancellation handlers a chance to be called
        }
        promise.fulfill("OK") // should have no effect
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    
    func testCancellation4() {
        let promise = Promise<String>()
        let future = promise.future!
        
        let cr = CancellationRequest()

        let expect1 = self.expectationWithDescription("continuation1 should be called")
        let expect2 = self.expectationWithDescription("continuation2 should be called")
        let expect3 = self.expectationWithDescription("continuation3 should be called")
        
        future.onComplete(cancellationToken: cr.token) { result -> () in
            result.map { s -> () in
                XCTFail("unexpected")
                return ()
            }
            expect1.fulfill()
        }
        future.onComplete(cancellationToken: cr.token) { result -> () in
            result.map { s -> () in
                XCTFail("unexpected")
                return ()
            }
            expect2.fulfill()
        }
        future.onComplete(cancellationToken: cr.token) { result -> () in
            result.map { s -> () in
                XCTFail("unexpected")
                return ()
            }
            expect3.fulfill()
        }
        
        cr.cancel()
        for _ in 1..<10 {
            usleep(1000) // give the cancellation handlers a chance to be called
        }
        promise.fulfill("OK")
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    
    func testCancellation5() {
        let promise = Promise<String>()
        let future = promise.future!
        
        let cr = CancellationRequest()
        let expect1 = self.expectationWithDescription("continuation1 should be called")
        let expect2 = self.expectationWithDescription("continuation2 should be called")
        let expect3 = self.expectationWithDescription("continuation3 should be called")
        let expect4 = self.expectationWithDescription("continuation3 should be called")
        
        future.onComplete(cancellationToken: cr.token) { result -> () in
            result.map { s -> () in
                XCTFail("unexpected")
                return ()
            }
            expect1.fulfill()
        }
        future.onComplete(cancellationToken: cr.token) { result -> () in
            result.map { s -> () in
                XCTFail("unexpected")
                return ()
            }
            expect2.fulfill()
        }
        future.onComplete(cancellationToken: cr.token) { result -> () in
            result.map { s -> () in
                XCTFail("unexpected")
                return ()
            }
            expect3.fulfill()
        }
        
        cr.cancel()
        for _ in 1..<10 {
            usleep(1000) // give the cancellation handlers a chance to be called
        }
        future.onComplete(cancellationToken: cr.token) { result -> () in
            result.map { s -> () in
                XCTFail("unexpected")
                return ()
            }
            expect4.fulfill()
        }
        promise.fulfill("OK")
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    
    
    
    
    func testBrokenPromise1() {
        var promise : Promise<String>? = Promise<String>()
        let future = promise!.future!
        
        let expect1 = self.expectationWithDescription("continuation1 should be called")
        
        future.onComplete { result in
            do {
                _ = try result.value()
                XCTFail("unexpected")
            }
            catch PromiseError.BrokenPromise {
                expect1.fulfill()
            }
            catch CancellationError.Cancelled  {
                XCTFail("unexpected")
            }
            catch  {
                XCTFail("unexpected")
            }
        }
        
        promise = nil
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    
    

}
