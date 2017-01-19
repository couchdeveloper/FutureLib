//
//  Logger.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import Dispatch
import Darwin


/// Initialize and configure the Logger
internal var Log: Logger  = {
    var target = ConsoleEventTarget()
    //target.writeOptions = .Sync
    return Logger(category: "FutureLib", verbosity: Logger.Severity.trace, targets: [target])
}()




/// Create a date time string from the given point in time specified as a `time_t` value and the micro seconds using the given format string.
///
/// - Parameters:
///   - t: A Unix `time_t` data type which is an integral value holding the number of seconds (not counting leap seconds) since 00:00, Jan 1 1970 UTC.
///   - usec: The amount of micro seconds which can be specified in order to increases the precision of the time.
///   - format: A format string as specified in function `strftime`.
/// - Returns: A string representing the time.
internal func dateTimeString(_ t: time_t, usec: suseconds_t, format: String) -> String {
    let maxSize: Int = 64
    var buffer: [Int8] = [CChar](repeating: 0, count: Int(maxSize))
    var t_tmp = t;
    let length = strftime(&buffer, maxSize, format, localtime(&t_tmp));
    assert(length > 0)
    let s = String(cString: buffer)
    let s2 = String(format: s, usec)
    return s2
}



public protocol EventType {
    associatedtype ValueType
}



public struct Event<T>: EventType {

    public typealias ValueType = T


    init(category: String, severity: Logger.Severity, message: T, function: StaticString = "", file: StaticString = "" , line: UInt = 0) {
        gettimeofday(&timeStamp, nil)
        self.category = category
        self.severity = severity
        self.message = message
        self.function = function
        self.file = file
        self.line = line
    }


    init(message: T, severity: Logger.Severity = Logger.Severity.none) {
        gettimeofday(&self.timeStamp, nil)
        self.message = message
        self.severity = severity
        category = ""
        function = ""
        file = ""
        line = 0
    }


    private (set) public var timeStamp: timeval = timeval()
    public let threadId = pthread_mach_thread_np(pthread_self())
    public let gcd_queue: String? = String.init(cString: __dispatch_queue_get_label(nil)) // = String.fromCString(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL))
    public let category: String
    public let severity: Logger.Severity
    public let message: T
    public let function: StaticString
    public let file: StaticString
    public let line: UInt
}


public struct WriteOptions: OptionSet {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    public static let None         = WriteOptions(rawValue: 0)
    public static let Sync         = WriteOptions(rawValue: 1 << 0)
}

public struct EventOptions: OptionSet {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    public static let None         = EventOptions(rawValue: 0)
    public static let TimeStamp    = EventOptions(rawValue: 1 << 0)

    public static let Process      = EventOptions(rawValue: 1 << 1)
    public static let PID          = EventOptions(rawValue: 1 << 2)
    public static let ThreadId     = EventOptions(rawValue: 1 << 3)

    public static let GCDQueue     = EventOptions(rawValue: 1 << 4)
    public static let Category     = EventOptions(rawValue: 1 << 5)
    public static let Severity     = EventOptions(rawValue: 1 << 6)
    public static let Function     = EventOptions(rawValue: 1 << 7)
    public static let File         = EventOptions(rawValue: 1 << 8)
    public static let Line         = EventOptions(rawValue: 1 << 9)
    public static let All: EventOptions = [.TimeStamp, .ThreadId, .GCDQueue, .Category, .Severity, .Function, .File, .Line]
    public static let Default: EventOptions = [.TimeStamp, .ThreadId, .GCDQueue, .Category, .Severity, .Function]

    public static let Verbose      = EventOptions(rawValue: 1 << 15)
}



internal struct DateTime {

    let year: UInt16
    let month: UInt8
    let day: UInt8
    let hour: UInt8
    let min: UInt8
    let sec: Double

    private init(tval: timeval, localtime: Bool = true) {
        var t_tmp = tval;
        var t: tm = tm()
        localtime_r(&t_tmp.tv_sec, &t)

        year = UInt16(t.tm_year + 1900)
        month = UInt8(t.tm_mon + 1)
        day = UInt8(t.tm_mday)
        hour = UInt8(t.tm_hour)
        min = UInt8(t.tm_min)
        sec = Double(t.tm_sec) + Double(tval.tv_usec)/(1000*1000)
    }

    internal static func localTime(_ tval: timeval) -> DateTime {
        return DateTime(tval: tval, localtime: true)
    }


