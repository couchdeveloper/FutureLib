//
//  Logger.swift
//  Future
//
//  Created by Andreas Grosam on 01.01.15.
//  Copyright (c) 2015 Andreas Grosam. All rights reserved.
//

import Dispatch
import Darwin





internal func dateTimeString(t:time_t, usec: suseconds_t, format: String) -> String {
    let maxSize: Int = 64
    var buffer: [Int8] = [CChar](count: Int(maxSize), repeatedValue: 0)
    var t_tmp = t;
    let length = strftime(&buffer, maxSize, format, localtime(&t_tmp));
    assert(length > 0)
    let s = String.fromCString(buffer)
    let s2 = String(format:s!, usec)
    return s2
}



private protocol EventType {
    typealias ValueType
}


private class Event<T> : EventType {
    
    typealias ValueType = T
    
    init(category: StaticString, severity: Logger.Severity, message: T, function: StaticString = "", file: StaticString = "" , line: UWord = 0) {
        gettimeofday(&_timeStamp, nil)
        _category = category
        _severity = severity
        _message = message
        _function = function
        _file = file
        _line = line
    }
    
    
    init(message: T, severity : Logger.Severity = Logger.Severity.None) {
        gettimeofday(&_timeStamp, nil)
        _message = message
        _severity = severity
        _category = ""
        _function = ""
        _file = ""
        _line = 0
    }
    
    
    private var _timeStamp:timeval = timeval()
    private let _threadId = pthread_mach_thread_np(pthread_self())
    private let _gcd_queue:String? = String.fromCString(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL))
    private let _category: StaticString
    private let _severity: Logger.Severity
    private let _message: T
    private let _function: StaticString
    private let _file: StaticString
    private let _line: UWord
}



public struct DateTime {

    let year: UInt16
    let month: UInt8
    let day: UInt8
    let hour: UInt8
    let min: UInt8
    let sec: Double
    
    private init(tval:timeval, localtime:Bool = true) {
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
    
    public static func localTime(tval:timeval) -> DateTime {
        return DateTime(tval: tval, localtime: true)
    }
    
}


public class Logger {

    public enum Severity: Int {
        case None, Error, Warning, Info, Debug, Trace
    }


    public class Format {
    }
    
    private let _category :StaticString
    private let _executionContext:ExecutionContext

    
    public var dateFormat: (timeval:timeval)-> String

    public var logLevel = Severity.Error
    

    
    public init(category: StaticString, verbosity: Severity,
        executionContext: ExecutionContext = AsyncExecutionContext(queue: dispatch_queue_create("logger_sync_queue", nil)!),
        dateTimeFormatter:(tval:timeval) -> String = Logger.defaultDateTimeFormatter)
    {
        _category = category
        self.logLevel = verbosity
        self._executionContext = executionContext
        self.dateFormat = dateTimeFormatter
    }
    
    convenience public init(_ category: StaticString) {
        self.init(category: category, verbosity: Severity.Info, dateTimeFormatter: Logger.defaultDateTimeFormatter)
    }
    
    
    
    private static func defaultDateTimeFormatter(tval:timeval) -> String {
        let t = DateTime.localTime(tval)
        let s:String = String(format: "%hu-%.2hhu-%.2hhu %.2hhu:%.2hhu:%07.4f", t.year, t.month, t.day, t.hour, t.min, t.sec)
        return s
    }
    
    private func writeEvent<T>(event: Event<T>) {
        let gcd_queue = event._gcd_queue == nil ? "" : event._gcd_queue!
        _executionContext.execute {
            print("\(self.dateFormat(timeval: event._timeStamp)) [\(event._threadId)][\(gcd_queue)] \(event._function): \(event._message)")
        }
    }
    
    public func writeln<T>(@autoclosure object: ()-> T) {
        writeEvent(Event(category: _category, severity: Severity.None, message: object()))
    }
    

    
    
    
    public func Error<T>(@autoclosure object: ()-> T, file: StaticString = __FILE__, function: StaticString = __FUNCTION__, line: UWord = __LINE__) {
        if (self.logLevel.rawValue > Severity.None.rawValue) {
            writeEvent(Event(category: self._category, severity: Severity.Error, message: object(), function: function, file: file, line: line))
        }
    }

    public func Warning<T>(@autoclosure object: ()-> T, file: StaticString = __FILE__, function: StaticString = __FUNCTION__, line: UWord = __LINE__) {
        if (self.logLevel.rawValue > Severity.Error.rawValue) {
            writeEvent(Event(category: self._category, severity: Severity.Warning, message: object(), function: function, file: file, line: line))
        }
    }

    public func Info<T>(@autoclosure object: ()-> T, file: StaticString = __FILE__, function: StaticString = __FUNCTION__, line: UWord = __LINE__) {
        if (self.logLevel.rawValue > Severity.Warning.rawValue) {
            writeEvent(Event(category: self._category, severity: Severity.Info, message: object(), function: function, file: file, line: line))
        }
    }
 
    public func Debug<T>(@autoclosure object: ()-> T, file: StaticString = __FILE__, function: StaticString = __FUNCTION__, line: UWord = __LINE__) {
        if (self.logLevel.rawValue > Severity.Info.rawValue) {
            writeEvent(Event(category: self._category, severity: Severity.Debug, message: object(), function: function, file: file, line: line))
        }
    }

    public func Trace<T>(@autoclosure object: ()-> T, file: StaticString = __FILE__, function: StaticString = __FUNCTION__, line: UWord = __LINE__) {
        if (self.logLevel.rawValue > Severity.Debug.rawValue) {
            writeEvent(Event(category: self._category, severity: Severity.Trace, message: object(), function: function, file: file, line: line))
        }
    }
    
    
}


