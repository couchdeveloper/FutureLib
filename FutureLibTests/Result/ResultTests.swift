//
//  ResultTests.swift
//  Future
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import XCTest
import FutureLib


class ResultTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
    // MARK: Create a Result
    
    func testResultVoidDefaultCtorYieldsSucceeded() {
        let result = Result()
        XCTAssertTrue(result.isSuccess)
        XCTAssertFalse(result.isFailure)
    }
    
    
    
    func testCreateResultWithSuccess() {
        let r1 = Result("OK")
        switch r1 {
        case .Success (let value):
            XCTAssertEqual("OK", value)
        case .Failure:
            XCTFail("unexpected failure")
        }
        XCTAssertTrue(r1.isSuccess)
        XCTAssertFalse(r1.isFailure)
        
        let r2 = Result(2)
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
        let r1 = Result<Int>(error: TestError.Failed)
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
        let r1 = Result<Int>(f)
        switch r1 {
        case .Success (let value):
            XCTAssertEqual(0, value)
        case .Failure:
            XCTFail("unexpected failure")
        }
    }
    
    func testCreateResultWithThrowingFunctionWhichThrows() {
        let f: () throws -> Int = { throw TestError.Failed }
        let r1 = Result<Int>(f)
        switch r1 {
        case .Success:
            XCTFail("unexpected success")
        case .Failure(let error):
            XCTAssertTrue(TestError.Failed == error)
        }
    }
    
    
    
    func testResultWithNSError() {
        let r = Result<Int>(error: NSError(domain: "Test", code: -1, userInfo: nil))
        
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
    
    
    
    // MARK: method map(f:) -> Result<U>
    
    func testSuccessfulResultMapsToNewResult() {
         let r = Result<Int>(3).map { value -> String in
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
        let r0 = Result<Int>({ throw TestError.Failed })
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
        let r = Result<Int>(3).map { value -> String in
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
    
    
    // MARK: method flatMap(f:) -> Result<U>
    
    func testSuccessfulResultFlatMapsToNewResult() {
        let r = Result<Int>(3).flatMap { value -> Result<String> in
            XCTAssertEqual(3, value)
            return Result("OK")
        }
        switch r {
        case .Success (let value):
            XCTAssertEqual("OK", value)
        case .Failure:
            XCTFail("unexpected failure")
        }
    }
    
    func testFailedResultFlatMapsToSameResult() {
        let r0 = Result<Int>({ throw TestError.Failed })
        let r = r0.flatMap { value -> Result<String> in
            XCTAssertEqual(3, value)
            return Result("OK")
        }
        switch r {
        case .Success:
            XCTFail("unexpected success")
        case .Failure(let error):
            XCTAssertTrue(TestError.Failed == error)
        }
    }
    
    
    
    // MARK: value()
    
    
    
    func testValueForSuccessfulResultReturnsSuccessValue() {
        let r = Result<Int>(3)
        do {
            let value = try r.value()
            XCTAssertEqual(3, value)
        }
        catch {
            XCTFail("unexpected failure")
        }
    }

    func testValueForFailedResultReturnsErrorValue() {
        let r = Result<Int>({ throw TestError.Failed })
        do {
            _ = try r.value()
            XCTFail("unexpected success")
        }
        catch let error {
            XCTAssertTrue(TestError.Failed == error)
        }
    }
    
    
//    func testEqualityOperator() {
//        let r1 = Result<Int>(3)
//        let r2 = Result<Int>(3)
//        XCTAssertTrue(r1 == r2)
//    }
    


}
