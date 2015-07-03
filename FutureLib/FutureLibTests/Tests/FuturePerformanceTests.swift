//
//  FuturePerformanceTests.swift
//  FutureTests
//
//  Created by Andreas Grosam on 27/06/15.
//
//

import XCTest
import FutureLib


class FuturePerformanceTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        #if !NDEBUG
            XCTFail("Performance tests should be run in Release configuration.")
        #endif
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }


    func testPerformanceCreateAndDestroy100000Futures() {
        self.measureBlock() {
            for _ in 0..<100000 {
                let promise = Promise<Int>()
                var future : Future<Int>? = promise.future!
                future = nil
            }
        }
    }
    
    
    
    
    func testPerformanceSetupAndFire10000x1x1Continuations() {
        self.measureBlock() {
            let count = 10000
            let dg = dispatch_group_create()
            var a = [Promise<Int>]()
            a.reserveCapacity(count)
            for _ in 0..<count {
                let p = Promise<Int>()
                a.append(p)
                let future = p.future!
                for _ in 0..<1 {
                    dispatch_group_enter(dg)
                    future.then { i -> Void in
                        dispatch_group_leave(dg)
                    }
                }
            }
            for (p) in a {
                p.fulfill(0)
            }
            dispatch_group_wait(dg, DISPATCH_TIME_FOREVER)
        }
    }
    
    
    func testPerformanceSetupAndFire10000x2x1Continuations() {
        self.measureBlock() {
            let count = 10000
            let dg = dispatch_group_create()
            var a = [Promise<Int>]()
            a.reserveCapacity(count)
            for _ in 0..<count {
                let p = Promise<Int>()
                a.append(p)
                let future = p.future!
                for _ in 0..<2 {
                    dispatch_group_enter(dg)
                    future.then { i -> Void in
                        dispatch_group_leave(dg)
                    }
                }
            }
            for (p) in a {
                p.fulfill(0)
            }
            dispatch_group_wait(dg, DISPATCH_TIME_FOREVER)
        }
    }
    
    
    func testPerformanceSetupAndFire10000x4x1Continuations() {
        self.measureBlock() {
            let count = 10000
            let dg = dispatch_group_create()
            var a = [Promise<Int>]()
            a.reserveCapacity(count)
            for _ in 0..<count {
                let p = Promise<Int>()
                a.append(p)
                let future = p.future!
                for _ in 0..<4 {
                    dispatch_group_enter(dg)
                    future.then { i -> Void in
                        dispatch_group_leave(dg)
                    }
                }
            }
            for (p) in a {
                p.fulfill(0)
            }
            dispatch_group_wait(dg, DISPATCH_TIME_FOREVER)
        }
    }
    
    
    func testPerformanceSetupAndFire10000x8x1Continuations() {
        self.measureBlock() {
            let count = 10000
            let dg = dispatch_group_create()
            var a = [Promise<Int>]()
            a.reserveCapacity(count)
            for _ in 0..<count {
                let p = Promise<Int>()
                a.append(p)
                let future = p.future!
                for _ in 0..<8 {
                    dispatch_group_enter(dg)
                    future.then { i -> Void in
                        dispatch_group_leave(dg)
                    }
                }
            }
            for (p) in a {
                p.fulfill(0)
            }
            dispatch_group_wait(dg, DISPATCH_TIME_FOREVER)
        }
    }
    
    func testPerformanceSetupAndFire10000x1x2Continuations() {
        self.measureBlock() {
            let count = 10000
            let dg = dispatch_group_create()
            var a = [Promise<Int>]()
            a.reserveCapacity(count)
            for _ in 0..<count {
                let p = Promise<Int>()
                a.append(p)
                let future = p.future!
                for _ in 0..<1 {
                    dispatch_group_enter(dg)
                    dispatch_group_enter(dg)
                    future.then { i -> Int in
                        dispatch_group_leave(dg)
                        return i
                    }
                    .then { i -> Void in
                        dispatch_group_leave(dg)
                    }
                }
            }
            for (p) in a {
                p.fulfill(0)
            }
            dispatch_group_wait(dg, DISPATCH_TIME_FOREVER)
        }
    }
    
    func testPerformanceSetupAndFire10000x1x3Continuations() {
        self.measureBlock() {
            let count = 10000
            let dg = dispatch_group_create()
            var a = [Promise<Int>]()
            a.reserveCapacity(count)
            for _ in 0..<count {
                let p = Promise<Int>()
                a.append(p)
                let future = p.future!
                for _ in 0..<1 {
                    dispatch_group_enter(dg)
                    dispatch_group_enter(dg)
                    dispatch_group_enter(dg)
                    future.then { i -> Int in
                        dispatch_group_leave(dg)
                        return i
                    }.then { i -> Int in
                        dispatch_group_leave(dg)
                        return i
                    }.then { i -> Void in
                        dispatch_group_leave(dg)
                    }
                }
            }
            for (p) in a {
                p.fulfill(0)
            }
            dispatch_group_wait(dg, DISPATCH_TIME_FOREVER)
        }
    }
    
        
    func testPerformanceSetupAndFire10000x1x4Continuations() {
        self.measureBlock() {
            let count = 10000
            let dg = dispatch_group_create()
            var a = [Promise<Int>]()
            a.reserveCapacity(count)
            for _ in 0..<count {
                let p = Promise<Int>()
                a.append(p)
                let future = p.future!
                for _ in 0..<1 {
                    dispatch_group_enter(dg)
                    dispatch_group_enter(dg)
                    dispatch_group_enter(dg)
                    dispatch_group_enter(dg)
                    future.then { i -> Int in
                        dispatch_group_leave(dg)
                        return i
                    }.then { i -> Int in
                        dispatch_group_leave(dg)
                        return i
                    }.then { i -> Int in
                        dispatch_group_leave(dg)
                        return i
                    }.then { i -> Void in
                        dispatch_group_leave(dg)
                    }
                }
            }
            for (p) in a {
                p.fulfill(0)
            }
            dispatch_group_wait(dg, DISPATCH_TIME_FOREVER)
        }
    }
    

    func testPerformanceSetupAndFire10000x1x8Continuations() {
        self.measureBlock() {
            let count = 10000
            let dg = dispatch_group_create()
            var a = [Promise<Int>]()
            a.reserveCapacity(count)
            for _ in 0..<count {
                let p = Promise<Int>()
                a.append(p)
                let future = p.future!
                for _ in 0..<1 {
                    dispatch_group_enter(dg)
                    dispatch_group_enter(dg)
                    dispatch_group_enter(dg)
                    dispatch_group_enter(dg)
                    dispatch_group_enter(dg)
                    dispatch_group_enter(dg)
                    dispatch_group_enter(dg)
                    dispatch_group_enter(dg)
                    future.then { i -> Int in
                        dispatch_group_leave(dg)
                        return i
                    }.then { i -> Int in
                        dispatch_group_leave(dg)
                        return i
                    }.then { i -> Int in
                        dispatch_group_leave(dg)
                        return i
                    }.then { i -> Int in
                        dispatch_group_leave(dg)
                        return i
                    }.then { i -> Int in
                        dispatch_group_leave(dg)
                        return i
                    }.then { i -> Int in
                        dispatch_group_leave(dg)
                        return i
                    }.then { i -> Int in
                        dispatch_group_leave(dg)
                        return i
                    }.then { i -> Void in
                        dispatch_group_leave(dg)
                    }
                }
            }
            for (p) in a {
                p.fulfill(0)
            }
            dispatch_group_wait(dg, DISPATCH_TIME_FOREVER)
        }
    }
    
    
    
}
