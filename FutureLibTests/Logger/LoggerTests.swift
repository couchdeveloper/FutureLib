//
//  LoggerTests.swift
//  Future
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import XCTest
import FutureLib


class StringStream : FlushableOutputStreamType {
    final var string: String = ""
    final func write(string: String) {
        self.string.appendContentsOf(string)
    }
    
    final func flush() {}
    
}

class StringEventTarget : StreamEventTarget {
    
    private let _stringstream = StringStream()
    
    init() {
        let eq = dispatch_queue_create("StringEventTarget private queue", DISPATCH_QUEUE_SERIAL)
        super.init(name: "StringStream", ostream: _stringstream, executionQueue: eq)
    }
    
    var string: String {
        var result: String = ""
        dispatch_barrier_sync(executionQueue) {
            result = self._stringstream.string
        }
        return result
    }
    
    func clear() {
        dispatch_barrier_async(executionQueue) {
            self._stringstream.string = ""
        }
    }
    
}


private class TestMessage {
}

extension TestMessage : CustomDebugStringConvertible {
    
    var debugDescription: String {
        return "This is a verbose description of `TestMessage`."
    }
    
}


extension TestMessage : CustomStringConvertible {
    
    var description: String {
        return "This is a short description of `TestMessage`."
    }
    
}

    



extension String {
    /// Returns `true` iff `self` begins contains `substring`.
    public func contains(substring: String) -> Bool {
        let range = self.rangeOfString(substring)
        if let r = range {
            return r.startIndex != r.endIndex
        }
        return false
    }
}


class LoggerTests: XCTestCase {
    

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
    

    func testExample() {
        let s = "Happy logging"
        let target = StringEventTarget()
        target.eventOptions = .None
        let log = Logger(category: "Test", verbosity: Logger.Severity.Trace, targets: [target])
        
        log.Trace("\(s)")
        let logMessage = target.string
        XCTAssertEqual(s + "\n", logMessage, "expected: \(s), actual: \(logMessage)")
    }

    
    func testExample2() {
        let target = StringEventTarget()
        let log = Logger(category: "Test", verbosity: Logger.Severity.Trace, targets: [target])
        
        let s = "Happy logging"
        log.Trace("\(s)")
        let logMessage = target.string
        //print(logMessage)
        
        XCTAssertTrue(logMessage.contains("Test"))
        XCTAssertTrue(logMessage.contains("Trace"))
        XCTAssertTrue(logMessage.contains("testExample2()"))
        XCTAssertTrue(logMessage.contains("com.apple.main-thread"))
        XCTAssertTrue(logMessage.contains(s))
    }
    
    func testExample3() {
        let target = StringEventTarget()
        XCTAssertTrue(target.string.isEmpty)
        let log = Logger(category: "XXXX", verbosity: Logger.Severity.Trace, targets: [target])
        target.eventOptions = .TimeStamp
        let s = "Happy logging"
        log.Trace(s)
        let logMessage = target.string
        XCTAssertFalse(logMessage.contains("Test"), logMessage)
        XCTAssertFalse(logMessage.contains("Trace"), logMessage)
        XCTAssertFalse(logMessage.contains("testExample3()"), logMessage)
        XCTAssertFalse(logMessage.contains("com.apple.main-thread"), logMessage)
        XCTAssertTrue(logMessage.contains(s))
    }
    
    
    func testExample4() {
        let stringTarget = StringEventTarget()
        let consoleTarget = ConsoleEventTarget()
        stringTarget.eventOptions = [.TimeStamp, .Verbose]
        consoleTarget.eventOptions = [.TimeStamp, .Verbose]
        consoleTarget.writeOptions = [.Sync]
        let log = Logger(category: String(Mirror(reflecting: self).subjectType), verbosity: Logger.Severity.Trace, targets: [stringTarget])
        for i in 0..<10 {
            log.Trace("\(i) to stringstream")
        }
        log.eventTargets = [consoleTarget]
        for i in 0..<10 {
            log.Trace("\(i) to Console")
        }
        
        let logMessage = stringTarget.string
        print(logMessage)
        consoleTarget.flush()
        XCTAssertFalse(logMessage.isEmpty)

}



}
