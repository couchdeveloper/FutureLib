//
//  ResultTests.swift
//  Future
//
//  Created by Andreas Grosam on 24.09.14.
//  Copyright (c) 2014 Andreas Grosam. All rights reserved.
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
    
    
    func testExample1() {

        let r = Result<Int>(3)
        r.map {
            XCTAssert($0 == 3, "Failed")
        }
        r.map { print($0) }
    }
    
    func testExample2() {
        let s = "123.0e1"
        
        func stringToDouble(s:String) -> Result<Double> {
            let buffer = s.cStringUsingEncoding(NSUTF8StringEncoding);
            errno = 0
            var endptr: UnsafeMutablePointer<Int8> = nil
            let x = strtod(buffer!, &endptr)
            if UnsafeMutablePointer<Int8>(buffer!) == endptr {
                let userInfo = [NSLocalizedFailureReasonErrorKey: "no digits"]
                return Result<Double>(error: NSError(domain: "StringToDouble", code: -1, userInfo: userInfo))
            }
            else if errno != 0 {
                let errorString:String = String.fromCString(strerror(errno))!
                let userInfo = [NSLocalizedFailureReasonErrorKey: errorString]
                let error = NSError(domain: "StringToDouble", code: -1, userInfo: userInfo)
                return Result<Double>(error: error)
            }
            else  {
                return Result<Double>(x)
            }
        }
        
//        let r :Result<Double> = stringToDouble(s).map {
//            //XCTAssert($0 == 123, "Failed")
//            $0
//        }
        
        let r1 = Result<Double>(1.23)
        let r2 : Result<Double> = r1.map { $0 }
        r2.map() { print($0) }
        Result<Double>(1.23).map { $0 }.map { print("\($0)") }
    }
    
    
    
    func testThrowingInitFunction() {
        
        enum TestError : ErrorType {
            case Test
        }
        
        func funcThrows() throws -> Double {
            throw TestError.Test
        }
        
        let r = Result<Double>(){try funcThrows()}
        print(r)
        
        let e = TestError.Test
        print(e)
        
        r.map { $0 }.map { print("\($0)") }
    }
    
    
    func testResultWithErrorThrows() {
        
        let r = Result<Int>(error: NSError(domain: "Test", code: -1, userInfo: nil))
        
        do {
            _ = try r.value()
            XCTFail("expected exception")
        }
        catch let ex {
            let error = ex as NSError
            XCTAssert(error.code == -1)
            print("Error: \(error).")
        }
        
    }
    
    
    func testResultVoidDefaultCtorYieldsSucceeded() {
        let result = Result()
        XCTAssertTrue(result.isSuccess)
    }

    func testResultVoidDefaultCtorWithErrorYieldsFailed() {
        let result = Result<Void>(error: TestError.Failed)
        XCTAssertTrue(result.isFailure)
    }
    
    
//    func testEqualityOperator() {
//        let r1 = Result<Int>(3)
//        let r2 = Result<Int>(3)
//        XCTAssertTrue(r1 == r2)
//    }
    


}
