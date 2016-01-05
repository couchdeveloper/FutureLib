//
//  SequenceFutureTypeFoldTests.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import XCTest
import FutureLib



func task<T>(delay: Double, f: () throws -> T) -> Future<T> {
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


    // MARK: traverse

    func testTraverseInputAppliedToTaskCompletesWithArrayOfSuccessValues() {
        let expect1 = self.expectationWithDescription("future should be completed")
        let inputs = ["a", "b", "c", "d"]
        inputs.traverse { s in
            return task(0.1) { s.uppercaseString }
        }.onSuccess { value in
            XCTAssertEqual(["A", "B", "C", "D"], value)
            expect1.fulfill()
        }
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }


    func testTraverseInputAppliedToTaskFails() {
        let expect1 = self.expectationWithDescription("future should be completed")
        let inputs = ["a", "b", "cc", "d"]
        inputs.traverse { s in
            return task(0.01) {
                guard s.characters.count > 1 else {
                    throw TestError.Failed
                }
                s.uppercaseString
            }
        }.onFailure { error in
            XCTAssertTrue(TestError.Failed == error)
            expect1.fulfill()
        }
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testTraverseCanBeCancelled() {
        let expect1 = self.expectationWithDescription("future should be completed")
        let cr = CancellationRequest()
        let inputs = ["a", "b", "c", "d"]
        inputs.traverse(ct: cr.token) { s -> Future<String> in
            return task(2.0) {
                return s.uppercaseString
            }
        }.onFailure { error in
            XCTAssertTrue(CancellationError.Cancelled == error)
            expect1.fulfill()
        }
        schedule_after(0.1) {
            cr.cancel()
        }
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }


    func testTraverseCompletesWithErrorFromTask() {
        let expect1 = self.expectationWithDescription("future should be completed")
        let inputs = [0.05, 0.08, 0.01, 0.3]

        let task: (Double) -> Future<Double> = { d in
            return Promise.resolveAfter(d) {
                if d > 0.02 { return d }
                throw TestError.Failed

            }.future!
        }

        inputs.traverse() { d in task(d) }
        .onFailure { error in
            XCTAssertTrue(TestError.Failed == error, String(error))
            expect1.fulfill()
        }
        self.waitForExpectationsWithTimeout(2, handler: nil)
    }


    func testTraverseInputAppliedToTaskFails2() {
        let expect1 = self.expectationWithDescription("future should be completed")
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
            XCTAssertTrue(CancellationError.Cancelled == error, String(error))
            expect1.fulfill()
        }
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }



    func testTraverseWithTaskQueueExecutionContext1() {
        let expect1 = self.expectationWithDescription("future should be completed")
        let ec = TaskQueue(maxConcurrentTasks: 1)
        let inputs = ["a", "b", "c", "d"]

        // The tasks confirms that it is the only one executing concurrently:
        let sem = dispatch_semaphore_create(1)
        let task: (String) -> Future<String> = { s in
            return Promise<String>.resolveAfter(0.01, f: {
                let avail = dispatch_semaphore_wait(sem, DISPATCH_TIME_NOW) == 0
                XCTAssertTrue(avail)
                dispatch_semaphore_signal(sem)
                return s.uppercaseString
            }).future!
        }

        inputs.traverse(ec: ec) { s in
            return task(s)
        }.onSuccess { value in
            XCTAssertEqual(["A", "B", "C", "D"], value)
            expect1.fulfill()
        }
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }


    func testTraverseWithTaskQueueExecutionContext2() {
        let expect1 = self.expectationWithDescription("future should be completed")
        let ec = TaskQueue(maxConcurrentTasks: 2)
        let inputs = ["a", "b", "c", "d"]

        // The task confirms that there are only two executing concurrently:
        let sem = dispatch_semaphore_create(2)
        let task: (String) -> Future<String> = { s in
            return Promise<String>.resolveAfter(0.01, f: {
                let avail = dispatch_semaphore_wait(sem, DISPATCH_TIME_NOW) == 0
                XCTAssertTrue(avail)
                dispatch_semaphore_signal(sem)
                return s.uppercaseString
            }).future!
        }

        inputs.traverse(ec: ec) { s in
            return task(s)
        }.onSuccess { value in
            XCTAssertEqual(["A", "B", "C", "D"], value)
            expect1.fulfill()
        }
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }


    // MARK: fold


    func testFoldCallsCombineInOrder() {

        let expect1 = self.expectationWithDescription("future1 should be completed")

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
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }


    func testFoldWillContinueWhenAllFuturesHaveBeenCompleted1() {

        let expect1 = self.expectationWithDescription("future1 should be completed")

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
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testFoldWillContinueWhenNextinSequenceFails() {

        let expect1 = self.expectationWithDescription("future1 should be completed")

        let futures = [
            task(0.01) { "A"},
            task(0.07) { "B"},
            task(0.05) { throw TestError.Failed },
            task(0.20) { "D"}
        ]
        futures.fold(initial: ()) { _,_ -> Void in }.onFailure { error in
            XCTAssertTrue(futures[0].isSuccess)
            XCTAssertTrue(futures[1].isSuccess)
            XCTAssertTrue(futures[2].isFailure)
            XCTAssertFalse(futures[3].isCompleted)
            expect1.fulfill()
        }
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }


    func testFoldWillContinueWhenNextinSequenceFails2() {

        let expect1 = self.expectationWithDescription("future1 should be completed")

        let futures = [
            task(0.01) { "A"},
            task(0.07) { "B"},
            task(0.05) { throw TestError.Failed },
            task(0.03) { "D"}
        ]
        futures.fold(initial: ()) { _,_ -> Void in }.onFailure { error in
            XCTAssertTrue(futures[0].isSuccess)
            XCTAssertTrue(futures[1].isSuccess)
            XCTAssertTrue(futures[2].isFailure)
            XCTAssertTrue(futures[3].isSuccess)
            expect1.fulfill()
        }
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }




    // MARK: sequence


    func testSequenceMapsToArrayOfTs() {

        let expect1 = self.expectationWithDescription("future1 should be completed")

        let futures = [
            task(0.01) { "A"},
            task(0.07) { "B"},
            task(0.03) { "C"},
            task(0.05) { "D"}
        ]
        futures.sequence().onSuccess { s in
            XCTAssertEqual(["A", "B", "C", "D"], s)
            expect1.fulfill()
        }
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }



    // MARK: results

    func testResultsMapsToArrayOfResults() {

        let expect1 = self.expectationWithDescription("future1 should be completed")

        let futures = [
            task(0.01) { "A"},
            task(0.07) { "B"},
            task(0.03) { "C"},
            task(0.05) { "D"}
        ]
        typealias ResultT = Result<String>
        futures.results().map { results in
            return try results.map { try $0.value() }
        }.onSuccess { values in
            XCTAssertEqual(["A", "B", "C", "D"], values)
            expect1.fulfill()
        }
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }

}
