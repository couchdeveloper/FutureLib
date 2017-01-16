//
//  FutureInternalTests.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import XCTest
import Dispatch
import Darwin

@testable import FutureLib


/**
A helper execution context which synchronously executes a given closure on the
_current_ execution context. This class is used to test private behavior of Future.
*/
struct SyncCurrent: ExecutionContext {

    internal func execute(f: @escaping ()->()) {
        f()
    }
}



//extension DispatchQueue: ExecutionContext {
//    public func execute(_ f: () -> ()) {
//        self.async(execute: f)
//    }
//}




class FutureInternalTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    
    func example(n: Int) {
        func t(_ i: Int) {
            //print("Start on \(Context.current())")
            let expect1 = self.expectation(description: "continuation ran")
            let expect2 = self.expectation(description: "last reference ran")
            let createQueue = DispatchQueue(label: "com.test.create-queue-\(i)")
            let registerQueue = DispatchQueue(label: "com.test.register-queue-\(i)")
            let completeQueue = DispatchQueue(label: "com.test.complete-queue-\(i)")
            let continuationQueue = DispatchQueue(label: "com.test.continuation-queue-\(i)")
            let otherQueue = DispatchQueue(label: "com.test.other-queue-\(i)")
            createQueue.async {
                let promise = Promise<Int>()   
                let future = promise.future!
                registerQueue.asyncAfter(deadline: .now() + Double(arc4random_uniform(2000))/10000.0) {
                    future.onComplete(ec: GCDAsyncExecutionContext(continuationQueue)) { value in 
                        //print("executing continuation with value: \(value) on \"\(Context.current())\"")
                        expect1.fulfill()                 
                    }
                }
                otherQueue.asyncAfter(deadline: .now() + Double(arc4random_uniform(2000))/10000.0) {
                    _ = future
                    expect2.fulfill()                 
                }
                completeQueue.asyncAfter(deadline: .now() + 0.2) {
                    assert(!Thread.isMainThread)
                    //print("Complete on \"\(Context.current())\"...") 
                    promise.fulfill(i)
                }
            }
        }
        (0..<n).forEach { i in 
            t(i)
        }
        
        self.waitForExpectations(timeout: 1, handler: nil)
    }
    
    func example2(n: Int) {
        func t(_ i: Int) {
            //print("Start on \(Context.current())")
            let expect1 = self.expectation(description: "continuation ran")
            let createQueue = DispatchQueue(label: "com.test.create-queue-\(i)")
            let completeQueue = DispatchQueue(label: "com.test.complete-queue-\(i)")
            let continuationQueue = DispatchQueue(label: "com.test.continuation-queue-\(i)")
            createQueue.async {
                let promise = Promise<Int>()   
                promise.future!.onComplete(ec: GCDAsyncExecutionContext(continuationQueue)) { value in 
                    //print("executing continuation with value: \(value) on \"\(Context.current())\"") 
                    expect1.fulfill()                 
                }
                completeQueue.asyncAfter(deadline: .now() + 0.2) {
                    assert(!Thread.isMainThread)
                    //print("Complete on \"\(Context.current())\"...") 
                    promise.fulfill(i)
                }
            }
        }
        (0..<n).forEach { i in 
            t(i)
        }
        
        self.waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testDataRaces() {
        // Run which Thread Sanitizer enabled!
        example2(n: 100)
    }
    
    
    //
    // Test if internal future methods are synchronized with the synchronization context.
    //

    func testFutureInternalsExecuteOnTheSynchronizationQueue1() {
        let expect = self.expectation(description: "future should be fulfilled")
        let promise = Promise<String>()
        let test:()->() = {            
            let future = promise.future!
            future.onComplete(ec: SyncCurrent()) { r -> () in
                XCTAssertTrue(future.sync.isSynchronized())
                expect.fulfill()
            }
        }
        test()
        promise.fulfill("OK")
        self.waitForExpectations(timeout: 1, handler: nil)
    }


    func testFutureInternalsExecuteOnTheSynchronizationQueue2() {
        let expect = self.expectation(description: "future should be fulfilled")
        let promise = Promise<String>()
        let cr = CancellationRequest()
        let test:()->() = {
            let future = promise.future!
            future.onComplete(ec: SyncCurrent(), ct: cr.token) { r -> () in
                XCTAssertTrue(future.sync.isSynchronized())
                expect.fulfill()
            }
        }
        test()
        cr.cancel()
        self.waitForExpectations(timeout: 1, handler: nil)
    }


    func testFutureInternalsExecuteOnTheSynchronizationQueue3() {
        let expect = self.expectation(description: "future should be fulfilled")
        let promise = Promise<String>()
        let cr = CancellationRequest()
        cr.cancel()
        let test:()->() = {
            let future = promise.future!
            future.onComplete(ec: SyncCurrent(), ct: cr.token) { r -> () in
                XCTAssertTrue(future.sync.isSynchronized())
                expect.fulfill()
            }
        }
        test()
        self.waitForExpectations(timeout: 1, handler: nil)
    }
    

}
