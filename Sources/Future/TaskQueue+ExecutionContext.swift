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
     Asynchronously submits the closure `f` for execution on the TaskQueue's queue. 
     The closure will be directly submitted to `self.queue`. That is, the closure 
     will _not_ be enqueued into `self` and property `maxConcurrentTasks` will not 
     be changed nor honored.
     
     - parameter f: The closure.
    */
    public func execute(_ f: ()->()) {
        GCDAsyncExecutionContext(self.queue).execute(f)
    }

    /**
     Enqueues the task `task` for execution on the task queue. The task will be 
     started when the number of concurrent running tasks is less than the maximum 
     number of concurrent tasks. 
     
     When the task has been started and has returned its future, the function `onStart` 
     will be called with the returned future as its argument.
     
     - parameter task: The asynchronous task with signature `() throws -> Future<T>`.
     - parameter onStart: A closure which will be called when the task will be started
     with the task's returned future as its argument.
     */
    public func schedule<T>(_ task: () throws -> Future<T>, onStart: (Future<T>) -> ()) {
        self.enqueue {
            var future: Future<T>?
            do {
                future = try task()
            }
            catch let error {
                future = Future<T>.failed(error)
            }
            onStart(future!)
            return future!
        }
    }
    
}
