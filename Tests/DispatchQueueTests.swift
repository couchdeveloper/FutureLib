//
//  DispatchQueueTests.swift
//  FutureLib
//
//  Created by Andreas Grosam on 24/06/16.
//  Copyright © 2016 Andreas Grosam. All rights reserved.
//

import XCTest
import Dispatch


private class Dummy: CustomStringConvertible {
    let expect: XCTestExpectation
    let name: String
    init(name: String, expect: XCTestExpectation) {
        let eci = ExecutionContextInfo.current
        NSLog("on \"\(eci.queueName)\" [\(eci.threadId)]: Init Dummy: \(name)")
        self.name = name
        self.expect = expect
    }
    deinit {
        let eci = ExecutionContextInfo.current
        NSLog("on \"\(eci.queueName)\" [\(eci.threadId)]: Dealloc Dummy: \(self.name)")
        expect.fulfill()
    }
    
    var description: String {
        return "Dummy: \(self.name)"
    }
}


class DispatchQueueTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testCapturedVariableShouldDeinitialize1() {
        let expect1 = self.expectation(description: "captured variable should be deinitialized")
        func f() {
            let d1 = Dummy(name: "d1", expect: expect1)
            DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(10)) {
                print(d1) // captured object should deinitialize after executing.
            }
        }
        f()
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testDispatchQueueSerialCapturedVariableShouldDeinitializeWithAsync() {
        let queue = DispatchQueue(label: "com.me.test.test-queue")
        let expect1 = self.expectation(description: "captured variable should be deinitialized")
        func f() {
            let d1 = Dummy(name: "d1", expect: expect1) 
            queue.async {
                print(d1) // captured object should deinitialize after executing.
            }
        }
        f()
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testDispatchQueueSerialCapturedVariableShouldDeinitializeWithAsyncBarrier() {
        let queue = DispatchQueue(label: "com.me.test.test-queue")
        let expect1 = self.expectation(description: "captured variable should be deinitialized")
        func f() {
            let d1 = Dummy(name: "d1", expect: expect1) 
            queue.async(flags: .barrier) {
                print(d1) // captured object should deinitialize after executing.
            }
        }
        f()
        waitForExpectations(timeout: 1, handler: nil)
    }

    
    
    func testDispatchQueueConcurrentCapturedVariableShouldDeinitializeWithAsync() {
        let queue = DispatchQueue(label: "com.me.test.test-queue", attributes: .concurrent)
        let expect1 = self.expectation(description: "captured variable should be deinitialized")
        func f() {
            let d1 = Dummy(name: "d1", expect: expect1) 
            queue.async {
                print(d1) // captured object should deinitialize after executing.
            }
        }
        f()
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testDispatchQueueConcurrentCapturedVariableShouldDeinitializeWithAsyncBarrier() {
        let queue = DispatchQueue(label: "com.me.test.test-queue", attributes: .concurrent)
        let expect1 = self.expectation(description: "captured variable should be deinitialized")
        func f() {
            let d1 = Dummy(name: "d1", expect: expect1) 
            queue.async(flags: .barrier) {
                print(d1) // captured object should deinitialize after executing.
            }
        }
        f()
        waitForExpectations(timeout: 1, handler: nil)
    }
    
}
