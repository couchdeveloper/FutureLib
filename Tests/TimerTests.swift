//
//  TimerTests.swift
//  FutureLib
//
//  Created by Andreas Grosam on 24/02/16.
//  Copyright © 2016 Andreas Grosam. All rights reserved.
//

import XCTest
import FutureLib



class TimerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testTimerShouldNotDeinitPrematurely() {
        let expect = self.expectation(withDescription: "future should be fulfilled")
        FutureLib.Timer.scheduleOneShotAfter(0.1) {  
            expect.fulfill()
        } 
        self.waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    func testTimerWith1000msDurationShouldHave1PercentAccuracy() {
        let expect = self.expectation(withDescription: "future should be fulfilled")
        let stopWatch = StopWatch() 
        stopWatch.start()
        FutureLib.Timer.scheduleOneShotAfter(1.0) {
            let elapsedSeconds = stopWatch.stop()
            XCTAssertEqualWithAccuracy(1.0, elapsedSeconds, accuracy: 0.01)
            expect.fulfill()
        }
        self.waitForExpectations(withTimeout: 2, handler: nil)
    }
    
    
    func testTimerWith100msDurationShouldHave1PercentAccuracy() {
        let expect = self.expectation(withDescription: "future should be fulfilled")
        let stopWatch = StopWatch() 
        stopWatch.start()
        FutureLib.Timer.scheduleOneShotAfter(0.1) {
            let elapsedSeconds = stopWatch.stop()
            XCTAssertEqualWithAccuracy(0.10, elapsedSeconds, accuracy: 0.001)
            expect.fulfill()
        }
        self.waitForExpectations(withTimeout: 2, handler: nil)
    }

    func testTimerWith10msDurationShouldHave10PercentAccuracy() {
        let expect = self.expectation(withDescription: "future should be fulfilled")
        let stopWatch = StopWatch() 
        stopWatch.start()
        FutureLib.Timer.scheduleOneShotAfter(0.01) { 
            let elapsedSeconds = stopWatch.stop()
            XCTAssertEqualWithAccuracy(0.01, elapsedSeconds, accuracy: 0.001)
            expect.fulfill()
        }
        self.waitForExpectations(withTimeout: 2, handler: nil)
    }
    

    func testTwoTimersWith100msAnd10msDurationShouldHave2And30PercentAccuracy() {
        let expect1 = self.expectation(withDescription: "future should be fulfilled")
        let expect2 = self.expectation(withDescription: "future should be fulfilled")
        let stopWatch = StopWatch() 
        stopWatch.start()
        FutureLib.Timer.scheduleOneShotAfter(0.1) { 
            let elapsedSeconds = stopWatch.time()
            XCTAssertEqualWithAccuracy(0.10, elapsedSeconds, accuracy: 0.001)
            expect1.fulfill()
        }
        FutureLib.Timer.scheduleOneShotAfter(0.01) { 
            let elapsedSeconds = stopWatch.time()
            XCTAssertEqualWithAccuracy(0.01, elapsedSeconds, accuracy: 0.001)
            expect2.fulfill()
        }
        self.waitForExpectations(withTimeout: 2, handler: nil)
    }
    
    
}
