//
//  SharedCancellationStatePerformanceTests.swift
//  FutureLib
//
//  Created by Andreas Grosam on 07.12.15.
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import XCTest
@testable import FutureLib


class SharedCancellationStatePerformanceTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    // Performance


    func testPerformanceRegister_1000() {
        self.measureMetrics(XCTestCase.defaultPerformanceMetrics(), automaticallyStartMeasuring: false) {
            self.startMeasuring()
            for _ in 0..<100 {
                let cs = SharedCancellationState()
                for _ in 0..<1000 {
                    cs.onCancel(on: GCDAsyncExecutionContext()) {
                    }
                }
            }
            self.stopMeasuring()
        }
    }

    func testPerformanceRegister_100() {
        self.measureMetrics(XCTestCase.defaultPerformanceMetrics(), automaticallyStartMeasuring: false) {
            self.startMeasuring()
            for _ in 0..<1000 {
                let cs = SharedCancellationState()
                for _ in 0..<100 {
                    cs.onCancel(on: GCDAsyncExecutionContext()) {
                    }
                }
            }
            self.stopMeasuring()
        }
    }

    func testPerformanceRegister_10() {
        self.measureMetrics(XCTestCase.defaultPerformanceMetrics(), automaticallyStartMeasuring: false) {
            self.startMeasuring()
            for _ in 0..<10000 {
                let cs = SharedCancellationState()
                for _ in 0..<10 {
                    cs.onCancel(on: GCDAsyncExecutionContext()) {
                    }
                }
            }
            self.stopMeasuring()
        }
    }

    func testPerformanceRegister_5() {
        self.measureMetrics(XCTestCase.defaultPerformanceMetrics(), automaticallyStartMeasuring: false) {
            self.startMeasuring()
            for _ in 0..<20000 {
                let cs = SharedCancellationState()
                for _ in 0..<5 {
                    cs.onCancel(on: GCDAsyncExecutionContext()) {
                    }
                }
            }
            self.stopMeasuring()
        }
    }

    func testPerformanceRegister_2() {
        self.measureMetrics(XCTestCase.defaultPerformanceMetrics(), automaticallyStartMeasuring: false) {
            self.startMeasuring()
            for _ in 0..<50000 {
                let cs = SharedCancellationState()
                for _ in 0..<2 {
                    cs.onCancel(on: GCDAsyncExecutionContext()) {
                    }
                }
            }
            self.stopMeasuring()
        }

    }

    func testPerformanceRegister_1() {
        self.measureMetrics(XCTestCase.defaultPerformanceMetrics(), automaticallyStartMeasuring: false) {
            self.startMeasuring()
            for _ in 0..<100000 {
                let cs = SharedCancellationState()
                for _ in 0..<1 {
                    cs.onCancel(on: GCDAsyncExecutionContext()) {
                    }
                }
            }
            self.stopMeasuring()
        }
    }


}
