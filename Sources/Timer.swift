//
//  Timer.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import Dispatch

/**
 Implements a cancelable timer with precise timing.
*/
internal extension DispatchTimeInterval {
    
    init(seconds: Timer.TimeInterval) {
        self = .nanoseconds(Int((seconds * 1e9) + 0.5))
    }
     
    func isZero() -> Bool {
        switch self {
        case .seconds(let value): return value == 0
        case .milliseconds(let value): return value == 0
        case .microseconds(let value): return value == 0
        case .nanoseconds(let value): return value == 0
        }
    }
}

public enum Deadline {
    case now    
    case after(seconds: TimeInterval)
    case wallClockTime(time: timespec)
}


public class Timer {
    
    public typealias TimerHandler = () -> ()
    public typealias TimeInterval = Double


    private let _timer: DispatchSourceTimer

    /**
     Returns a cancelable, precise one-shot timer in resumed state.
     
     Setting a tolerance for a timer allows it to fire later than the scheduled fire
     date, improving the ability of the system to optimize for increased power savings
     and responsiveness. The timer may fire at any time between its scheduled fire date
     and the scheduled fire date plus the tolerance. The timer will not fire before the
     scheduled fire date. The default value is zero, which means no additional tolerance
     is applied.
     
     As the user of the timer, you will have the best idea of what an appropriate tolerance
     for a timer may be. A general rule of thumb, though, is to set the tolerance to at
     least 10% of the interval, for a repeating timer. Even a small amount of tolerance
     will have a significant positive impact on the power usage of your application.
     The system may put a maximum value of the tolerance.
     
     - parameter deadline: The delay in seconds or the wall clock time after the timer will fire.
     - parameter tolerance: A tolerance in seconds the fire date can deviate. Must be positive.
     - parameter on:  The execution on which to execute the block.
     - parameter f:  The closure to submit.
     - return: An initialized Timer object.
     */
    @discardableResult
    public static func scheduleOneShot(
        deadline: Deadline, 
        on ec: ExecutionContext = GCDAsyncExecutionContext(), 
        tolerance: TimeInterval = 0, 
        f: TimerHandler) -> Timer
    {
        let leeway = DispatchTimeInterval(seconds: tolerance)
        let flags: DispatchSource.TimerFlags = leeway.isZero() ? .strict : []  
        let timer = Timer(flags: flags) 
        timer._timer.setEventHandler {
            ec.execute(f)
            _ = timer // prevent the timer to deinitialize prematurely.
        }    
        switch deadline {
        case .now: 
            timer._timer.scheduleOneshot(deadline: DispatchTime.now(), leeway: leeway)
        case .after(let seconds):
            timer._timer.scheduleOneshot(deadline: DispatchTime.now() + seconds, leeway: leeway)
        case .wallClockTime(let time):
            timer._timer.scheduleOneshot(wallDeadline: DispatchWallTime(time: time), leeway: leeway)
        }        
        timer._timer.resume()
        return timer
    }
    
    /**
     Returns a cancelable, precise one-shot timer in resumed state.
     
     Setting a tolerance for a timer allows it to fire later than the scheduled fire
     date, improving the ability of the system to optimize for increased power savings
     and responsiveness. The timer may fire at any time between its scheduled fire date
     and the scheduled fire date plus the tolerance. The timer will not fire before the
     scheduled fire date. The default value is zero, which means no additional tolerance
     is applied.
     
     As the user of the timer, you will have the best idea of what an appropriate tolerance
     for a timer may be. A general rule of thumb, though, is to set the tolerance to at
     least 10% of the interval, for a repeating timer. Even a small amount of tolerance
     will have a significant positive impact on the power usage of your application.
     The system may put a maximum value of the tolerance.
     
     - parameter seconds: The delay in seconds after the timer will fire.
     - parameter tolerance: A tolerance in seconds the fire date can deviate. Must be positive.
     - parameter on:  The execution on which to execute the block.
     - parameter f:  The closure to submit.
     - return: An initialized Timer object.
     */    
    @discardableResult
    public static func scheduleOneShotAfter(
        _ seconds: TimeInterval, 
        on ec: ExecutionContext = GCDAsyncExecutionContext(), 
        tolerance: TimeInterval = 0, 
        f: TimerHandler) -> Timer
    {
        let leeway = DispatchTimeInterval(seconds: tolerance)
        let flags: DispatchSource.TimerFlags = leeway.isZero() ? .strict : []  
        let timer = Timer(flags: flags) 
        timer._timer.setEventHandler {
            ec.execute(f)
            _ = timer // prevent the timer to deinitialize prematurely 
        }    
        timer._timer.scheduleOneshot(deadline: DispatchTime.now() + seconds, leeway: leeway)
        timer._timer.resume()
        return timer
    }

    
    /**
     Returns a cancelable, precise repeating timer in resumed state.
     
     Setting a tolerance for a timer allows it to fire later than the scheduled fire
     date, improving the ability of the system to optimize for increased power savings
     and responsiveness. The timer may fire at any time between its scheduled fire date
     and the scheduled fire date plus the tolerance. The timer will not fire before the
     scheduled fire date. The default value is zero, which means no additional tolerance
     is applied.
     
     As the user of the timer, you will have the best idea of what an appropriate tolerance
     for a timer may be. A general rule of thumb, though, is to set the tolerance to at
     least 10% of the interval, for a repeating timer. Even a small amount of tolerance
     will have a significant positive impact on the power usage of your application.
     The system may put a maximum value of the tolerance.
     
     - parameter deadline: The delay in seconds or the wall clock time after the timer will fire.
     - parameter tolerance: A tolerance in seconds the fire date can deviate. Must be positive.
     - parameter on:  The execution on which to execute the block.
     - parameter f:  The closure to submit.
     - return: An initialized Timer object.
     */
    @discardableResult
    public static func scheduleRepeating(
        deadline: Deadline = .now, 
        interval: TimeInterval,
        on ec: ExecutionContext = GCDAsyncExecutionContext(), 
        tolerance: TimeInterval = 0, 
        f: TimerHandler) -> Timer
    {
        let leeway = DispatchTimeInterval(seconds: tolerance)
        let dispatchInterval = DispatchTimeInterval(seconds: interval)
        let flags: DispatchSource.TimerFlags = leeway.isZero() ? .strict : []  
        let timer = Timer(flags: flags) 
        timer._timer.setEventHandler {
            _ = timer // prevent the timer to deinitialize prematurely
            ec.execute(f)
        }    
        switch deadline {
        case .now: 
            timer._timer.scheduleRepeating(deadline: DispatchTime.now(), interval: dispatchInterval, leeway: leeway)
        case .after(let seconds):
            timer._timer.scheduleRepeating(deadline: DispatchTime.now() + seconds, interval: dispatchInterval, leeway: leeway)
        case .wallClockTime(let time):
            timer._timer.scheduleRepeating(wallDeadline: DispatchWallTime(time: time), interval: dispatchInterval, leeway: leeway)
        } 
        timer._timer.resume()
        return timer
    }

    

    
    private init(flags: DispatchSource.TimerFlags) {
        _timer = DispatchSource.timer(flags: flags)
    }
    
    deinit {
        cancel()
    }
    
    /**
     Returns `True` if the timer has not yet been fired and if it is not cancelled.
     */
    public final var isValid: Bool {
        return _timer.isCancelled
    }
    
    /**
     Cancels the timer.
     The timer handler will not be called anymore.
     */
    public final func cancel() {
        _timer.cancel()
    }
    
    

}
