//
//  FutureBaseTests.swift
//  FutureLib
//
//  Created by Andreas Grosam on 19/09/15.
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import XCTest
import FutureLib


class FutureBaseTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testExample1a() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        let test:()->() = {
            let promise = Promise<String>()
            let future: FutureBaseType = promise.future!
            promise.fulfill("OK")
            let ec = GCDAsyncExecutionContext()
            future.onCompleteFuture(on: ec) { f in
                expect.fulfill()
            }
            
        }
        test()
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }

    
    
    
    func testExample1b() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        let test:()->() = {
            let promise = Promise<String>()
            let future = promise.future!
            promise.fulfill("OK")
            
            let ec = GCDAsyncExecutionContext()
            future.onCompleteFuture(on: ec) { f in
                expect.fulfill()
            }
            
        }
        test()
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
}
