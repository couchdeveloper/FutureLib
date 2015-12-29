//: [Previous](@previous)

//:# TaskQueue Demo

//: A `TaskQueue` is an execution context which can execute _tasks_ concurrently with a set limit of maximum number if concurrent tasks. What `NSOperartionQueue` is for `NSOperation`s, `TaskQueue` is for _tasks_.   
//:   
//: A _task_ is an asynchronous closure or function which returns a `Future`: 
//:  
//: `() -> Future<T>`  

import Foundation
import FutureLib
import XCPlayground
XCPlaygroundPage.currentPage.needsIndefiniteExecution = true


//: The following function defines a task that runs for the specidfied duration. It will stop also when a cancellation has been requested:
func doSomething(c: Character, duration: Double, cancellationToken ct: CancellationToken) -> Future<Int> {
    let promise = Promise<Int>()
    let taskTimer = Timer(delay: 0, interval: 0.2, tolerance: 0.01, cancellationToken: ct) { t in
        promise // keep a reference to the promise in order to pevent that it is being deinitialized prematurely.
        print("\(c)")
    }
    let cancelId = ct.onCancel {
        print("task cancelled")
        promise.reject(CancellationError.Cancelled)
    }
    let finishedTimer = Timer(delay: duration, tolerance: 0.01, cancellationToken: ct) { t in
        taskTimer.cancel()
        ct.unregister(cancelId)
        print("task \(c) finished")
    }
    taskTimer.resume()
    finishedTimer.resume()
    print("task \(c) started")
    return promise.future!
}

//:### Create a `TaskQueue` which will execute at maximum two tasks concurrently:
let taskQueue = TaskQueue(maxConcurrentTasks: 2)
let cr = CancellationRequest()

//: Enqueue the 1st task. The task will be immediateley executed since the number of active tasks was less than `maxConcurrentTask`.
taskQueue.enqueue {
    doSomething("1", duration: 6.0, cancellationToken: cr.token)
}

//: Enqueue the 2nd task. The task will be immediateley executed since the number of active tasks was less than `maxConcurrentTask`.
taskQueue.enqueue {
    doSomething("2", duration: 3.0, cancellationToken: cr.token)
}

//: Enqueue the 3rd task. The task will be deferred, since the number of active tasks is now equal `maxConcurrentTask`. When one of the previous enqueued task will finish, this task starts to execute.
taskQueue.enqueue { 
    doSomething("3", duration: 2.0, cancellationToken: cr.token)
}



//: [Next](@next)
