//
//  Logger.swift
//  Future
//
//  Created by Andreas Grosam on 01.01.15.
//  Copyright (c) 2015 Andreas Grosam. All rights reserved.
//

import Foundation



internal func currentDateTimeString(format:String) -> String {
    return dateTimeString(time(UnsafeMutablePointer<time_t>()), format)
}

internal func dateTimeString(t:time_t, format: String) -> String {
    let maxSize: Int = 64
    var buffer: [Int8] = [CChar](count: Int(maxSize), repeatedValue: 0)
    var t_tmp = t;
    let length = strftime(&buffer, maxSize, format, localtime(&t_tmp));
    assert(length > 0)
    let s = String.fromCString(buffer)
    return s!
}



private class Event<T> {
    
    init(category: StaticString, severity: Logger.Severity, message: T, function: StaticString = "", file: StaticString = "" , line: UWord = 0) {
        _category = category
        _severity = severity
        _message = message
        _function = function
        _file = file
        _line = line
    }
    
    
    init(message: T, severity : Logger.Severity = Logger.Severity.None) {
        _message = message
        _severity = severity
    }
    
    
    private let _timeStamp = time(UnsafeMutablePointer<time_t>())
    private let _threadId = pthread_self()
    private var _category: StaticString = ""
    private var _severity: Logger.Severity
    private var _message: T
    private var _function: StaticString = ""
    private var _file: StaticString = ""
    private var _line: UWord = 0
}



public class Logger {

    public enum Severity: Int {
        case None, Error, Warning, Info, Debug, Message
    }


    public class Format {
    }

    
    private let _category :StaticString;

    var DateTimeFormatString = "%Y-%m-%d %H:%M:%S" // "%Y-%m-%d %H:%M:%S %z"
    var LogLevel = Severity.Error
    
    
    public init(_ category: StaticString) {
        _category = category
    }
    
    public init(category: StaticString, verbosity: Severity, dateTimeFormatString: String = "%Y-%m-%d %H:%M:%S") {
        _category = category
        self.LogLevel = verbosity
        self.DateTimeFormatString = dateTimeFormatString
    }
    
    
    private func writeln<T>(event: Event<T>) {
        let timeString = dateTimeString(event._timeStamp, "%Y-%m-%d %H:%M:%S")
        println("\(timeString) [\(event._threadId)] \(event._function): \(event._message)");
    }
    
    public func writeln<T>(object: T) {
        writeln(Event(category: _category, severity: Severity.None, message: object))
    }
    

    
    
    
    public func Error<T>(object: T, file: StaticString = __FILE__, function: StaticString = __FUNCTION__, line: UWord = __LINE__) {
        if (self.LogLevel.rawValue > Severity.None.rawValue) {
            writeln(Event(category: self._category, severity: Severity.Error, message: object, function: function, file: file, line: line))
        }
    }

    public func Warning<T>(object: T, file: StaticString = __FILE__, function: StaticString = __FUNCTION__, line: UWord = __LINE__) {
        if (self.LogLevel.rawValue > Severity.Error.rawValue) {
            writeln(Event(category: self._category, severity: Severity.Warning, message: object, function: function, file: file, line: line))
        }
    }

    public func Info<T>(object: T, file: StaticString = __FILE__, function: StaticString = __FUNCTION__, line: UWord = __LINE__) {
        if (self.LogLevel.rawValue > Severity.Warning.rawValue) {
            writeln(Event(category: self._category, severity: Severity.Info, message: object, function: function, file: file, line: line))
        }
    }
 
    public func Debug<T>(object: T, file: StaticString = __FILE__, function: StaticString = __FUNCTION__, line: UWord = __LINE__) {
        if (self.LogLevel.rawValue > Severity.Info.rawValue) {
            writeln(Event(category: self._category, severity: Severity.Debug, message: object, function: function, file: file, line: line))
        }
    }

    public func Message<T>(object: T, file: StaticString = __FILE__, function: StaticString = __FUNCTION__, line: UWord = __LINE__) {
        if (self.LogLevel.rawValue > Severity.Debug.rawValue) {
            writeln(Event(category: self._category, severity: Severity.Message, message: object, function: function, file: file, line: line))
        }
    }
    
    
}


