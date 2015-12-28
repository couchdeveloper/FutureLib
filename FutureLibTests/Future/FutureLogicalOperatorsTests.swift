//
//  FutureLogicalOperatorsTests.swift
//  FutureLib
//
//  Created by Andreas Grosam on 07.12.15.
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import XCTest
import FutureLib

class FutureLogicalOperatorsTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testExample() {
        func task1() -> Future<Int> {
            //return schedule_after(1.0, cancellationToken: ct) { "A" }
            return Promise(value: 1).future!
        }
        
        func task2() -> Future<Double> {
            //return schedule_after(1.25, cancellationToken: ct) { "B" }
            return Promise(value: 1.23).future!
        }
        
        func task3() -> Future<String> {
            //return schedule_after(1.25, cancellationToken: ct) { "B" }
            return Promise(value: "B").future!
        }
        
        
        func task4(args: (Int, Double, String)) -> Future<String> {
            //return schedule_after(1.5, cancellationToken: ct) { args.0 + args.1 }
            return Promise(value: "\(args.0) \(args.1) \(args.2)").future!
        }
        
        let f1 = task1()
        let f2 = task2()
        let f3 = task3()
        
        
        (f1 && f2 && f3)
            .map { tupel in
                print("tupel: \(tupel)")
        }
        
        
    }


}
