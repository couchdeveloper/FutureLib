//
//  TimerTests.swift
//  FutureLib
//
//  Created by Andreas Grosam on 24/02/16.
//  Copyright © 2016 Andreas Grosam. All rights reserved.
//

import XCTest
import FutureLib
import Darwin


private let sTimebaseInfo: mach_timebase_info_data_t = {
    var timebaseInfo = mach_timebase_info_data_t()
    mach_timebase_info(&timebaseInfo)
    return timebaseInfo
}()

func toSeconds(absoluteDuration: UInt64) -> Double {
    return Double(absoluteDuration) * 1.0e-9 * Double(sTimebaseInfo.numer) / Double(sTimebaseInfo.denom)
}

class TimerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testTimerWith1000msDurationShouldHave1PercentAccuracy() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        let t0 = mach_absolute_time()
        Timer(delay: 1.0, tolerance: 0.0) { timer in
            let t1 = mach_absolute_time()
            let elapsed = t1 - t0;
            let elapsedNano = toSeconds(elapsed)
            XCTAssertEqualWithAccuracy(1.0, elapsedNano, accuracy: 0.01)
            expect.fulfill()
        }
        .resume()
        self.waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    
    func testTimerWith100msDurationShouldHave1PercentAccuracy() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        let t0 = mach_absolute_time()
        Timer(delay: 0.1, tolerance: 0.0) { timer in
            let t1 = mach_absolute_time()
            let elapsed = t1 - t0;
            let elapsedNano = toSeconds(elapsed)
            XCTAssertEqualWithAccuracy(0.10, elapsedNano, accuracy: 0.001)
            expect.fulfill()
        }
        .resume()
        self.waitForExpectationsWithTimeout(2, handler: nil)
    }

    func testTimerWith10msDurationShouldHave10PercentAccuracy() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        let t0 = mach_absolute_time()
        Timer(delay: 0.01, tolerance: 0.0) { timer in
            let t1 = mach_absolute_time()
            let elapsed = t1 - t0;
            let elapsedNano = toSeconds(elapsed)
            XCTAssertEqualWithAccuracy(0.01, elapsedNano, accuracy: 0.001)
            expect.fulfill()
        }
        .resume()
        self.waitForExpectationsWithTimeout(2, handler: nil)
    }
    

    func testTwoTimersWith100msAnd10msDurationShouldHave2And30PercentAccuracy() {
        let expect1 = self.expectationWithDescription("future should be fulfilled")
        let expect2 = self.expectationWithDescription("future should be fulfilled")
        let t0 = mach_absolute_time()
        Timer(delay: 0.1, tolerance: 0.0) { timer in
            let t1 = mach_absolute_time()
            let elapsed = t1 - t0;
            let elapsedNano = toSeconds(elapsed)
            XCTAssertEqualWithAccuracy(0.10, elapsedNano, accuracy: 0.001)
            expect1.fulfill()
            }
            .resume()
        Timer(delay: 0.01, tolerance: 0.0) { timer in
            let t1 = mach_absolute_time()
            let elapsed = t1 - t0;
            let elapsedNano = toSeconds(elapsed)
            XCTAssertEqualWithAccuracy(0.01, elapsedNano, accuracy: 0.001)
            expect2.fulfill()
            }
            .resume()
        self.waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    
}
