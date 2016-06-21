//
//  ContinuationRegistryTests.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import XCTest
@testable import FutureLib

class ClosureRegistryTests: XCTestCase {


    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testDefaultCtorYieldsEmpty1() {
        let registry = ClosureRegistry<String>()
        XCTAssertEqual(0, registry.count)

        if case .empty = registry {
        }
        else {
            XCTFail("registry should equal .Empty")
        }
    }

    func testDefaultCtorYieldsEmpty2() {
        let registry = ClosureRegistry<Void>()
        XCTAssertEqual(0, registry.count)

        if case .empty = registry {
        }
        else {
            XCTFail("registry should equal .Empty")
        }
    }



    func testAddingFirstHandlerYieldsSingle1() {
        var registry = ClosureRegistry<String>()

        _ = registry.register({ s in
            print(s)
        })

        XCTAssertEqual(1, registry.count)

        if case .single = registry {
        }
        else {
            XCTFail("registry should equal .Single")
        }
    }

    func testAddingFirstHandlerYieldsSingle2() {
        var registry = ClosureRegistry<Void>()

        _ = registry.register({ s in
            print(s)
        })

        XCTAssertEqual(1, registry.count)

        if case .single = registry {
        }
        else {
            XCTFail("registry should equal .Single")
        }
    }


    func testRemovingFirstHandlerYieldsEmpty1() {
        var registry = ClosureRegistry<String>()

        let id = registry.register({ s in
            print(s)
        })

        _ = registry.unregister(id)

        if case .empty = registry {
        }
        else {
            XCTFail("registry should equal .Empty")
        }
    }

    func testRemovingFirstHandlerYieldsEmpty2() {
        var registry = ClosureRegistry<Void>()

        let id = registry.register({ s in
            print(s)
        })

        _ = registry.unregister(id)

        if case .empty = registry {
        }
        else {
            XCTFail("registry should equal .Empty")
        }
    }

    func testAddingTwoHandlersYieldsMultiple() {
        var registry = ClosureRegistry<String>()

        _ = registry.register({ s in
            print(s)
        })

        _ = registry.register({ s in
            print(s)
        })

        XCTAssertEqual(2, registry.count)

        if case .multiple = registry {
        }
        else {
            XCTFail("registry should equal .Multiple")
        }
    }

    func testRunWithouHandlersSucceeds() {
        let registry = ClosureRegistry<String>()
        registry.resume("OK")
        XCTAssert(true)
    }


    func testRegistredHandlersWillExecuteOnRun1() {
        var registry = ClosureRegistry<String>()

        let expect1 = self.expectation(withDescription: "handler1 should be called")

        _ = registry.register({ s in
            XCTAssertEqual("OK", s)
            expect1.fulfill()
        })

        registry.resume("OK")
        waitForExpectations(withTimeout: 1, handler: nil)
    }

    func testRegistredHandlersWillExecuteOnRun2() {
        var registry = ClosureRegistry<String>()

        let expect1 = self.expectation(withDescription: "handler1 should be called")
        let expect2 = self.expectation(withDescription: "handler2 should be called")

        _ = registry.register({ s in
            XCTAssertEqual("OK", s)
            expect1.fulfill()
        })

        _ = registry.register({ s in
            XCTAssertEqual("OK", s)
            expect2.fulfill()
        })

        registry.resume("OK")
        waitForExpectations(withTimeout: 1, handler: nil)
    }



    func testRegistredHandlersWillExecuteOnRun3() {
        var registry = ClosureRegistry<String>()

        let expect1 = self.expectation(withDescription: "handler1 should be called")
        let expect2 = self.expectation(withDescription: "handler2 should be called")
        let expect3 = self.expectation(withDescription: "handler2 should be called")


        _ = registry.register({ s in
            XCTAssertEqual("OK", s)
            expect1.fulfill()
        })

        _ = registry.register({ s in
            XCTAssertEqual("OK", s)
            expect2.fulfill()
        })

        _ = registry.register({ s in
            XCTAssertEqual("OK", s)
            expect3.fulfill()
        })

        registry.resume("OK")
        waitForExpectations(withTimeout: 1, handler: nil)
    }



    func testUnregistredHandlersWillNotExecuteOnRun1() {
        var registry = ClosureRegistry<String>()

        let expect1 = self.expectation(withDescription: "handler1 should be called")
        let expect2 = self.expectation(withDescription: "handler2 should be called")
        let expect3 = self.expectation(withDescription: "handler3 should be called")


        let id0 = registry.register({ s in
            XCTFail("Unexpected")
        })

        let _ = registry.register({ s in
            XCTAssertEqual("OK", s)
            expect1.fulfill()
        })

        let _ = registry.register({ s in
            XCTAssertEqual("OK", s)
            expect2.fulfill()
        })

        let _ = registry.register({ s in
            XCTAssertEqual("OK", s)
            expect3.fulfill()
        })


        _ = registry.unregister(id0)

        registry.resume("OK")
        waitForExpectations(withTimeout: 1, handler: nil)
    }


    func testUnregistredHandlersWillNotExecuteOnRun2() {
        var registry = ClosureRegistry<String>()

        let expect1 = self.expectation(withDescription: "handler1 should be called")
        let expect2 = self.expectation(withDescription: "handler2 should be called")
        let expect3 = self.expectation(withDescription: "handler3 should be called")


        let _ = registry.register({ s in
            XCTAssertEqual("OK", s)
            expect1.fulfill()
        })

        let id0 = registry.register({ s in
            XCTFail("Unexpected")
        })

        let _ = registry.register({ s in
            XCTAssertEqual("OK", s)
            expect2.fulfill()
        })

        let _ = registry.register({ s in
            XCTAssertEqual("OK", s)
            expect3.fulfill()
        })


        _ = registry.unregister(id0)

        registry.resume("OK")
        waitForExpectations(withTimeout: 1, handler: nil)
    }

    func testUnregistredHandlersWillNotExecuteOnRun3() {
        var registry = ClosureRegistry<String>()

        let expect1 = self.expectation(withDescription: "handler1 should be called")
        let expect2 = self.expectation(withDescription: "handler2 should be called")
        let expect3 = self.expectation(withDescription: "handler3 should be called")


        let _ = registry.register({ s in
            XCTAssertEqual("OK", s)
            expect1.fulfill()
        })

        let _ = registry.register({ s in
            XCTAssertEqual("OK", s)
            expect2.fulfill()
        })

        let id0 = registry.register({ s in
            XCTFail("Unexpected")
        })

        let _ = registry.register({ s in
            XCTAssertEqual("OK", s)
            expect3.fulfill()
        })


        _ = registry.unregister(id0)

        registry.resume("OK")
        waitForExpectations(withTimeout: 1, handler: nil)
    }



    func testUnregistredHandlersWillNotExecuteOnRun4() {
        var registry = ClosureRegistry<String>()

        let expect1 = self.expectation(withDescription: "handler1 should be called")
        let expect2 = self.expectation(withDescription: "handler2 should be called")
        let expect3 = self.expectation(withDescription: "handler3 should be called")


        let _ = registry.register({ s in
            XCTAssertEqual("OK", s)
            expect1.fulfill()
        })

        let _ = registry.register({ s in
            XCTAssertEqual("OK", s)
            expect2.fulfill()
        })

        let _ = registry.register({ s in
            XCTAssertEqual("OK", s)
            expect3.fulfill()
        })

        let id0 = registry.register({ s in
            XCTFail("Unexpected")
        })


        _ = registry.unregister(id0)

        registry.resume("OK")
        waitForExpectations(withTimeout: 1, handler: nil)
    }




}
