//
//  TaskQueueTests.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import XCTest
import FutureLib
import Darwin

class TaskQueueTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testMaxConcurrentTaskEquals1() {
        let expect = self.expectation(withDescription: "future should be fulfilled")
        let maxConcurrentTasks: Int32 = 1
        let g = DispatchGroup()
        var i: Int32 = 0
        let task: () -> Future<Void> = {
            XCTAssertTrue(OSAtomicIncrement32(&i) <= maxConcurrentTasks)
            return Promise<Void>.resolveAfter(0.02, f: {
                OSAtomicDecrement32(&i)
                g.leave()
            }).future!
        }
        
        let queue = TaskQueue(maxConcurrentTasks: UInt(maxConcurrentTasks))
        for _ in 0...5 {
            g.enter()
            queue.enqueue(task)
        }
        g.notify(queue: DispatchQueue.main) {
            expect.fulfill()
        }
        self.waitForExpectations(withTimeout: 1, handler: nil)
    }

    func testMaxConcurrentTaskEquals2() {
        let expect = self.expectation(withDescription: "future should be fulfilled")
        let maxConcurrentTasks: Int32 = 2
        let g = DispatchGroup()
        var i: Int32 = 0
        let task: () -> Future<Void> = {
            XCTAssertTrue(OSAtomicIncrement32(&i) <= maxConcurrentTasks)
            return Promise<Void>.resolveAfter(0.02, f: {
                OSAtomicDecrement32(&i)
                g.leave()
            }).future!
        }
        
        let queue = TaskQueue(maxConcurrentTasks: UInt(maxConcurrentTasks))
        for _ in 0...10 {
            g.enter()
            queue.enqueue(task)
        }
        g.notify(queue: DispatchQueue.main) {
            expect.fulfill()
        }
        self.waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    func testMaxConcurrentTaskEquals3() {
        let expect = self.expectation(withDescription: "future should be fulfilled")
        let maxConcurrentTasks: Int32 = 3
        let g = DispatchGroup()
        var i: Int32 = 0
        let task: () -> Future<Void> = {
            XCTAssertTrue(OSAtomicIncrement32(&i) <= maxConcurrentTasks)
            return Promise<Void>.resolveAfter(0.02, f: {
                OSAtomicDecrement32(&i)
                g.leave()
            }).future!
        }
        
        let queue = TaskQueue(maxConcurrentTasks: UInt(maxConcurrentTasks))
        for _ in 0...15 {
            g.enter()
            queue.enqueue(task)
        }
        g.notify(queue: DispatchQueue.main) {
            expect.fulfill()
        }
        self.waitForExpectations(withTimeout: 1, handler: nil)
    }

    func testMaxConcurrentTaskEquals4() {
        let expect = self.expectation(withDescription: "future should be fulfilled")
        let maxConcurrentTasks: Int32 = 4
        let g = DispatchGroup()
        var i: Int32 = 0
        let task: () -> Future<Void> = {
            XCTAssertTrue(OSAtomicIncrement32(&i) <= maxConcurrentTasks)
            return Promise<Void>.resolveAfter(0.02, f: {
                OSAtomicDecrement32(&i)
                g.leave()
            }).future!
        }
        
        let queue = TaskQueue(maxConcurrentTasks: UInt(maxConcurrentTasks))
        for _ in 0...20 {
            g.enter()
            queue.enqueue(task)
        }
        g.notify(queue: DispatchQueue.main) {
            expect.fulfill()
        }
        self.waitForExpectations(withTimeout: 1, handler: nil)
    }


}
