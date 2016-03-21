//
//  TaskQueue+ExecutionContext.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//


/**
 Extends a TaskQueue to become an Execution Context.
*/
extension TaskQueue: ExecutionContext {

    /** 
     Submit the closure `f` for execution on the task queue. The block will be
     asynchronously submitted to `self.queue`.
     
     - parameter f: The closure.
    */
    public func execute(f: ()->()) {
        GCDAsyncExecutionContext(self.queue).execute(f)
    }

    /**
     Asynchronously submit the task `task` for execution on the task queue. The
     task will be immediately started when the number of concurrent running tasks 
     is less than the maximum number of concurrent tasks. Otherwise, it will be 
     enqueued in a FIFO queue and waits there until the concurrent number of tasks
     decreases to less than the maximum and it's its turn to be started.
     
     When the task will be stated, the function `start` will be called with the
     returned future as its argument.
     
     - parameter task: The asynchronous task with signature `() throws -> Future<T>`.
     - parameter start: A closure which will be called when the task will be started
     with the tasks's returned future as its argument.
     */
    public func schedule<T>(task: () throws -> Future<T>, start: Future<T> -> ()) {
        self.enqueue {
            var future: Future<T>?
            do {
                future = try task()
            }
            catch let error {
                future = Future<T>.failed(error)
            }
            start(future!)
            return future!
        }
    }
    
}
