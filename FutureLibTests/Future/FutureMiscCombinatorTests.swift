//
//  FutureMiscCombinatorTests.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import XCTest
import FutureLib


/**
 Testd the combinators `zip`, `transform` and `filter`
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
        let expect = self.expectationWithDescription("future should be completed")

        let f1 = Future.succeeded(0)
        let f2 = Future.succeeded("OK")

        f1.zip(f2).onSuccess { tuple in
            XCTAssertTrue(tuple.0 == 0 && tuple.1 == "OK")
            expect.fulfill()
        }

        self.waitForExpectationsWithTimeout(1, handler: nil)
    }


    func testZip2() {
        let expect = self.expectationWithDescription("future should be completed")

        let f1 = Promise.resolveAfter(0.01) { 0 }.future!
        let f2 = Promise.resolveAfter(0.02) { "OK" }.future!

        f1.zip(f2).onSuccess { tuple in
            XCTAssertTrue(tuple.0 == 0 && tuple.1 == "OK")
            expect.fulfill()
        }

        self.waitForExpectationsWithTimeout(1, handler: nil)
    }


    func testZip3() {
        let expect = self.expectationWithDescription("future should be completed")

        let f1 = Promise.resolveAfter(0.01) { 0 }.future!
        let f2 = Promise.resolveAfter(0.02) { throw TestError.Failed }.future!

        f1.zip(f2).onFailure { error in
            XCTAssertTrue(TestError.Failed == error)
            expect.fulfill()
        }

        self.waitForExpectationsWithTimeout(1, handler: nil)
    }


    func testZip4() {
        let expect = self.expectationWithDescription("future should be completed")

        let f1 = Promise.resolveAfter(0.01) { throw TestError.Failed }.future!
        let f2 = Promise.resolveAfter(0.02) { "OK" }.future!

        f1.zip(f2).onFailure { error in
            XCTAssertTrue(TestError.Failed == error)
            expect.fulfill()
        }

        self.waitForExpectationsWithTimeout(1, handler: nil)
    }




    // MARK: transform

    func testTransform1() {
        let expect = self.expectationWithDescription("future should be completed")

        let future = Future.succeeded(0)

        future.transform(s: {_ in 1}, f:{_ in TestError.Failed2}).onSuccess { value in
            XCTAssertEqual(1, value)
            expect.fulfill()
        }

        self.waitForExpectationsWithTimeout(1, handler: nil)
    }


    func testTransform2() {
        let expect = self.expectationWithDescription("future should be completed")

        let future = Future<Int>.failed(TestError.Failed)

        future.transform(s: {_ in 1}, f:{_ in TestError.Failed2}).onFailure { error in
            XCTAssertTrue(TestError.Failed2 == error)
            expect.fulfill()
        }

        self.waitForExpectationsWithTimeout(1, handler: nil)
    }


    // MARK: filter

    func testFilter1() {
        let expect = self.expectationWithDescription("future should be completed")

        let future = Future.succeeded(0)

        future.filter() { return $0 == 0 }
        .onSuccess { value in
            XCTAssertEqual(0, value)
            expect.fulfill()
        }

        self.waitForExpectationsWithTimeout(1, handler: nil)
    }


    func testFilter2() {
        let expect = self.expectationWithDescription("future should be completed")

        let future = Future.succeeded(0)

        future.filter() { return $0 == 1 }
        .onFailure { error in
            XCTAssertTrue(FutureError.NoSuchElement == error)
            expect.fulfill()
        }

        self.waitForExpectationsWithTimeout(1, handler: nil)
    }


    func testFilter3() {
        let expect = self.expectationWithDescription("future should be completed")

        let future = Future.succeeded(0)

        future.filter() { _ in throw TestError.Failed }
        .onFailure { error in
            XCTAssertTrue(TestError.Failed == error)
            expect.fulfill()
        }

        self.waitForExpectationsWithTimeout(1, handler: nil)
    }

}



