//
//  ResultTests.swift
//  Future
//
//  Created by Andreas Grosam on 24.09.14.
//  Copyright (c) 2014 Andreas Grosam. All rights reserved.
//

import XCTest
import Future


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
        r.map(println)
    }

    func testExample2() {
        let s = "123.0e123456789"
        
        func stringToDouble(s:String) -> Result<Double> {
            let buffer = s.cStringUsingEncoding(NSUTF8StringEncoding);
            errno = 0
            var endptr:UnsafeMutablePointer<Int8> = nil
            let x = strtod(buffer!, &endptr)
            if UnsafePointer<Int8>(buffer!) == endptr {
                let userInfo = [NSLocalizedFailureReasonErrorKey: "no digits"]
                return Result<Double>(NSError(domain: "StringToDouble", code: -1, userInfo: userInfo))
            }
            else if errno != 0 {
                let errorString:String = String.fromCString(strerror(errno))!
                let userInfo = [NSLocalizedFailureReasonErrorKey: errorString]
                let error = NSError(domain: "StringToDouble", code: -1, userInfo: userInfo)
                return Result<Double>(error)
            }
            else  {
                return Result<Double>(x)
            }
        }
        
        stringToDouble(s).map {
            XCTAssert($0 == 123, "Failed")
            $0
        }.map(println)
    }
    

}
