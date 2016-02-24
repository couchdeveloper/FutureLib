//
//  schedule_after.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import Dispatch


public typealias TimeInterval = Double


/**
 An accurate timer for use in unit tests.
 */
private final class AccurateTimer {
    
    private typealias TimerHandler = () -> ()
    private typealias TimeInterval = Double
    
    
    private final let _timer: dispatch_source_t
    private final let _delay: Int64
    private final let _interval: UInt64
    private final let _leeway: UInt64
    
    private init(delay: TimeInterval, tolerance: TimeInterval = 0.0,
                 on ec: dispatch_queue_t = dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0),
                     f: TimerHandler) {
        _delay = Int64((delay * Double(NSEC_PER_SEC)) + 0.5)
        _interval = DISPATCH_TIME_FOREVER
        _leeway = UInt64((tolerance * Double(NSEC_PER_SEC)) + 0.5)
        _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, tolerance > 0 ? 0 : DISPATCH_TIMER_STRICT, DISPATCH_TARGET_QUEUE_DEFAULT)
        dispatch_source_set_event_handler(_timer) {
            dispatch_source_cancel(self._timer) // one shot timer
            dispatch_async(ec, f)
        }
    }
    
    deinit {
        cancel()
    }
    
    
    
    /**
     Starts the timer.
     
     The timer fires once after the specified delay plus the specified tolerance.
     */
    private final func resume() {
        let time = dispatch_time(DISPATCH_TIME_NOW, _delay)
        dispatch_source_set_timer(_timer, time, _interval, _leeway)
        dispatch_resume(_timer)
    }
    
    
    
    /**
     Returns `True` if the timer has not yet been fired and if it is not cancelled.
     */
    private final var isValid: Bool {
        return 0 == dispatch_source_testcancel(_timer)
    }
    
    /**
     Cancels the timer.
     */
    private final func cancel() {
        dispatch_source_cancel(_timer)
    }
    
}

/**
 Submits the block on the specifie queue and executed it after the specified delay.
 The delay is as accurate as possible.
 */
public func schedule_after(delay: TimeInterval, queue: dispatch_queue_t = dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), f: () -> ()) {
    let d = delay * Double(NSEC_PER_SEC) * 1.0e-9
    AccurateTimer(delay: d, on: queue, f: f).resume()
}