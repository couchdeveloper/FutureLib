//
//  FutureMiscCombinatorTests.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import XCTest
import FutureLib


/**
 Testd the combinators `zip` and `filter`
 */


class FutureMiscCombinatorTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }


    // MARK: zip

    func testZip1() {
        let expect = self.expectation(withDescription: "future should be completed")

        let f1 = Future.succeeded(0)
        let f2 = Future.succeeded("OK")

        f1.zip(f2).onSuccess { tuple in
            XCTAssertTrue(tuple.0 == 0 && tuple.1 == "OK")
            expect.fulfill()
        }

        self.waitForExpectations(withTimeout: 1, handler: nil)
    }


    func testZip2() {
        let expect = self.expectation(withDescription: "future should be completed")

        let f1 = Promise.resolveAfter(0.01) { 0 }.future!
        let f2 = Promise.resolveAfter(0.02) { "OK" }.future!

        f1.zip(f2).onSuccess { tuple in
            XCTAssertTrue(tuple.0 == 0 && tuple.1 == "OK")
            expect.fulfill()
        }

        self.waitForExpectations(withTimeout: 1, handler: nil)
    }


    func testZip3() {
        let expect = self.expectation(withDescription: "future should be completed")

        let f1 = Promise.resolveAfter(0.01) { 0 }.future!
        let f2 = Promise.resolveAfter(0.02) { throw TestError.failed }.future!

        f1.zip(f2).onFailure { error in
            XCTAssertTrue(TestError.failed == error)
            expect.fulfill()
        }

        self.waitForExpectations(withTimeout: 1, handler: nil)
    }


    func testZip4() {
        let expect = self.expectation(withDescription: "future should be completed")

        let f1 = Promise.resolveAfter(0.01) { throw TestError.failed }.future!
        let f2 = Promise.resolveAfter(0.02) { "OK" }.future!

        f1.zip(f2).onFailure { error in
            XCTAssertTrue(TestError.failed == error)
            expect.fulfill()
        }

        self.waitForExpectations(withTimeout: 1, handler: nil)
    }





    // MARK: filter

    func testFilter1() {
        let expect = self.expectation(withDescription: "future should be completed")

        let future = Future.succeeded(0)

        future.filter() { return $0 == 0 }
        .onSuccess { value in
            XCTAssertEqual(0, value)
            expect.fulfill()
        }

        self.waitForExpectations(withTimeout: 1, handler: nil)
    }


    func testFilter2() {
        let expect = self.expectation(withDescription: "future should be completed")

        let future = Future.succeeded(0)

        future.filter() { return $0 == 1 }
        .onFailure { error in
            XCTAssertTrue(FutureError.noSuchElement == error)
            expect.fulfill()
        }

        self.waitForExpectations(withTimeout: 1, handler: nil)
    }


    func testFilter3() {
        let expect = self.expectation(withDescription: "future should be completed")

        let future = Future.succeeded(0)

        future.filter() { _ in throw TestError.failed }
        .onFailure { error in
            XCTAssertTrue(TestError.failed == error)
            expect.fulfill()
        }

        self.waitForExpectations(withTimeout: 1, handler: nil)
    }

}



