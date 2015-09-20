//
//  Timer.swift
//  FutureLib
//
//  Created by Andreas Grosam on 09.08.15.
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import Dispatch


public class Timer {
    
    public typealias TimerHandler = (Timer) -> ()
    public typealias TimeInterval = Double
    
    
    private let _timer : dispatch_source_t
    private let _interval : Int64
    private let _leeway : UInt64
    
    
    /**
        Initalizes a cancelable, one-shot timer in suspended state.

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


        - parameter: delay The delay in seconds after the timer will fire

        - parameter: queue  The queue on which to submit the block.

        - parameter: block  The block to submit. This parameter cannot be NULL.

        - parameter: tolearance A tolerance in seconds the fire data can deviate. Must be
        positive.

        - return: An initialized Timer object.
    */
    public init(delay : TimeInterval, tolerance : TimeInterval, queue : dispatch_queue_t, f:TimerHandler)
    {
        _interval = Int64((delay * Double(NSEC_PER_SEC)) + 0.5)
        _leeway = UInt64((tolerance * Double(NSEC_PER_SEC)) + 0.5)
        _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
        
        dispatch_source_set_event_handler(_timer) {
            dispatch_source_cancel(self._timer); // one shot timer
            f(self)
        }
    }

    
    deinit {
        dispatch_source_cancel(_timer);
    }
    


    /**
        Starts the timer.

        The timer fires once after the specified delay plus the specified tolerance.
    */
    public final func start() {
        let time = dispatch_time(DISPATCH_TIME_NOW, _interval)
        dispatch_source_set_timer(_timer, time, DISPATCH_TIME_FOREVER /*one shot*/, _leeway);
        dispatch_resume(_timer);
    }

    /**
        Cancels the timer.

        The timer becomes invalid and its block will not be executed.
    */
    public final func cancel() {
        dispatch_source_cancel(_timer);
    }

    /**
        Returns `True` if the timer has not yet been fired and it is not cancelled.
    */
    public final func isValid() -> Bool
    {
        return 0 == dispatch_source_testcancel(_timer);
    }

}

