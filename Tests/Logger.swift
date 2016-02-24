//
//  Logger.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import Dispatch
import Darwin





internal func dateTimeString(t: time_t, usec: suseconds_t, format: String) -> String {
    let maxSize: Int = 64
    var buffer: [Int8] = [CChar](count: Int(maxSize), repeatedValue: 0)
    var t_tmp = t;
    let length = strftime(&buffer, maxSize, format, localtime(&t_tmp));
    assert(length > 0)
    let s = String.fromCString(buffer)
    let s2 = String(format: s!, usec)
    return s2
}



public protocol EventType {
    associatedtype ValueType
}



public struct Event<T> : EventType {

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


    init(message: T, severity: Logger.Severity = Logger.Severity.None) {
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
    public let gcd_queue: String? = String.fromCString(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL))
    public let category: String
    public let severity: Logger.Severity
    public let message: T
    public let function: StaticString
    public let file: StaticString
    public let line: UInt
}


public struct WriteOptions: OptionSetType {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    public static let None         = WriteOptions(rawValue: 0)
    public static let Sync         = WriteOptions(rawValue: 1 << 0)
}

public struct EventOptions : OptionSetType {
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

    internal static func localTime(tval: timeval) -> DateTime {
        return DateTime(tval: tval, localtime: true)
    }


    internal static func defaultDateTimeFormatter(tval: timeval) -> String {
        let t = DateTime.localTime(tval)
        let s: String = String(format: "%hu-%.2hhu-%.2hhu %.2hhu:%.2hhu:%06.3f", t.year, t.month, t.day, t.hour, t.min, t.sec)
        return s
    }

}



public protocol EventTargetType  {

    var name: String { get }
    var writeOptions: WriteOptions { get set }

    mutating func writeEvent<T>(event: Event<T>)
}



public protocol Flushable {
    func flush()
}




public protocol StreamEventTargetType : EventTargetType, Flushable {

    var eventOptions: EventOptions { get set }

    var dateFormat: (timeval: timeval)-> String { get set }

    func flush()
}



public protocol FlushableOutputStreamType : OutputStreamType, Flushable {
}



private struct StdOutputStream : FlushableOutputStreamType {
    func write(string: String) { fputs(string, stdout) }
    func flush() { fflush(stdout)}
}



private struct StdErrorStream : FlushableOutputStreamType {
    func write(string: String) { fputs(string, stdout) }
    func flush() { fflush(stderr)}
}



public class ConsoleEventTarget : StreamEventTarget {

    static private var stdOutputStream = StdOutputStream()
    static private let _executionQueue = dispatch_queue_create("ConsoleEventTarget queue", dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INTERACTIVE, 0))

    public init() {
        super.init(name: "Console", ostream: StdOutputStream(), executionQueue: ConsoleEventTarget._executionQueue)
    }

}



public class StreamEventTarget : StreamEventTargetType {

    private (set) public var name: String
    public let executionQueue: dispatch_queue_t

    internal var _ostream: FlushableOutputStreamType
    private var _writeOptions: WriteOptions
    private var _eventOptions: EventOptions
    private var _dateFormat: (timeval: timeval)-> String = DateTime.defaultDateTimeFormatter


    public init(name: String,
        ostream: FlushableOutputStreamType,
        writeOptions: WriteOptions = WriteOptions(),
        eventOptions: EventOptions = EventOptions([.TimeStamp, .ThreadId, .GCDQueue, .Category, .Severity, .Function]),
        executionQueue eq: dispatch_queue_t = dispatch_queue_create("", DISPATCH_QUEUE_SERIAL))
    {
        self.name = name
        _ostream = ostream
        _writeOptions = writeOptions
        _eventOptions = eventOptions
        executionQueue = eq
    }

    deinit {
        dispatch_barrier_sync(executionQueue) {}
    }


    public func writeEvent<T>(event: Event<T>) {
        StreamEventTarget.writeEvent(&_ostream, event: event, writeOptions: writeOptions, eventOptions: eventOptions, dateFormat: dateFormat, executionQueue: executionQueue)
    }

    public func flush() {
        _ostream.flush()
    }


    internal static func writeMessage<T>(
        inout ostream: FlushableOutputStreamType,
        message: T,
        options: EventOptions)
    {
        let messageString = String(message)
        if !messageString.isEmpty {
            ostream.write(messageString)
        }
    }

    internal static func writeVerboseMessage<T>(
        inout ostream: FlushableOutputStreamType,
        message: T,
        options: EventOptions)
    {
        let messageString = String(reflecting: message)
        if !messageString.isEmpty {
            ostream.write(messageString)
        }
    }



