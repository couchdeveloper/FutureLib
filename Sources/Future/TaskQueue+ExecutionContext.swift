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

    public func schedule<U, F: FutureType where F.ValueType == U>(task: () -> F, start: (F)->()) {
        self.enqueue {
            let f = task()
            start(f)
            return f
        }
    }
}
