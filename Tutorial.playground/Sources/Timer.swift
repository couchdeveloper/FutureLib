import Dispatch


public class Timer : Cancelable {

    public typealias TimerHandler = (Timer) -> ()


    private let _timer: dispatch_source_t
    private let _delay: Int64
    private let _interval: UInt64
    private let _leeway: UInt64


    /**
     Initializes a cancelable, one-shot timer in suspended state.

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

     - parameter: tolerance A tolerance in seconds the fire data can deviate. Must be
     positive.

     - parameter: queue  The dispatch queue on which to execute the block.

     - parameter: f  The closure to submit.


     - return: An initialized Timer object.
     */
    public init(delay d: Double, tolerance t: Double,
        queue q: dispatch_queue_t = DISPATCH_TARGET_QUEUE_DEFAULT,
        f: TimerHandler)
    {
        _delay = Int64((d * Double(NSEC_PER_SEC)) + 0.5)
        _interval = DISPATCH_TIME_FOREVER
        _leeway = UInt64((t * Double(NSEC_PER_SEC)) + 0.5)
        _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, q);
        dispatch_source_set_event_handler(_timer) {
            dispatch_source_cancel(self._timer); // one shot timer
            f(self)
        }
    }



    /**
     Initializes a cancelable, periodic timer in suspended state.

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

     - parameter: interval The interval in seconds after the timer will fire

     - parameter: tolerance A tolerance in seconds the fire data can deviate. Must be
     positive.

     - parameter: queue  The dispatch queue on which to execute the block.

     - parameter: f  The closure to submit.

     - return: An initialized Timer object.
     */
    public init(delay d: Double, interval i: Double, tolerance t: Double,
        queue q: dispatch_queue_t = DISPATCH_TARGET_QUEUE_DEFAULT,
        f: TimerHandler)
    {
        _delay = Int64((d * Double(NSEC_PER_SEC)) + 0.5)
        _interval = UInt64((i * Double(NSEC_PER_SEC)) + 0.5)
        _leeway = UInt64((t * Double(NSEC_PER_SEC)) + 0.5)
        _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, q);
        dispatch_source_set_event_handler(_timer) {
            f(self)
        }
    }


    deinit {
        cancel()
    }



    /**
     Starts the timer.

     The timer fires once after the specified delay plus the specified tolerance.
     */
    public final func resume() {
        let time = dispatch_time(DISPATCH_TIME_NOW, _delay)
        dispatch_source_set_timer(_timer, time, _interval, _leeway);
        dispatch_resume(_timer);
    }



    /**
     Returns `True` if the timer has not yet been fired and if it is not cancelled.
     */
    public final var isValid: Bool  {
        return 0 == dispatch_source_testcancel(_timer);
    }

    /**
     Cancels the timer.
     */
    public final func cancel() {
        dispatch_source_cancel(_timer);
    }

}
