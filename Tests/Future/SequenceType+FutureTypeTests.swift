//
//  SequenceFutureTypeFoldTests.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import XCTest
import FutureLib
import Darwin



func task<T>(_ delay: Double, f: @escaping () throws -> T) -> Future<T> {
    return Promise<T>.resolveAfter(delay, f: f).future!
}




class SequenceTypeFutureTypeTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    
    // MARK: find
    
    func testFind() {
        let expect1 = self.expectation(description: "future should be completed")
        let futures = [
            Promise.resolveAfter(0.10) {1}.future!,
            Promise.resolveAfter(0.12) {2}.future!,
            Promise.resolveAfter(0.08) {3}.future!,
            Promise.resolveAfter(0.01) {4}.future!,
            Promise.resolveAfter(0.02) {5}.future!
        ]
        
        futures.find { $0 == 3 }.map { value in
            XCTAssertNotNil(value)
            XCTAssertEqual(3, value!)
            expect1.fulfill()
        }.onFailure { error in
            XCTFail("unexpected error: \(error)")
            expect1.fulfill()
        }
        self.waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testFindWithCancellation() {
        let expect1 = self.expectation(description: "future should be completed")
        func t() {
            let futures = [
                Promise.resolveAfter(1.10) {1}.future!,
                Promise.resolveAfter(1.12) {2}.future!,
                Promise.resolveAfter(1.08) {3}.future!,
                Promise.resolveAfter(1.01) {4}.future!,
                Promise.resolveAfter(1.02) {5}.future!
            ]
            let cr = CancellationRequest()
            schedule_after(0.5) {
                cr.cancel()
            }
            futures.find(ct: cr.token) { $0 == 3 }.map { value in
                XCTFail("unexpected success: \(value)")
                expect1.fulfill()
                }.onFailure { error in
                    XCTAssertTrue(error is CancellationError)
                    expect1.fulfill()
            }
        }
        t()
        self.waitForExpectations(timeout: 1, handler: nil)
    }
    

    
    
    // Mark: firstCompleted
    
    func testFirstCompleted() {
        let expect1 = self.expectation(description: "future should be completed")
        func t() {
            let futures = [
                Promise<Int>.resolveAfter(0.30) {Log.Info("1"); return 1}.future!,
                Promise<Int>.resolveAfter(0.40) {Log.Info("3"); return 3}.future!,
                Promise<Int>.resolveAfter(0.20) {Log.Info("3"); return 3}.future!,
                Promise<Int>.resolveAfter(0.30) {Log.Info("4"); return 4}.future!,
                Promise<Int>.resolveAfter(0.40) {Log.Info("5"); return 5}.future!,
                Promise<Int>.resolveAfter(0.50) {Log.Info("6"); return 6}.future!,
                Promise<Int>.resolveAfter(0.60) {Log.Info("7"); return 7}.future!,
                Promise<Int>.resolveAfter(0.70) {Log.Info("8"); return 8}.future!,
                Promise<Int>.resolveAfter(0.80) {Log.Info("9"); return 9}.future!,
                Promise<Int>.resolveAfter(0.20) {Log.Info("10"); return 10}.future!,
                Promise<Int>.resolveAfter(0.30) {Log.Info("11"); return 11}.future!,
                Promise<Int>.resolveAfter(0.40) {Log.Info("12"); return 12}.future!,
                Promise<Int>.resolveAfter(0.01) {Log.Info("13"); return 13}.future!,
                Promise<Int>.resolveAfter(0.50) {Log.Info("14"); return 14}.future!
            ]
            let cr = CancellationRequest()
            futures.firstCompleted(cr.token).map { value in
                XCTAssertNotNil(value)
                XCTAssertEqual(13, value)
                cr.cancel()
                expect1.fulfill()
            }.onFailure { error in
                XCTFail("unexpected error: \(error)")
                expect1.fulfill()
            }
        }
        t()        
        self.waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testFirstCompletedWithCancellation() {
        let expect1 = self.expectation(description: "future should be completed")
        let cr = CancellationRequest()
        schedule_after(0.1) {
            cr.cancel()
        }
        func t() {
            let futures = [
                Promise<Int>.resolveAfter(1.30) {Log.Info("1"); return 1}.future!,
                Promise<Int>.resolveAfter(1.40) {Log.Info("3"); return 3}.future!,
                Promise<Int>.resolveAfter(1.20) {Log.Info("3"); return 3}.future!,
                Promise<Int>.resolveAfter(1.30) {Log.Info("4"); return 4}.future!,
                Promise<Int>.resolveAfter(1.40) {Log.Info("5"); return 5}.future!,
                Promise<Int>.resolveAfter(1.50) {Log.Info("6"); return 6}.future!,
                Promise<Int>.resolveAfter(1.60) {Log.Info("7"); return 7}.future!,
                Promise<Int>.resolveAfter(1.70) {Log.Info("8"); return 8}.future!,
                Promise<Int>.resolveAfter(1.80) {Log.Info("9"); return 9}.future!,
                Promise<Int>.resolveAfter(1.20) {Log.Info("10"); return 10}.future!,
                Promise<Int>.resolveAfter(1.30) {Log.Info("11"); return 11}.future!,
                Promise<Int>.resolveAfter(1.40) {Log.Info("12"); return 12}.future!,
                Promise<Int>.resolveAfter(1.01) {Log.Info("13"); return 13}.future!,
                Promise<Int>.resolveAfter(1.50) {Log.Info("14"); return 14}.future!
            ]
            futures.firstCompleted(cr.token).map { value in
                XCTFail("unexpected success: \(value)")
                expect1.fulfill()
            }.onFailure { error in
                XCTAssertTrue(error is CancellationError)
                expect1.fulfill()
            }
        }
        t()
        self.waitForExpectations(timeout: 1, handler: nil)
    }


    // MARK: traverse

    func testTraverseInputAppliedToTaskCompletesWithArrayOfSuccessValues() {
        let expect1 = self.expectation(description: "future should be completed")
        let inputs = ["a", "b", "c", "d"]
        inputs.traverse { s in
            return task(0.1) { s.uppercased() }
        }.onSuccess { value in
            XCTAssertEqual(["A", "B", "C", "D"], value)
            expect1.fulfill()
        }
        self.waitForExpectations(timeout: 1, handler: nil)
    }


    func testTraverseInputAppliedToTaskFails() {
        let expect1 = self.expectation(description: "future should be completed")
        let inputs = ["a", "b", "cc", "d"]
        let future: Future<[String]> = inputs.traverse { s in
            return task(0.01) {
                guard s.characters.count > 1 else {
                    throw TestError.failed
                }
                return s.uppercased()
            }
        }
        future.onFailure { error in
            XCTAssertTrue(TestError.failed == error)
            expect1.fulfill()
        }
        self.waitForExpectations(timeout: 1, handler: nil)
    }

    func testTraverseCanBeCancelled() {
        let expect1 = self.expectation(description: "future should be completed")
        let cr = CancellationRequest()
        let inputs = ["a", "b", "c", "d"]
        inputs.traverse(ct: cr.token) { s -> Future<String> in
            return task(2.0) {
                return s.uppercased()
            }
        }.onFailure { error in
            XCTAssertTrue(error is CancellationError)
            expect1.fulfill()
        }
        schedule_after(0.1) {
            cr.cancel()
        }
        self.waitForExpectations(timeout: 1, handler: nil)
    }


    func testTraverseCompletesWithErrorFromTask() {
        let expect1 = self.expectation(description: "future should be completed")
        let inputs = [0.05, 0.08, 0.01, 0.3]

        let task: (Double) -> Future<Double> = { d in
            return Promise.resolveAfter(d) {
                if d > 0.02 { return d }
                throw TestError.failed

            }.future!
        }

        inputs.traverse() { d in task(d) }
        .onFailure { error in
            XCTAssertTrue(TestError.failed == error, String(describing: error))
            expect1.fulfill()
        }
        self.waitForExpectations(timeout: 2, handler: nil)
    }


    func testTraverseInputAppliedToTaskFails2() {
        let expect1 = self.expectation(description: "future should be completed")
        let inputs = [1.1, 1.5, 0.01, 3.0]

        // Utilize a cancellation token to cancel all pending tasks when one
        // task fails:
        let cr = CancellationRequest()
        let task: (Double) -> Future<Double> = { d in
            return Promise.resolveAfter(d) { d }.future!
                .filter { $0 >= 1.0 }
                .recover { error in
                    cr.cancel()
                    throw error
                }
        }

        inputs.traverse(ct: cr.token) { d in task(d) }
        .onFailure { error in
            XCTAssertTrue(error is CancellationError, String(describing: error))
            expect1.fulfill()
        }
        self.waitForExpectations(timeout: 1, handler: nil)
    }

    
    func testTraverseWithTaskQueueExecutionContextWith1MaxConcurrentTask() {
        let expect1 = self.expectation(description: "future should be completed")
        let maxConcurrentTasks: Int32 = 1
        let ec = TaskQueue(maxConcurrentTasks: UInt(maxConcurrentTasks))
        let inputs = ["a", "b", "c", "d", "e"]
        var i: Int32 = 0
        // The tasks confirms that only maxConcurrentTasks executing concurrently:
        let task: (String) -> Future<String> = { s in
            XCTAssertTrue(OSAtomicIncrement32(&i) <= maxConcurrentTasks)
            return Promise<String>.resolveAfter(0.02, f: {
                OSAtomicDecrement32(&i)
                return s.uppercased()
            }).future!
        }

        inputs.traverse(ec: ec) { s in
            return task(s)
        }.onSuccess { value in
            XCTAssertEqual(["A", "B", "C", "D", "E"], value)
            expect1.fulfill()
        }
        self.waitForExpectations(timeout: 1, handler: nil)
    }


    func testTraverseWithTaskQueueExecutionContextWith2MaxConcurrentTask() {
        let expect1 = self.expectation(description: "future should be completed")
        let maxConcurrentTasks: Int32 = 2
        let ec = TaskQueue(maxConcurrentTasks: UInt(maxConcurrentTasks))
        let inputs = ["a", "b", "c", "d", "e"]
        var i: Int32 = 0
        // The tasks confirms that only maxConcurrentTasks executing concurrently:
        let task: (String) -> Future<String> = { s in
            XCTAssertTrue(OSAtomicIncrement32(&i) <= maxConcurrentTasks)
            return Promise<String>.resolveAfter(0.02, f: {
                OSAtomicDecrement32(&i)
                return s.uppercased()
            }).future!
        }
        
        inputs.traverse(ec: ec) { s in
            return task(s)
            }.onSuccess { value in
                XCTAssertEqual(["A", "B", "C", "D", "E"], value)
                expect1.fulfill()
        }
        self.waitForExpectations(timeout: 1, handler: nil)
    }


    // MARK: fold


    func testFoldCallsCombineInOrder() {

        let expect1 = self.expectation(description: "future1 should be completed")

        let futures = [
            task(0.01) { "A"},
            task(0.07) { "B"},
            task(0.03) { "C"},
            task(0.05) { "D"}
        ]
        futures.fold(initial: "") { (c,e) in  c + e }.onSuccess { s in
            XCTAssertEqual("ABCD", s)
            expect1.fulfill()
        }
        self.waitForExpectations(timeout: 1, handler: nil)
    }


    func testFoldWillContinueWhenAllFuturesHaveBeenCompleted1() {

        let expect1 = self.expectation(description: "future1 should be completed")

        let futures = [
            task(0.01) { "A"},
            task(0.07) { "B"},
            task(0.03) { "C"},
            task(0.05) { "D"}
        ]
        futures.fold(initial: ()) { _,_ -> Void in }.onSuccess {
            futures.forEach {
                XCTAssertTrue($0.isSuccess)
            }
            expect1.fulfill()
        }
        self.waitForExpectations(timeout: 1, handler: nil)
    }

    func testFoldWillContinueWhenNextinSequenceFails() {

        let expect1 = self.expectation(description: "future1 should be completed")

        let futures: [Future<String>] = [
            task(0.01) { "A" },
            task(0.07) { "B" },
            task(0.05) { throw TestError.failed },
            task(0.20) { "D" }
        ]
        futures.fold(initial: "") { (a, b) in 
            a + b
        }.map { value in
            value
        }
        .onFailure { error in
            XCTAssertTrue(futures[0].isSuccess)
            XCTAssertTrue(futures[1].isSuccess)
            XCTAssertTrue(futures[2].isFailure)
            XCTAssertFalse(futures[3].isCompleted)
            expect1.fulfill()
        }
        self.waitForExpectations(timeout: 1, handler: nil)
    }


    func testFoldWillContinueWhenNextinSequenceFails2() {

        let expect1 = self.expectation(description: "future1 should be completed")

        let futures: [Future<String>] = [
            task(0.01) { "A" },
            task(0.07) { "B" },
            task(0.05) { throw TestError.failed },
            task(0.03) { "D" }
        ]
        futures.fold(initial: "") { (a, b) in
            a + b
        }.map { value in
            value
        }
        .onFailure { error in
            XCTAssertTrue(futures[0].isSuccess)
            XCTAssertTrue(futures[1].isSuccess)
            XCTAssertTrue(futures[2].isFailure)
            XCTAssertTrue(futures[3].isSuccess)
            expect1.fulfill()
        }
        self.waitForExpectations(timeout: 1, handler: nil)
    }




    // MARK: sequence


    func testSequenceMapsToArrayOfTs() {

        let expect1 = self.expectation(description: "future1 should be completed")

        let futures: [Future<String>] = [
            task(0.01) { "A" },
            task(0.07) { "B" },
            task(0.03) { "C" },
            task(0.05) { "D" }
        ]
        futures.sequence().onSuccess { s in
            XCTAssertEqual(["A", "B", "C", "D"], s)
            expect1.fulfill()
        }
        self.waitForExpectations(timeout: 1, handler: nil)
    }



    // MARK: results

    func testResultsMapsToArrayOfResults() {

        let expect1 = self.expectation(description: "future1 should be completed")

        let futures: [Future<String>] = [
            task(0.01) { "A" },
            task(0.07) { "B" },
            task(0.03) { "C" },
            task(0.05) { "D" }
        ]
        typealias ResultT = Try<String>
        futures.results().map { results in
            return try results.map { try $0.get() }
        }.onSuccess { values in
            XCTAssertEqual(["A", "B", "C", "D"], values)
            expect1.fulfill()
        }
        self.waitForExpectations(timeout: 1, handler: nil)
    }

}
