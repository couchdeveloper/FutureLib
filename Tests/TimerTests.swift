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
        let expect = self.expectation(description: "future should be fulfilled")
        let timer = FutureLib.Timer()
        timer.scheduleOneShotAfter(delay: 0.1) {  
            expect.fulfill()
        } 
        self.waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testTimerWith1000msDurationShouldHave1PercentAccuracy() {
        let expect = self.expectation(description: "future should be fulfilled")
        let stopWatch = StopWatch() 
        stopWatch.start()
        let timer = FutureLib.Timer()
        timer.scheduleOneShotAfter(delay: 1.0) {
            let elapsedSeconds = stopWatch.stop()
            XCTAssertEqualWithAccuracy(1.0, elapsedSeconds, accuracy: 0.01)
            expect.fulfill()
        }
        self.waitForExpectations(timeout: 2, handler: nil)
    }
    
    
    func testTimerWith100msDurationShouldHave1PercentAccuracy() {
        let expect = self.expectation(description: "future should be fulfilled")
        let stopWatch = StopWatch() 
        stopWatch.start()
        let timer = FutureLib.Timer()
        timer.scheduleOneShotAfter(delay: 0.1) {
            let elapsedSeconds = stopWatch.stop()
            XCTAssertEqualWithAccuracy(0.10, elapsedSeconds, accuracy: 0.001)
            expect.fulfill()
        }
        self.waitForExpectations(timeout: 2, handler: nil)
    }

    func testTimerWith10msDurationShouldHave10PercentAccuracy() {
        let expect = self.expectation(description: "future should be fulfilled")
        let stopWatch = StopWatch() 
        stopWatch.start()
        let timer = FutureLib.Timer()
        timer.scheduleOneShotAfter(delay: 0.01) { 
            let elapsedSeconds = stopWatch.stop()
            XCTAssertEqualWithAccuracy(0.01, elapsedSeconds, accuracy: 0.001)
            expect.fulfill()
        }
        self.waitForExpectations(timeout: 2, handler: nil)
    }
    

    func testTwoTimersWith100msAnd10msDurationShouldHave2And30PercentAccuracy() {
        let expect1 = self.expectation(description: "future should be fulfilled")
        let expect2 = self.expectation(description: "future should be fulfilled")
        let stopWatch = StopWatch() 
        let timer1 = FutureLib.Timer()
        let timer2 = FutureLib.Timer()
        stopWatch.start()
        timer1.scheduleOneShotAfter(delay: 0.1) {
            let elapsedSeconds = stopWatch.time()
            XCTAssertEqualWithAccuracy(0.10, elapsedSeconds, accuracy: 0.001)
            expect1.fulfill()
        }
        timer2.scheduleOneShotAfter(delay: 0.01) {
            let elapsedSeconds = stopWatch.time()
            XCTAssertEqualWithAccuracy(0.01, elapsedSeconds, accuracy: 0.001)
            expect2.fulfill()
        }
        self.waitForExpectations(timeout: 2, handler: nil)
    }
    
    
}
