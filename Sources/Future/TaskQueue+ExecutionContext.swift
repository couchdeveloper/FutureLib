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

    public func execute(f: ()->()) {
        GCDAsyncExecutionContext(self.queue).execute(f)
    }

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