    internal static func writeEvent<T>(
        inout ostream: FlushableOutputStreamType,
        event: Event<T>,
        writeOptions: WriteOptions,
        eventOptions: EventOptions,
        dateFormat: (timeval: timeval)-> String,
        executionQueue eq: dispatch_queue_t)
    {
        let f: ()->() = {
            var hasSeparator = true
            if eventOptions.contains(.TimeStamp) {
                ostream.write("\(dateFormat(timeval: event.timeStamp)) ")
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
                writeVerboseMessage(&ostream, message: event.message, options: eventOptions)
            }
            else {
                writeMessage(&ostream, message: event.message, options: eventOptions)
            }
            ostream.write("\n")
        }
        if writeOptions.contains(.Sync) {
            dispatch_sync(eq, f)
        }
        else {
            dispatch_async(eq, f)
        }
    }


    final public var writeOptions: WriteOptions {
        get {
            var result: WriteOptions = .None
            dispatch_sync(executionQueue) {
                result = self._writeOptions
            }
            return result
        }
        set {
            dispatch_async(executionQueue) {
                self._writeOptions = newValue
            }
        }
    }

    final public var eventOptions: EventOptions {
        get {
            var result: EventOptions = .None
            dispatch_sync(executionQueue) {
                result = self._eventOptions
            }
            return result
        }
        set {
            dispatch_async(executionQueue) {
                self._eventOptions = newValue
            }
        }
    }


    final public var dateFormat: (timeval: timeval)-> String {
        get {
            var result: (timeval: timeval)-> String = {_ in return ""}
            dispatch_sync(executionQueue) {
                result = self._dateFormat
            }
            return result
        }
        set {
            dispatch_async(executionQueue) {
                self._dateFormat = newValue
            }
        }
    }

}



public class Logger {

    private let _syncQueue = dispatch_queue_create("Logger sync_queue", DISPATCH_QUEUE_CONCURRENT)



    public enum Severity: Int {
        case None, Error, Warning, Info, Debug, Trace
    }

    private var _eventTargets: [EventTargetType]
    private let _category: String

    public var logLevel = Severity.Error


    public var eventTargets: [EventTargetType] {
        get {
            var result = [EventTargetType]()
            dispatch_sync(self._syncQueue) {
                result = self._eventTargets
            }
            return result
        }
        set {
            dispatch_barrier_async(self._syncQueue) {
                self._eventTargets = newValue
            }
        }
    }


    public init(@autoclosure category: ()-> String, verbosity: Severity, targets: [EventTargetType] = [ConsoleEventTarget()])
    {
        _category = category()
        self.logLevel = verbosity
        _eventTargets = targets
    }

    convenience public init(@autoclosure category: ()-> String, targets: [EventTargetType] = [ConsoleEventTarget()]) {
        self.init(category: category, verbosity: Severity.Info, targets: targets)
    }

    public func writeln<T>(@autoclosure object: ()-> T) {
        let event = Event(category: _category, severity: Severity.None, message: object())
        for var et in eventTargets {
            et.writeEvent(event)
        }
    }

    public func Error<T>(@autoclosure object: ()-> T, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
        if (self.logLevel.rawValue > Severity.None.rawValue) {
            let event = Event(category: self._category, severity: Severity.Error, message: object(), function: function, file: file, line: line)
            for var et in eventTargets {
                et.writeEvent(event)
            }
        }
    }

    public func Warning<T>(@autoclosure object: ()-> T, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
        if (self.logLevel.rawValue > Severity.Error.rawValue) {
            let event = Event(category: self._category, severity: Severity.Warning, message: object(), function: function, file: file, line: line)
            for var et in eventTargets {
                et.writeEvent(event)
            }
        }
    }

    public func Info<T>(@autoclosure object: ()-> T, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
        if (self.logLevel.rawValue > Severity.Warning.rawValue) {
            let event = Event(category: self._category, severity: Severity.Info, message: object(), function: function, file: file, line: line)
            for var et in eventTargets {
                et.writeEvent(event)
            }
        }
    }

    public func Debug<T>(@autoclosure object: ()-> T, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
        if (self.logLevel.rawValue > Severity.Info.rawValue) {
            let event = Event(category: self._category, severity: Severity.Debug, message: object(), function: function, file: file, line: line)
            for var et in eventTargets {
                et.writeEvent(event)
            }
        }
    }

    public func Trace<T>(@autoclosure object: ()-> T, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
        if (self.logLevel.rawValue > Severity.Debug.rawValue) {
            let event = Event(category: self._category, severity: Severity.Trace, message: object(), function: function, file: file, line: line)
            for var et in eventTargets {
                et.writeEvent(event)
            }
        }
    }


}
