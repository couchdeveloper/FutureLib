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
        let expect = self.expectationWithDescription("future should be fulfilled")
        let maxConcurrentTasks: Int32 = 1
        let g = dispatch_group_create()
        var i: Int32 = 0
        let task: () -> Future<Void> = {
            XCTAssertTrue(OSAtomicIncrement32(&i) <= maxConcurrentTasks)
            return Promise<Void>.resolveAfter(0.1, f: {
                OSAtomicDecrement32(&i)
                dispatch_group_leave(g)
            }).future!
        }
        
        let queue = TaskQueue(maxConcurrentTasks: UInt(maxConcurrentTasks))
        for _ in 0...5 {
            dispatch_group_enter(g)
            queue.enqueue(task)
        }
        dispatch_group_notify(g, dispatch_get_main_queue()) {
            expect.fulfill()
        }
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testMaxConcurrentTaskEquals2() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        let maxConcurrentTasks: Int32 = 2
        let g = dispatch_group_create()
        var i: Int32 = 0
        let task: () -> Future<Void> = {
            XCTAssertTrue(OSAtomicIncrement32(&i) <= maxConcurrentTasks)
            return Promise<Void>.resolveAfter(0.1, f: {
                OSAtomicDecrement32(&i)
                dispatch_group_leave(g)
            }).future!
        }
        
        let queue = TaskQueue(maxConcurrentTasks: UInt(maxConcurrentTasks))
        for _ in 0...10 {
            dispatch_group_enter(g)
            queue.enqueue(task)
        }
        dispatch_group_notify(g, dispatch_get_main_queue()) {
            expect.fulfill()
        }
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testMaxConcurrentTaskEquals3() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        let maxConcurrentTasks: Int32 = 3
        let g = dispatch_group_create()
        var i: Int32 = 0
        let task: () -> Future<Void> = {
            XCTAssertTrue(OSAtomicIncrement32(&i) <= maxConcurrentTasks)
            return Promise<Void>.resolveAfter(0.1, f: {
                OSAtomicDecrement32(&i)
                dispatch_group_leave(g)
            }).future!
        }
        
        let queue = TaskQueue(maxConcurrentTasks: UInt(maxConcurrentTasks))
        for _ in 0...15 {
            dispatch_group_enter(g)
            queue.enqueue(task)
        }
        dispatch_group_notify(g, dispatch_get_main_queue()) {
            expect.fulfill()
        }
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testMaxConcurrentTaskEquals4() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        let maxConcurrentTasks: Int32 = 4
        let g = dispatch_group_create()
        var i: Int32 = 0
        let task: () -> Future<Void> = {
            XCTAssertTrue(OSAtomicIncrement32(&i) <= maxConcurrentTasks)
            return Promise<Void>.resolveAfter(0.1, f: {
                OSAtomicDecrement32(&i)
                dispatch_group_leave(g)
            }).future!
        }
        
        let queue = TaskQueue(maxConcurrentTasks: UInt(maxConcurrentTasks))
        for _ in 0...20 {
            dispatch_group_enter(g)
            queue.enqueue(task)
        }
        dispatch_group_notify(g, dispatch_get_main_queue()) {
            expect.fulfill()
        }
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }


}
