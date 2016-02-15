//
//  TryTests.swift
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import XCTest
import FutureLib


class TryTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }


    // MARK: Create a Try

    func testResultVoidDefaultCtorYieldsSucceeded() {
        let result = Try()
        XCTAssertTrue(result.isSuccess)
        XCTAssertFalse(result.isFailure)
    }



    func testCreateResultWithSuccess() {
        let r1 = Try("OK")
        switch r1 {
        case .Success (let value):
            XCTAssertEqual("OK", value)
        case .Failure:
            XCTFail("unexpected failure")
        }
        XCTAssertTrue(r1.isSuccess)
        XCTAssertFalse(r1.isFailure)

        let r2 = Try(2)
        switch r2 {
        case .Success (let value):
            XCTAssertEqual(2, value)
        case .Failure:
            XCTFail("unexpected failure")
        }
        XCTAssertTrue(r2.isSuccess)
        XCTAssertFalse(r2.isFailure)
    }


    func testCreateResultWithFailure() {
        let r1 = Try<Int>(error: TestError.Failed)
        switch r1 {
        case .Success:
            XCTFail("unexpected success")
        case .Failure(let error):
            XCTAssertTrue(TestError.Failed == error)
        }
        XCTAssertFalse(r1.isSuccess)
        XCTAssertTrue(r1.isFailure)

    }


    func testCreateResultWithThrowingFunction() {
        let f: () throws -> Int = { return 0 }
        let r1 = Try<Int>(f)
        switch r1 {
        case .Success (let value):
            XCTAssertEqual(0, value)
        case .Failure:
            XCTFail("unexpected failure")
        }
    }

    func testCreateResultWithThrowingFunctionWhichThrows() {
        let f: () throws -> Int = { throw TestError.Failed }
        let r1 = Try<Int>(f)
        switch r1 {
        case .Success:
            XCTFail("unexpected success")
        case .Failure(let error):
            XCTAssertTrue(TestError.Failed == error)
        }
    }



    func testResultWithNSError() {
        let r = Try<Int>(error: NSError(domain: "Test", code: -1, userInfo: nil))

        switch r {
        case .Success:
            XCTFail("unexpected success")
        case .Failure(let error):
            switch error {
            case let err as NSError:
                XCTAssertEqual(-1, err.code)
                XCTAssertEqual("Test", err.domain)
            default:
                XCTFail("Unexpected error: \(error)")
            }
        }
    }



    // MARK: method map(f:) -> Try<U>

    func testSuccessfulResultMapsToNewResult() {
         let r = Try<Int>(3).map { value -> String in
            XCTAssertEqual(3, value)
            return "OK"
        }
        switch r {
        case .Success (let value):
            XCTAssertEqual("OK", value)
        case .Failure:
            XCTFail("unexpected failure")
        }
    }

    func testFailedResultMapsToSameResult() {
        let r0 = Try<Int>({ throw TestError.Failed })
        let r = r0.map { value -> String in
            XCTAssertEqual(3, value)
            return "OK"
        }
        switch r {
        case .Success:
            XCTFail("unexpected success")
        case .Failure(let error):
            XCTAssertTrue(TestError.Failed == error)
        }
    }


    func testSuccessfulResultWithTrowingMappingFunctionMapsToNewResult() {
        let r = Try<Int>(3).map { value -> String in
            XCTAssertEqual(3, value)
            throw TestError.Failed
        }
        switch r {
        case .Success:
            XCTFail("unexpected success")
        case .Failure(let error):
            XCTAssertTrue(TestError.Failed == error)
        }
    }


    // MARK: method flatMap(f:) -> Try<U>

    func testSuccessfulResultFlatMapsToNewResult() {
        let r = Try<Int>(3).flatMap { value -> Try<String> in
            XCTAssertEqual(3, value)
            return Try("OK")
        }
        switch r {
        case .Success (let value):
            XCTAssertEqual("OK", value)
        case .Failure:
            XCTFail("unexpected failure")
        }
    }

    func testFailedResultFlatMapsToSameResult() {
        let r0 = Try<Int>({ throw TestError.Failed })
        let r = r0.flatMap { value -> Try<String> in
            XCTAssertEqual(3, value)
            return Try("OK")
        }
        switch r {
        case .Success:
            XCTFail("unexpected success")
        case .Failure(let error):
            XCTAssertTrue(TestError.Failed == error)
        }
    }



    // MARK: get()



    func testValueForSuccessfulResultReturnsSuccessValue() {
        let r = Try<Int>(3)
        do {
            let value = try r.get()
            XCTAssertEqual(3, value)
        }
        catch {
            XCTFail("unexpected failure")
        }
    }

    func testValueForFailedResultReturnsErrorValue() {
        let r = Try<Int>({ throw TestError.Failed })
        do {
            _ = try r.get()
            XCTFail("unexpected success")
        }
        catch let error {
            XCTAssertTrue(TestError.Failed == error)
        }
    }

    // MARK: flatten()
    
    func testFlattenWithSuccess() {
        let r: Try<Try<Int>> = Try<Try<Int>>(Try<Int>(1))
        
        let r0 = r.flatten()
        switch r0 {
        case .Success(let value):
            XCTAssertEqual(1, value)
        case .Failure(let error):
            XCTFail("unexpected error: \(error)")
        }
    }
    
    func testFlattenWithFailure() {
        let r: Try<Try<Int>> = Try<Try<Int>>(error: TestError.Failed)
        
        let r0 = r.flatten()
        switch r0 {
        case .Success(let value):
            XCTFail("unexpected success: \(value)")
        case .Failure(let error):
            XCTAssertTrue(TestError.Failed == error)
        }
    }
    
    
    // MARK: recover()
    
    func testRecoverWhenSuccess() {
        let r = Try<Int>(0)
        
        let r0 = r.recover { (error) -> Int in
            return -1
        }
        switch r0 {
        case .Success(let value):
            XCTAssertEqual(0, value)
        case .Failure(let error):
            XCTFail("unexpected error: \(error)")
        }
    }
    
    func testRecoverWhenFailure() {
        let r = Try<Int>(error: TestError.Failed)
        
        let r0 = r.recover { error in
            return -1
        }
        switch r0 {
        case .Success(let value):
            XCTAssertEqual(-1, value)
        
        case .Failure(let error):
            XCTFail("unexpected error: \(error)")
        }
    }
    
    
    
    // MARK: recoverWith()
    
    func testRecoverWithWhenSuccess() {
        let r = Try<Int>(0)
        
        let r0 = r.recoverWith { error in
            return Try(1)
        }
        switch r0 {
        case .Success(let value):
            XCTAssertEqual(0, value)
        case .Failure(let error):
            XCTFail("unexpected error: \(error)")
        }
    }
    
    func testRecoverWithWhenFailure() {
        let r = Try<Int>(error: TestError.Failed)
        
        let r0 = r.recoverWith { error in
            return Try(-1)
        }
        switch r0 {
        case .Success(let value):
            XCTAssertEqual(-1, value)
            
        case .Failure(let error):
            XCTFail("unexpected error: \(error)")
        }
    }

    

//    func testEqualityOperator() {
//        let r1 = Try<Int>(3)
//        let r2 = Try<Int>(3)
//        XCTAssertTrue(r1 == r2)
//    }



}
