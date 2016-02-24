//
//  FutureLifetimeTests.swift
//  FutureTests
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import XCTest
import FutureLib



class Dummy {
    let _expect: XCTestExpectation
    init(_ expect: XCTestExpectation) {
        _expect = expect
    }
    deinit {
        _expect.fulfill()
    }
}




/// Initialize and configure the Logger
internal var Log: Logger  = {
    var target = ConsoleEventTarget()
    target.writeOptions = .Sync
    return Logger(category: "FutureLibTests", verbosity: Logger.Severity.Trace, targets: [target])
}()



class Foo<T> {
    typealias ArrayClosure = ([T])->()
}

class FutureLifetimeTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    
    
    //    // Livetime
    
    func testFutureShouldDeallocateIfThereAreNoObservers() {
        let promise = Promise<Int>()
        weak var weakRef: Future<Int>?
        func t() {
            let future = promise.future
            weakRef = future
        }
        t()
        XCTAssertNil(weakRef)
    }
    
    func testFutureShouldDeallocateIfThereAreNoObservers2() {
        let cr = CancellationRequest()
        let ct = cr.token
        let promise = Promise<Int>()
        let expect1 = self.expectationWithDescription("cancellation handler should be unregistered")
        
        dispatch_async(dispatch_get_global_queue(0, 0)) {
            let future = promise.future!
            let d1 = Dummy(expect1)
            future.onSuccess(ct: ct) { i -> () in
                XCTFail("unexpected")
                print(d1)
            }
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (Int64)(100 * NSEC_PER_MSEC)),dispatch_get_global_queue(0,0)) {
            cr.cancel()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testFutureShouldDeallocateIfThereAreNoObservers3() {
        let cr = CancellationRequest()
        let ct = cr.token
        let promise = Promise<Int>()
        let expect1 = self.expectationWithDescription("cancellation handler should be unregistered")
        let expect2 = self.expectationWithDescription("cancellation handler should be unregistered")
        
        dispatch_async(dispatch_get_global_queue(0,0)) {
            let future = promise.future!
            let d1 = Dummy(expect1)
            let d2 = Dummy(expect2)
            
            future.onSuccess(ct: ct) { i -> () in
                XCTFail("unexpected")
                print(d1)
            }
            future.onSuccess(ct: ct) { i -> () in
                XCTFail("unexpected")
                print(d2)
            }
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (Int64)(10 * NSEC_PER_MSEC)),dispatch_get_global_queue(0,0)) {
            cr.cancel()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testFutureShouldDeallocateIfThereAreNoObservers4() {
        let cr = CancellationRequest()
        let ct = cr.token
        let promise = Promise<Int>()
        let expect1 = self.expectationWithDescription("cancellation handler should be unregistered")
        let expect2 = self.expectationWithDescription("cancellation handler should be unregistered")
        let expect3 = self.expectationWithDescription("cancellation handler should be unregistered")
        
        dispatch_async(dispatch_get_global_queue(0,0)) {
            let future = promise.future!
            let d1 = Dummy(expect1)
            let d2 = Dummy(expect2)
            
            future.onSuccess(ct: ct) { i -> () in
                XCTFail("unexpected")
                print(d1)
            }
            future.onSuccess(ct: ct) { i -> () in
                XCTFail("unexpected")
                print(d2)
            }
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (Int64)(10 * NSEC_PER_MSEC)),dispatch_get_global_queue(0,0)) {
                cr.cancel()
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (Int64)(10 * NSEC_PER_MSEC)),dispatch_get_global_queue(0,0)) {
                    let d3 = Dummy(expect3)
                    future.onSuccess(ct: cr.token) { i -> () in
                        XCTFail("unexpected")
                        print(d3)
                    }
                }
            };
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    
    
    func testFutureShouldNotDeallocateIfThereIsOneObserver() {
        weak var weakRef: Future<Int>?
        let promise = Promise<Int>()
        let sem = dispatch_semaphore_create(0)
        func t() {
            let future = promise.future!
            future.onSuccess { value -> () in
                dispatch_semaphore_signal(sem)
            }
            weakRef = future
        }
        t()
        XCTAssertNotNil(weakRef)
        promise.fulfill(0)
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER)
        let future = weakRef
        XCTAssertNil(future)
    }
    
    func testFutureShouldCompleteWithBrokenPromiseIfPromiseDeallocatesPrematurely() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)) {
            let promise = Promise<String>()
            promise.future!.onFailure { error in
                if case PromiseError.BrokenPromise = error where error is PromiseError {
                } else {
                    XCTFail("Invalid kind of error: \(String(reflecting: error)))")
                }
                expect.fulfill()
            }
            let delay = dispatch_time(DISPATCH_TIME_NOW, Int64(0.05 * Double(NSEC_PER_SEC)))
            dispatch_after(delay, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)) {
                promise
            }
        }
        waitForExpectationsWithTimeout(0.4, handler: nil)
    }
    
    
    
    func testPromiseChainShouldNotDeallocatePrematurely() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        let delay = dispatch_time(DISPATCH_TIME_NOW, Int64(0.2 * Double(NSEC_PER_SEC)))
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)) {
            let promise = Promise<String>()
            let future = promise.future!
            future.map { str -> String in
                usleep(1000)
                return "1"
            }
            .map { str in
                "2"
            }
            .onSuccess { str in
                expect.fulfill()
            }
            
            dispatch_after(delay, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)) {
                promise.fulfill("OK")
            }
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    

}
