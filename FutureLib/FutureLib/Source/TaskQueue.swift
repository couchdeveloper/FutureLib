//
//  TaskQueue.swift
//  FutureLib
//
//  Created by Andreas Grosam on 09.08.15.
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import Dispatch



public class TaskQueue {
    
    public typealias TaskType = (ct: CancellationToken) -> FutureBaseType
    
    private var _maxConcurrentTasks : Int = 1
    private var _concurrentTasks : Int  = 0
    private let _sync_queue : dispatch_queue_t = dispatch_queue_create("task_queue.sync", DISPATCH_QUEUE_SERIAL)
    private let _queue : dispatch_queue_t
    private let _cancellationRequest = CancellationRequest()
    private var _suspended : Bool = false
    
    init(maxConcurrentTasks : Int = 1) {
        _maxConcurrentTasks = maxConcurrentTasks
        _queue = dispatch_queue_create("task_queue.queue", DISPATCH_QUEUE_SERIAL)
        dispatch_set_target_queue(_sync_queue, _queue)
    }
    
    
    public final func enqueue(f : TaskType) {
        dispatch_async(_queue) {
            if (!self._cancellationRequest.isCancellationRequested) {
                if (++self._concurrentTasks >= self._maxConcurrentTasks && !self._suspended) {
                    self._suspended = true
                    dispatch_suspend(self._queue)
                }
                assert(self._concurrentTasks <= self._maxConcurrentTasks)
                f(ct: self._cancellationRequest.token)
                .continueWith(on: GCDAsyncExecutionContext(self._sync_queue)) { _ in
                    if (--self._concurrentTasks < self._maxConcurrentTasks && self._suspended) {
                        self._suspended = false
                        dispatch_resume(self._queue)
                    }
                }
            }
        }
    }
    
    
    public final var maxConcurrentTasks : Int {
        get {
            var result = 0
            dispatch_sync(_sync_queue) {
                result = self._maxConcurrentTasks
            }
            return result
        }
        set (value) {
            dispatch_async(_sync_queue) {
                self._maxConcurrentTasks = value
            }
        }
    }
    
    
    public final var isCancelled : Bool {
        return _cancellationRequest.isCancellationRequested
    }
    
    public final func cancel() {
        _cancellationRequest.cancel()
    }
    
    
}



