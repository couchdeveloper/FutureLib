//
//  schedule_after.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import Dispatch

/**
 Implements a cancelable timer with precise timing.
 */    

internal class Timer {
    
    internal typealias TimerHandler = () -> ()
    
    /// time interval in seconds
    internal typealias TimeInterval = Double 
    
    private let _timer: DispatchSourceTimer
    
    /**
     Returns a cancelable, precise one-shot timer in _resumed_ state.
     
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
    internal static func scheduleAfter(
        _ seconds: TimeInterval, 
        queue: DispatchQueue = DispatchQueue.global(), 
        tolerance: TimeInterval = 0, 
        f: TimerHandler) -> Timer
    {
        let leeway: DispatchTimeInterval = .nanoseconds(Int(seconds * 1e9 + 0.5))
        let flags: DispatchSource.TimerFlags = seconds == 0 ? .strict : []  
        let timer = Timer(flags: flags, queue: queue) 
        timer._timer.setEventHandler {
            f()
            timer._timer.cancel()
        }
        timer._timer.scheduleOneshot(deadline: DispatchTime.now() + seconds, leeway: leeway)
        timer._timer.resume()
        return timer
    }
    
    
    private init(flags: DispatchSource.TimerFlags, queue: DispatchQueue) {
        _timer = DispatchSource.timer(flags: flags, queue: queue)
    }
    
    deinit {
        guard _timer.isCancelled else {
            fatalError("broken timer") // the Timer object has been deinitialized before the timer has fired or has been cancelled.
        }
    }
    
    /**
     Returns `True` if the timer has not yet been fired and if it is not cancelled.
     */
    internal final var isValid: Bool {
        return _timer.isCancelled
    }
    
    /**
     Cancels the timer.
     The timer handler will not be called anymore.
     */
    internal final func cancel() {
        _timer.cancel()
    }
        
}
    
    

/**
 Submits the block on the specifie queue and executed it after the specified delay.
 The delay is as accurate as possible.
 */
internal func schedule_after(_ delay: Timer.TimeInterval, queue: DispatchQueue = DispatchQueue.global(), f: () -> ()) {
    Timer.scheduleAfter(delay, queue: queue, f: f)
}
