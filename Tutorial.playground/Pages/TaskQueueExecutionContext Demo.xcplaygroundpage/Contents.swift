//: [Previous](@previous)

import Foundation
import FutureLib
import Dispatch

import XCPlayground
XCPlaygroundPage.currentPage.needsIndefiniteExecution = true


//:# TaskQueue Execution Context Demo
//: A `TaskQueue` is also an _execution context_ which can be specified as parameter to member functions for class `Future`.

//: Create a dispatch queue which will be set as argument in the `TaskQueue` constructor. This queue is the execution context where asynchronous tasks will be started and where functions and closures will be executed:
let queue = dispatch_queue_create("my_serial_queue", nil)

//: Create a TaskQueue whose maximum number of concurrent tasks is set to 1, and which uses the given queue to start the tasks and execute closures:
let ec: ExecutionContext = TaskQueue(maxConcurrentTasks: 1, queue: queue)


//: Define a simple task which takes a parameter input:
let task: (String) -> Future<String> = { input in 
    NSLog("task \(input) started")
    let promise = Promise<String>()
    let delay = dispatch_time(DISPATCH_TIME_NOW, Int64(1.0 * Double(NSEC_PER_SEC)))
    dispatch_after(delay, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)) {
        NSLog("task \(input) finished")
        promise.fulfill(input.lowercaseString)
    }
    return promise.future!
}


["A", "B", "C", "D"].forEach { name in
    NSLog("task \(name) scheduled")
    ec.schedule { // schedule returns the future from task when it has been started!
        task(name)
    }.flatMap { future in
        return future.map { value in
            NSLog("Result of task \(name): \(value)")
        }
    }
}





