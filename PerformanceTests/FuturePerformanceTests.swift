//
//  FuturePerformanceTests.swift
//  FutureTests
//
//  Created by Andreas Grosam on 27/06/15.
//
//

import XCTest
import FutureLib

private struct SyncEC: ExecutionContext {

    func execute(f: ()->()) {
        f()
    }

    func schedule<FT: FutureType>(task: () -> FT, start: FT -> ()) {
        start(task())
    }
}


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


    func testResult() {
        self.measureBlock() {
            for _ in 0..<100000 {
                let r = Try<Int>(1)
                let _ = r.map{
                    UInt($0)
                }
            }
        }
    }


    func testPerformanceCreateAndDestroy100000Futures() {
        self.measureBlock() {
            for _ in 0..<100000 {
                let promise = Promise<Int>()
                let future: Future<Int>? = promise.future!
                //future = nil
            }
        }
    }



    func testPerformanceSetupAndFire10000ContinuationsSerial1() {
        func f(i: Int, promise: Promise<Void>) {
            if i == 0 {
                promise.fulfill()
            }
            else {
                let p = Promise(value: 0)
                p.future!.onComplete { _ in
                    _ = f(i - 1, promise: promise)
                }
            }
        }

        self.measureBlock() {
            let sem = dispatch_semaphore_create(0)
            let promise = Promise<Void>()
            let i = 10000
            f(i, promise: promise)
            promise.future!.onComplete() { _ in
                dispatch_semaphore_signal(sem)
            }
            dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER)
        }
    }


    func testPerformanceSetupAndFire10000ContinuationsSerial2() {
        func f(i: Int, promise: Promise<Void>) {
            if i == 0 {
                promise.fulfill()
            }
            else {
                let p = Promise(value: 0)
                p.future!.onComplete(ec: GCDAsyncExecutionContext(), ct: CancellationTokenNone()) { _ in
                    _ = f(i - 1, promise: promise)
                }
            }
        }

        self.measureBlock() {
            let sem = dispatch_semaphore_create(0)
            let promise = Promise<Void>()
            let i = 10000
            f(i, promise: promise)
            promise.future!.onComplete() { _ in
                dispatch_semaphore_signal(sem)
            }
            dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER)
        }
    }


    func testPerformanceSetupAndFire10000ContinuationsSerial3() {
        func f(i: Int, on ec: ExecutionContext, promise: Promise<Void>) {
            if i == 0 {
                promise.fulfill()
            }
            else {
                let p = Promise(value: 0)
                p.future!.onComplete(ec: ec) { _ in
                    _ = f(i - 1, on: ec, promise: promise)
                }
            }
        }

        self.measureBlock() {
            let sem = dispatch_semaphore_create(0)
            let sync_queue = dispatch_queue_create("private sync queue", dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_DEFAULT, 0))
            let ec = GCDAsyncExecutionContext(sync_queue)
            let promise = Promise<Void>()
            let i = 10000
            f(i, on: ec, promise: promise)
            promise.future!.onComplete() { _ in
                dispatch_semaphore_signal(sem)
            }
            dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER)
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
                    let _ = future.map { i -> Void in
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
        measureMetrics(XCTestCase.defaultPerformanceMetrics(), automaticallyStartMeasuring: false) {
            let count = 10000
            let dg = dispatch_group_create()
            var a = [Promise<Int>]()
            a.reserveCapacity(count)

            self.startMeasuring()
            for _ in 0..<count {
                let p = Promise<Int>()
                a.append(p)
                let future = p.future!
                for _ in 0..<2 {
                    dispatch_group_enter(dg)
                    let _ = future.map { i -> Void in
                        dispatch_group_leave(dg)
                    }
                }
            }
            for (p) in a {
                p.fulfill(0)
            }
            dispatch_group_wait(dg, DISPATCH_TIME_FOREVER)

            self.stopMeasuring()
            // Cleanup before next invocation
        }
    }


    func testPerformanceSetup10000x2x1Continuations() {
        measureMetrics(XCTestCase.defaultPerformanceMetrics(), automaticallyStartMeasuring: false) {
            let count = 10000
            let dg = dispatch_group_create()
            var a = [Promise<Int>]()
            a.reserveCapacity(count)

            self.startMeasuring()
            for _ in 0..<count {
                let p = Promise<Int>()
                a.append(p)
                let future = p.future!
                for _ in 0..<2 {
                    dispatch_group_enter(dg)
                    let _ = future.map { i -> Void in
                        dispatch_group_leave(dg)
                    }
                }
            }
            self.stopMeasuring()

            // Cleanup before next invocation
            for (p) in a {
                p.fulfill(0)
            }
            dispatch_group_wait(dg, DISPATCH_TIME_FOREVER)

        }
    }

    func testPerformanceFullfillAndRunContinuations10000x2x1Continuations() {
        measureMetrics(XCTestCase.defaultPerformanceMetrics(), automaticallyStartMeasuring: false) {
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
                    let _ = future.map { i -> Void in
                        dispatch_group_leave(dg)
                    }
                }
            }

            self.startMeasuring()
            for (p) in a {
                p.fulfill(0)
            }
            dispatch_group_wait(dg, DISPATCH_TIME_FOREVER)

            self.stopMeasuring()
            // Cleanup before next invocation
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
                    let _ = future.map { i -> Void in
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
                    let _ = future.map { i -> Void in
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
                    let _ = future.map { i -> Int in
                        dispatch_group_leave(dg)
                        return i
                    }
                    .map { i -> Void in
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
                    let _ = future.map { i -> Int in
                        dispatch_group_leave(dg)
                        return i
                    }.map { i -> Int in
                        dispatch_group_leave(dg)
                        return i
                    }.map { i -> Void in
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
                    let _ = future.map { i -> Int in
                        dispatch_group_leave(dg)
                        return i
                    }.map { i -> Int in
                        dispatch_group_leave(dg)
                        return i
                    }.map { i -> Int in
                        dispatch_group_leave(dg)
                        return i
                    }.map { i -> Void in
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
                    let _ = future.map { i -> Int in
                        dispatch_group_leave(dg)
                        return i
                    }.map { i -> Int in
                        dispatch_group_leave(dg)
                        return i
                    }.map { i -> Int in
                        dispatch_group_leave(dg)
                        return i
                    }.map { i -> Int in
                        dispatch_group_leave(dg)
                        return i
                    }.map { i -> Int in
                        dispatch_group_leave(dg)
                        return i
                    }.map { i -> Int in
                        dispatch_group_leave(dg)
                        return i
                    }.map { i -> Int in
                        dispatch_group_leave(dg)
                        return i
                    }.map { i -> Void in
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



    func testPerformanceSetup10000xmap() {
        measureMetrics(XCTestCase.defaultPerformanceMetrics(), automaticallyStartMeasuring: false) {
            let count = 10000
            var a = [Promise<Int>]()
            a.reserveCapacity(count)

            for _ in 0..<count {
                let p = Promise<Int>()
                a.append(p)
            }
            self.startMeasuring()
            for i in 0..<count {
                for _ in 0..<1 {
                    let _ = a[i].future!.map { _ in
                        return 0
                    }
                }
            }
            self.stopMeasuring()
        }
    }

    func testPerformanceSetup10000xflatMap() {
        measureMetrics(XCTestCase.defaultPerformanceMetrics(), automaticallyStartMeasuring: false) {
            let count = 10000
            var a = [Promise<Int>]()
            a.reserveCapacity(count)

            for _ in 0..<count {
                let p = Promise<Int>()
                a.append(p)
            }
            let future = Future.succeeded(0)
            self.startMeasuring()
            for i in 0..<count {
                for _ in 0..<1 {
                    let _ = a[i].future!.flatMap { _ in
                        return future
                    }
                }
            }
            self.stopMeasuring()
        }
    }


    func test1000Zip1() {
        measureMetrics(XCTestCase.defaultPerformanceMetrics(), automaticallyStartMeasuring: false) {
            let count = 10000
            let f1 = Future<Int>.succeeded(0)
            let f2 = Future<Int>.succeeded(1)
            let dg = dispatch_group_create()
            for _ in 0..<count {
                dispatch_group_enter(dg)
            }
            self.startMeasuring()
            for _ in 0..<count {
                f1.zip(f2).onComplete { _ in
                    dispatch_group_leave(dg)
                }
            }
            dispatch_group_wait(dg, DISPATCH_TIME_FOREVER)
            self.stopMeasuring()
        }
    }
    
    
    func testBenchmark() {
        self.measureBlock() {
            var fut: Future<Int> = Future.succeeded(0)
            let numberOfFutureCompositions = 1000
            for i in 0..<numberOfFutureCompositions {
                let futBegin = Future<Int>.apply { 1 } 
                let futEnd: Future<Int> = futBegin.flatMap { e0 in
                    
                    let futIn0 = Future.succeeded(i).flatMap { e1 in
                        Future<Int>.apply {i}.flatMap { e2 in
                            //Log.Info("=1=")
                            return Future.succeeded(e1 + e2)
                        }
                    }
                    //Log.Info("futIn0: \(futIn0)")
                    let futIn1 = Future<Int>.apply {i}.flatMap { e1 in
                        Future.succeeded(i).flatMap { e2 -> Future<Int> in
                            //Log.Info("=2=")
                            return Future<Int>.apply {e1 + e2}
                        }
                    }
                    //Log.Info("futIn1: \(futIn1)")
                    return futIn0.flatMap { e1 in
                        //Log.Info("=+1=")
                        return futIn1.flatMap { e2 -> Future<Int> in
                            //Log.Info("=+2=")
                            return Future.succeeded(e0 + e1 + e2)
                        }
                    }
                }
                
                fut = fut.flatMap { _ in 
                    futEnd 
                }
            }
            fut.wait()
        }
    }

}
