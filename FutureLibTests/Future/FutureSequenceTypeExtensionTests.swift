//
//  FutureSequenceTypeExtensionTests.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import XCTest
import FutureLib

class FutureSequenceTypeExtensionTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
    
// MARK: results()
    
    func testStaticFuncResults() {
        let futures = [
            Promise.resolveAfter(0.10) { 1 }.future!,
            Promise.resolveAfter(0.11) { 2 }.future!,
            Promise.resolveAfter(0.12) { 3 }.future!,
        ]
        let futureArray = FutureBaseType.results(sequence: futures)
        print(futureArray)
        futureArray.wait()
    }

//    // MARK: onComplete(on:cancellationToken:_)
//
//    func testSequenceOfFuturesShallInvokeContinuationWhenAllCompleted1() {
//        let expect1 = self.expectationWithDescription("continuation should be called")
//        [
//            Future<Int>.succeededAfter(0.01, value: 0),
//            Future<Int>.succeededAfter(0.02, value: 1),
//            Future<Int>.succeededAfter(0.03, value: 2)
//        ].onComplete { s -> () in
//            let values = s.map() { try! $0.value() }
//            print("\(values)")
//            expect1.fulfill()
//        }
//        waitForExpectationsWithTimeout(1.0, handler: nil)
//    }
//    
//    func testSequenceOfFuturesShallInvokeContinuationWhenAllCompleted2() {
//        let expect1 = self.expectationWithDescription("continuation should be called")
//        [
//            Future<Int>.succeededAfter(0.01, value: 0),
//            Future<Int>.failedAfter(0.02, error: TestError.Failed),
//            Future<Int>.succeededAfter(0.03, value: 2)
//        ].onComplete { s -> () in
//            print("\(s.map() { $0 })")
//            expect1.fulfill()
//        }
//        
//        waitForExpectationsWithTimeout(1.0, handler: nil)
//    }
//
//    
//    // MARK: forEach(on:cancellationToken:_)
//    
//    
//    func testSequenceOfFuturesShallInvokeCompletionForeachFuture() {
//        
//        let expect1 = self.expectationWithDescription("completions should be called")
//        
//        let futures = [
//            Future<Int>.succeededAfter(0.01, value: 0),
//            Future<Int>.succeededAfter(0.02, value: 1),
//            Future<Int>.succeededAfter(0.03, value: 2)
//        ]
//        futures.forEach { (index, result) -> () in
//            if index == futures.count-1 {
//                expect1.fulfill()
//            }
//        }
//        waitForExpectationsWithTimeout(1.0, handler: nil)
//    }
//    
//    func testSequenceOfFuturesShallInvokeCompletionForeachFutureInOrder() {
//        let ec = GCDAsyncExecutionContext(dispatch_queue_create("test.sync_queue", DISPATCH_QUEUE_SERIAL))
//        let expect1 = self.expectationWithDescription("completions should be called")
//        
//        let expected = [0,1,2,3,4,5]
//        var actual = [Int]()
//        
//        let futures = [
//            Future<Int>.succeededAfter(0.05, value: 0),
//            Future<Int>.succeededAfter(0.02, value: 1),
//            Future<Int>.succeededAfter(0.01, value: 2),
//            Future<Int>.succeededAfter(0.07, value: 3),
//            Future<Int>.succeededAfter(0.02, value: 4),
//            Future<Int>.succeededAfter(0.03, value: 5)
//        ]
//        futures.forEach(on: ec) { (index, result) -> () in
//            actual.append(index)
//            if index == futures.count-1 {
//                XCTAssertEqual(expected, actual)
//                expect1.fulfill()
//            }
//        }
//        waitForExpectationsWithTimeout(1.0, handler: nil)
//    }
//    
//    
//    func testSequenceOfFuturesShallInvokeCompletionForeachFutureInOrderWhenCancelled() {
//        let ec = GCDAsyncExecutionContext(dispatch_queue_create("test.sync_queue", DISPATCH_QUEUE_SERIAL))
//        let expect1 = self.expectationWithDescription("completions should be called")
//        
//        let expected = [0,1,2,3,4,5]
//        var actual = [Int]()
//        
//        let futures = [
//            Future<Int>.succeededAfter(0.5, value: 0),
//            Future<Int>.succeededAfter(0.2, value: 1),
//            Future<Int>.succeededAfter(0.1, value: 2),
//            Future<Int>.succeededAfter(0.7, value: 3),
//            Future<Int>.succeededAfter(0.2, value: 4),
//            Future<Int>.succeededAfter(0.3, value: 5)
//        ]
//        let cr = CancellationRequest()
//        futures.forEach(on: ec, cancellationToken: cr.token) { (index, result) -> () in
//            actual.append(index)
//            switch result {
//            case .Success: XCTFail("result should be .Failure")
//            default : break
//            }
//            if index == futures.count-1 {
//                XCTAssertEqual(expected, actual)
//                expect1.fulfill()
//            }
//        }
//        cr.cancel()
//        waitForExpectationsWithTimeout(1.0, handler: nil)
//    }
//    
//    
//    // MARK: map(on:cancellationToken:_)
//
//    func testMapReturnsFutureWithArrayOfMappedValues() {
//        let expect1 = self.expectationWithDescription("continuation should be called")
//        [
//            Future<Int>.succeededAfter(0.01, value: 0),
//            Future<Int>.succeededAfter(0.02, value: 1),
//            Future<Int>.succeededAfter(0.03, value: 2)
//        ].map { value -> Int in
//            return value
//        }.onComplete { result in
//            do {
//                let values = try result.value()
//                XCTAssertEqual([0,1,2], values)
//            }
//            catch let error {
//                XCTFail("\(error)")
//            }
//            expect1.fulfill()
//        }
//        waitForExpectationsWithTimeout(1.0, handler: nil)
//    }
//
//
//    func testMapReturnsFutureWithErrorWhenAFutureFailed() {
//        let expect1 = self.expectationWithDescription("continuation should be called")
//        [
//            Future<Int>.succeededAfter(0.01, value: 0),
//            Future<Int>.failedAfter(0.02, error: TestError.Failed),
//            Future<Int>.succeededAfter(0.03, value: 2)
//        ].map { value -> Int in
//            return value
//        }.onComplete { result in
//            do {
//                _ = try result.value()
//                XCTFail("unexpected")
//            }
//            catch let error {
//                XCTAssertTrue(error == TestError.Failed)
//            }
//            expect1.fulfill()
//        }
//        waitForExpectationsWithTimeout(1.0, handler: nil)
//    }
//    
//    func testMapReturnsFutureWithErrorWhenMapppingFunctionThrows() {
//        let expect1 = self.expectationWithDescription("continuation should be called")
//        [
//            Future<Int>.succeededAfter(0.01, value: 0),
//            Future<Int>.succeededAfter(0.02, value: 1),
//            Future<Int>.succeededAfter(0.03, value: 2)
//        ].map { value -> Int in
//            if value == 1 {
//                throw TestError.Failed
//            }
//            return value
//        }.onComplete { result in
//            do {
//                _ = try result.value()
//                XCTFail("unexpected")
//            }
//            catch let error {
//                XCTAssertTrue(error == TestError.Failed)
//            }
//            expect1.fulfill()
//        }
//        waitForExpectationsWithTimeout(1, handler: nil)
//    }
    
    
}