    internal static func defaultDateTimeFormatter(_ tval: timeval) -> String {
        let t = DateTime.localTime(tval)
        let s: String = String(format: "%hu-%.2hhu-%.2hhu %.2hhu:%.2hhu:%06.3f", t.year, t.month, t.day, t.hour, t.min, t.sec)
        return s
    }

}



public protocol EventTargetType  {

    var name: String { get }
    var writeOptions: WriteOptions { get set }

    mutating func writeEvent<T>(_ event: Event<T>)
}



public protocol Flushable {
    func flush()
}

public protocol OutputStream {
    func write(_ string: String)    
}


public protocol StreamEventTargetType: EventTargetType, Flushable {

    var eventOptions: EventOptions { get set }

    var dateFormat: (timeval) -> String { get set }

    func flush()
}



public protocol FlushableOutputStreamType: OutputStream, Flushable {
}



private struct StdOutputStream: FlushableOutputStreamType {
    func write(_ string: String) { fputs(string, stdout) }
    func flush() { fflush(stdout)}
}



private struct StdErrorStream: FlushableOutputStreamType {
    func write(_ string: String) { fputs(string, stdout) }
    func flush() { fflush(stderr)}
}



public class ConsoleEventTarget: StreamEventTarget {

    static private var stdOutputStream = StdOutputStream()
    static private let _executionQueue = DispatchQueue(label: "ConsoleEventTarget queue")

    public init() {
        super.init(name: "Console", ostream: StdOutputStream(), executionQueue: ConsoleEventTarget._executionQueue)
    }

}



public class StreamEventTarget: StreamEventTargetType {

    private (set) public var name: String
    public let executionQueue: DispatchQueue

    internal var _ostream: FlushableOutputStreamType
    private var _writeOptions: WriteOptions
    private var _eventOptions: EventOptions
    private var _dateFormat: (_ timeval: timeval)-> String = DateTime.defaultDateTimeFormatter


    public init(name: String, ostream: FlushableOutputStreamType, writeOptions: WriteOptions = WriteOptions(), eventOptions: EventOptions = EventOptions([.TimeStamp, .ThreadId, .GCDQueue, .Category, .Severity, .Function]), executionQueue eq: DispatchQueue = DispatchQueue(label: "")) {
        self.name = name
        _ostream = ostream
        _writeOptions = writeOptions
        _eventOptions = eventOptions
        executionQueue = eq
    }

    deinit {
        executionQueue.sync {}
    }


    public func writeEvent<T>(_ event: Event<T>) {
        StreamEventTarget.writeEvent(_ostream, event: event, writeOptions: writeOptions, eventOptions: eventOptions, dateFormat: dateFormat, executionQueue: executionQueue)
    }

    public func flush() {
        _ostream.flush()
    }


    internal static func writeMessage<T>(_ ostream: FlushableOutputStreamType, message: T, options: EventOptions) {
        let messageString = String(describing: message)
        if !messageString.isEmpty {
            ostream.write(messageString)
        }
    }

    internal static func writeVerboseMessage<T>(_ ostream: FlushableOutputStreamType, message: T, options: EventOptions) {
        let messageString = String(reflecting: message)
        if !messageString.isEmpty {
            ostream.write(messageString)
        }
    }



    internal static func writeEvent<T>(_ ostream: FlushableOutputStreamType, event: Event<T>, writeOptions: WriteOptions, eventOptions: EventOptions, dateFormat: @escaping (timeval)-> String, executionQueue eq: DispatchQueue) {
        let f: ()->() = {
            var hasSeparator = true
            if eventOptions.contains(.TimeStamp) {
                ostream.write("\(dateFormat(event.timeStamp)) ")
                hasSeparator = true
            }
            if eventOptions.contains(.ThreadId) {
                ostream.write("[\(event.threadId)]")
                hasSeparator = false
            }
            if eventOptions.contains(.GCDQueue) {
                let gcd_queue = event.gcd_queue == nil ? "" : event.gcd_queue!
                ostream.write("(\(gcd_queue))")
                hasSeparator = false
            }
            if eventOptions.contains(.Category) {
                if !hasSeparator {
                    ostream.write(" ")
                }
                ostream.write("<\(event.category)>")
                hasSeparator = false
            }
            if eventOptions.contains(.Severity) {
                if !hasSeparator {
                    ostream.write(" ")
                }
                ostream.write("\(event.severity)")
                hasSeparator = false
            }
            if eventOptions.contains(.Function) {
                if !hasSeparator {
                    ostream.write(" ")
                }
                ostream.write("\(event.function)")
                hasSeparator = false
            }
            if eventOptions.contains(.File) {
                if !hasSeparator {
                    ostream.write(" ")
                }
                ostream.write("\(event.file)")
                hasSeparator = false
            }
            if eventOptions.contains(.Line) {
                if eventOptions.contains(.File) {
                    ostream.write(".")
                }
                else if !hasSeparator {
                    ostream.write(" ")
                }
                ostream.write("\(event.line)")
                hasSeparator = false
            }
            if !hasSeparator {
                ostream.write(" ")
            }
            if eventOptions.contains(.Verbose) {
                writeVerboseMessage(ostream, message: event.message, options: eventOptions)
            }
            else {
                writeMessage(ostream, message: event.message, options: eventOptions)
            }
            ostream.write("\n")
        }
        if writeOptions.contains(.Sync) {
            eq.sync(execute: f)
        }
        else {
            eq.async(execute: f)
        }
    }


