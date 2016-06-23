//
//  CancellationOperatorsTests.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import XCTest
@testable import FutureLib

class CancellationOperatorsTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testOred2CancellationToken1() {
        autoreleasepool {
            let expect = self.expectation(withDescription: "handler shoulde be called")
            let cr1 = CancellationRequest()
            let cr2 = CancellationRequest()
            let ct = cr1.token || cr2.token
            _ = ct.onCancel {
                expect.fulfill()
            }
            cr1.cancel()
            self.waitForExpectations(withTimeout: 1, handler: nil)
            XCTAssertTrue(ct.isCancellationRequested)
            usleep(100_000)
        }
    }


    func testOred2CancellationToken2() {
        autoreleasepool {
            let expect = self.expectation(withDescription: "handler shoulde be called")
            let cr1 = CancellationRequest()
            let cr2 = CancellationRequest()
            let ct = cr1.token || cr2.token
            _ = ct.onCancel {
                expect.fulfill()
            }
            cr2.cancel()
            self.waitForExpectations(withTimeout: 1, handler: nil)
            XCTAssertTrue(ct.isCancellationRequested)
            usleep(100_000)
        }
    }

    func testOred3CancellationToken1() {
        autoreleasepool {
            let expect = self.expectation(withDescription: "handler shoulde be called")
            let cr1 = CancellationRequest()
            let cr2 = CancellationRequest()
            let cr3 = CancellationRequest()
            let ct = cr1.token || cr2.token || cr3.token
            _ = ct.onCancel {
                expect.fulfill()
            }
            cr1.cancel()
            self.waitForExpectations(withTimeout: 1, handler: nil)
            XCTAssertTrue(ct.isCancellationRequested)
            usleep(100_000)
        }
    }


    func testOred3CancellationToken2() {
        autoreleasepool {
            let expect = self.expectation(withDescription: "handler shoulde be called")
            let cr1 = CancellationRequest()
            let cr2 = CancellationRequest()
            let cr3 = CancellationRequest()
            let ct = cr1.token || cr2.token || cr3.token
            _ = ct.onCancel {
                expect.fulfill()
            }
            cr2.cancel()
            self.waitForExpectations(withTimeout: 1, handler: nil)
            XCTAssertTrue(ct.isCancellationRequested)
            usleep(100_000)
        }
    }


    func testOred3CancellationToken3() {
        autoreleasepool {
            let queue = DispatchQueue(label: "cancel-queue")
            let expect = self.expectation(withDescription: "handler shoulde be called")
            let cr1 = CancellationRequest()
            let cr2 = CancellationRequest()
            let cr3 = CancellationRequest()
            
            let ct = cr1.token || cr2.token || cr3.token
            _ = ct.onCancel(on: GCDAsyncExecutionContext(queue)) {
                expect.fulfill()
            }
            cr3.cancel()
            self.waitForExpectations(withTimeout: 10000, handler: nil)
            XCTAssertTrue(ct.isCancellationRequested)
        }
        print("*** autoreleas pool")
        sleep(1)
    }


    func testAnded2CancellationToken1() {
        autoreleasepool {
            let cr1 = CancellationRequest()
            let cr2 = CancellationRequest()
            let ct = cr1.token && cr2.token
            cr1.cancel()
            _ = ct.onCancel {
                XCTFail("unexpected")
            }
            usleep(100_000)
            XCTAssertFalse(ct.isCancellationRequested)
        }
    }
    

    func testAnded2CancellationToken2() {
        autoreleasepool {
            let cr1 = CancellationRequest()
            let cr2 = CancellationRequest()
            let ct = cr1.token && cr2.token
            cr2.cancel()
            _ = ct.onCancel {
                XCTFail("unexpected")
            }
            usleep(100_000)
            XCTAssertFalse(ct.isCancellationRequested)
        }
    }

    func testAnded2CancellationToken12() {
        autoreleasepool {
            let expect = self.expectation(withDescription: "handler shoulde be called")
            let cr1 = CancellationRequest()
            let cr2 = CancellationRequest()
            let ct = cr1.token && cr2.token
            _ = ct.onCancel {
                expect.fulfill()
            }
            cr1.cancel()
            cr2.cancel()
            self.waitForExpectations(withTimeout: 1, handler: nil)
            XCTAssertTrue(ct.isCancellationRequested)
        }
    }




    func testAnded3CancellationToken1() {
        autoreleasepool {
            let cr1 = CancellationRequest()
            let cr2 = CancellationRequest()
            let cr3 = CancellationRequest()
            let ct = cr1.token && cr2.token && cr3.token
            cr1.cancel()
            _ = ct.onCancel {
                XCTFail("unexpected")
            }
            usleep(100_000)
            XCTAssertFalse(ct.isCancellationRequested)
        }
    }

    func testAnded3CancellationToken2() {
        autoreleasepool {
            let cr1 = CancellationRequest()
            let cr2 = CancellationRequest()
            let cr3 = CancellationRequest()
            let ct = cr1.token && cr2.token && cr3.token
            cr2.cancel()
            _ = ct.onCancel {
                XCTFail("unexpected")
            }
            usleep(100_000)
            XCTAssertFalse(ct.isCancellationRequested)
        }
    }

    func testAnded3CancellationToken3() {
        autoreleasepool {
            let cr1 = CancellationRequest()
            let cr2 = CancellationRequest()
            let cr3 = CancellationRequest()
            let ct = cr1.token && cr2.token && cr3.token
            cr3.cancel()
            _ = ct.onCancel {
                XCTFail("unexpected")
            }
            usleep(100_000)
            XCTAssertFalse(ct.isCancellationRequested)
        }
    }

    func testAnded3CancellationToken123() {
        autoreleasepool {
            let expect = self.expectation(withDescription: "handler shoulde be called")
            let cr1 = CancellationRequest()
            let cr2 = CancellationRequest()
            let cr3 = CancellationRequest()
            let ct = cr1.token && cr2.token && cr3.token
            _ = ct.onCancel {
                expect.fulfill()
            }
            cr1.cancel()
            cr2.cancel()
            cr3.cancel()
            self.waitForExpectations(withTimeout: 1, handler: nil)
            XCTAssertTrue(ct.isCancellationRequested)
        }
    }


}
