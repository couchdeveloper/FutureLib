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

        if case .Empty = registry {
        }
        else {
            XCTFail("registry should equal .Empty")
        }
    }

    func testDefaultCtorYieldsEmpty2() {
        let registry = ClosureRegistry<Void>()
        XCTAssertEqual(0, registry.count)

        if case .Empty = registry {
        }
        else {
            XCTFail("registry should equal .Empty")
        }
    }



    func testAddingFirstHandlerYieldsSingle1() {
        var registry = ClosureRegistry<String>()

        registry.register({ s in
            print(s)
        })

        XCTAssertEqual(1, registry.count)

        if case .Single = registry {
        }
        else {
            XCTFail("registry should equal .Single")
        }
    }

    func testAddingFirstHandlerYieldsSingle2() {
        var registry = ClosureRegistry<Void>()

        registry.register({ s in
            print(s)
        })

        XCTAssertEqual(1, registry.count)

        if case .Single = registry {
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

        registry.unregister(id)

        if case .Empty = registry {
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

        registry.unregister(id)

        if case .Empty = registry {
        }
        else {
            XCTFail("registry should equal .Empty")
        }
    }

    func testAddingTwoHandlersYieldsMultiple() {
        var registry = ClosureRegistry<String>()

        registry.register({ s in
            print(s)
        })

        registry.register({ s in
            print(s)
        })

        XCTAssertEqual(2, registry.count)

        if case .Multiple = registry {
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

        let expect1 = self.expectationWithDescription("handler1 should be called")

        registry.register({ s in
            XCTAssertEqual("OK", s)
            expect1.fulfill()
        })

        registry.resume("OK")
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testRegistredHandlersWillExecuteOnRun2() {
        var registry = ClosureRegistry<String>()

        let expect1 = self.expectationWithDescription("handler1 should be called")
        let expect2 = self.expectationWithDescription("handler2 should be called")

        registry.register({ s in
            XCTAssertEqual("OK", s)
            expect1.fulfill()
        })

        registry.register({ s in
            XCTAssertEqual("OK", s)
            expect2.fulfill()
        })

        registry.resume("OK")
        waitForExpectationsWithTimeout(1, handler: nil)
    }



    func testRegistredHandlersWillExecuteOnRun3() {
        var registry = ClosureRegistry<String>()

        let expect1 = self.expectationWithDescription("handler1 should be called")
        let expect2 = self.expectationWithDescription("handler2 should be called")
        let expect3 = self.expectationWithDescription("handler2 should be called")


        registry.register({ s in
            XCTAssertEqual("OK", s)
            expect1.fulfill()
        })

        registry.register({ s in
            XCTAssertEqual("OK", s)
            expect2.fulfill()
        })

        registry.register({ s in
            XCTAssertEqual("OK", s)
            expect3.fulfill()
        })

        registry.resume("OK")
        waitForExpectationsWithTimeout(1, handler: nil)
    }



    func testUnregistredHandlersWillNotExecuteOnRun1() {
        var registry = ClosureRegistry<String>()

        let expect1 = self.expectationWithDescription("handler1 should be called")
        let expect2 = self.expectationWithDescription("handler2 should be called")
        let expect3 = self.expectationWithDescription("handler3 should be called")


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


        registry.unregister(id0)

        registry.resume("OK")
        waitForExpectationsWithTimeout(1, handler: nil)
    }


    func testUnregistredHandlersWillNotExecuteOnRun2() {
        var registry = ClosureRegistry<String>()

        let expect1 = self.expectationWithDescription("handler1 should be called")
        let expect2 = self.expectationWithDescription("handler2 should be called")
        let expect3 = self.expectationWithDescription("handler3 should be called")


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


        registry.unregister(id0)

        registry.resume("OK")
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testUnregistredHandlersWillNotExecuteOnRun3() {
        var registry = ClosureRegistry<String>()

        let expect1 = self.expectationWithDescription("handler1 should be called")
        let expect2 = self.expectationWithDescription("handler2 should be called")
        let expect3 = self.expectationWithDescription("handler3 should be called")


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


        registry.unregister(id0)

        registry.resume("OK")
        waitForExpectationsWithTimeout(1, handler: nil)
    }



    func testUnregistredHandlersWillNotExecuteOnRun4() {
        var registry = ClosureRegistry<String>()

        let expect1 = self.expectationWithDescription("handler1 should be called")
        let expect2 = self.expectationWithDescription("handler2 should be called")
        let expect3 = self.expectationWithDescription("handler3 should be called")


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


        registry.unregister(id0)

        registry.resume("OK")
        waitForExpectationsWithTimeout(1, handler: nil)
    }




}