    final public var writeOptions: WriteOptions {
        get {
            var result: WriteOptions = .None
            executionQueue.sync {
                result = self._writeOptions
            }
            return result
        }
        set {
            executionQueue.async {
                self._writeOptions = newValue
            }
        }
    }

    final public var eventOptions: EventOptions {
        get {
            var result: EventOptions = .None
            executionQueue.sync {
                result = self._eventOptions
            }
            return result
        }
        set {
            executionQueue.async {
                self._eventOptions = newValue
            }
        }
    }


    final public var dateFormat: (_ timeval: timeval)-> String {
        get {
            var result: (_ timeval: timeval)-> String = {_ in return ""}
            executionQueue.sync {
                result = self._dateFormat
            }
            return result
        }
        set {
            executionQueue.async {
                self._dateFormat = newValue
            }
        }
    }

}



public class Logger {

    private let _syncQueue = DispatchQueue.init(label: "Logger sync_queue", attributes: .concurrent)
    
    public enum Severity: Int {
        case none, error, warning, info, debug, trace
    }

    private var _eventTargets: [EventTargetType]
    private let _category: String

    public var logLevel = Severity.error


    public var eventTargets: [EventTargetType] {
        get {
            var result = [EventTargetType]()
            self._syncQueue.sync {
                result = self._eventTargets
            }
            return result
        }
        set {
            self._syncQueue.async {
                self._eventTargets = newValue
            }
        }
    }


    public init( category: @autoclosure()-> String, verbosity: Severity, targets: [EventTargetType] = [ConsoleEventTarget()])
    {
        _category = category()
        self.logLevel = verbosity
        _eventTargets = targets
    }

    convenience public init(category: @autoclosure ()-> String, targets: [EventTargetType] = [ConsoleEventTarget()]) {
        self.init(category: category, verbosity: Severity.info, targets: targets)
    }

    public func writeln<T>(_ object: @autoclosure ()-> T) {
        let event = Event(category: _category, severity: Severity.none, message: object())
        for var et in eventTargets {
            et.writeEvent(event)
        }
    }

    public func Error<T>(_ object: @autoclosure ()-> T, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
        if (self.logLevel.rawValue > Severity.none.rawValue) {
            let event = Event(category: self._category, severity: Severity.error, message: object(), function: function, file: file, line: line)
            for var et in eventTargets {
                et.writeEvent(event)
            }
        }
    }

    public func Warning<T>(_ object: @autoclosure ()-> T, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
        if (self.logLevel.rawValue > Severity.error.rawValue) {
            let event = Event(category: self._category, severity: Severity.warning, message: object(), function: function, file: file, line: line)
            for var et in eventTargets {
                et.writeEvent(event)
            }
        }
    }

    public func Info<T>(_ object: @autoclosure ()-> T, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
        if (self.logLevel.rawValue > Severity.warning.rawValue) {
            let event = Event(category: self._category, severity: Severity.info, message: object(), function: function, file: file, line: line)
            for var et in eventTargets {
                et.writeEvent(event)
            }
        }
    }

    public func Debug<T>(_ object: @autoclosure ()-> T, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
        if (self.logLevel.rawValue > Severity.info.rawValue) {
            let event = Event(category: self._category, severity: Severity.debug, message: object(), function: function, file: file, line: line)
            for var et in eventTargets {
                et.writeEvent(event)
            }
        }
    }

    public func Trace<T>(_ object: @autoclosure ()-> T, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
        if (self.logLevel.rawValue > Severity.debug.rawValue) {
            let event = Event(category: self._category, severity: Severity.trace, message: object(), function: function, file: file, line: line)
            for var et in eventTargets {
                et.writeEvent(event)
            }
        }
    }


}
