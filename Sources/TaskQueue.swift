//
//  TaskQueue.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import Dispatch

/**
 A TaskQueue is a FIFO queue where _tasks_ can be enqueued. The tasks will be
 executed in order up to `maxConcurrentTasks` concurrently. When a task has been
 finished it will be dequeued.
 A _task_ is simply a closure which returns a `Future`.
*/

public class TaskQueue {

    /**
     The type of the closure which defines a task.
    */
    public typealias TaskType = () -> FutureBaseType

    public let queue: dispatch_queue_t

    private var _maxConcurrentTasks: UInt = 1
    private var _concurrentTasks: UInt = 0
    private let _group = dispatch_group_create()
    private let _syncQueue = dispatch_queue_create("task_queue.sync_queue", DISPATCH_QUEUE_SERIAL)
    private var _suspended = false

    /**
     Designated initializer.

     - parameter maxConcurrentTasks: The number of tasks which can be executed
     concurrently.
     - parameter queue: The dispatch queue where to start the tasks. This should
     be a serial dispatch queue.
    */
    public init(maxConcurrentTasks: UInt = 1,
        queue: dispatch_queue_t =
        dispatch_queue_create("task_queue.queue", DISPATCH_QUEUE_SERIAL)) {
        self.queue = queue
        _maxConcurrentTasks = maxConcurrentTasks
        dispatch_set_target_queue(queue, _syncQueue)
    }

    /**
     Enqueues the given task and returns immediately.

     The task will be executed when the current number
     of active tasks is smaller than `maxConcurrentTasks`.

     - parameter task: The task which will be enqueued.
    */
    public final func enqueue(task: TaskType) {
        dispatch_async(queue) {
            self._enqueue(task)
        }
    }


    private final func _enqueue(task: TaskType) {
        dispatch_group_enter(self._group)
        _concurrentTasks += 1
        if _concurrentTasks >= _maxConcurrentTasks && !_suspended {
            _suspended = true
            dispatch_suspend(queue)
        }
        assert(_concurrentTasks <= _maxConcurrentTasks)
        let future = task()
        future.continueWith(ec: GCDAsyncExecutionContext(self._syncQueue),
            ct: CancellationTokenNone()) { _ in
            self._concurrentTasks -= 1    
            if self._concurrentTasks < self._maxConcurrentTasks && self._suspended {
                self._suspended = false
                dispatch_resume(self.queue)
            }
            dispatch_group_leave(self._group)
        }
    }

    /**
     Enqueues the given task for barrier execution and returns immediately.

     A barrier task allows you to create a synchronization point within the `TaskQueue`.
     When it encounters a barrier task, the `TaskQueue` delays the execution of
     the barrier task (or any further tasks) until all tasks enqueued before the
     barrier task finish executing. At that point, the barrier task executes by
     itself. Upon completion, the TaskQueue resumes its normal execution behavior.

     - parameter task: The task which will be enqueued as a barrier task.
     */
    public final func enqueueBarrier(task: TaskType) {
        dispatch_async(queue) {
            dispatch_suspend(self.queue)
            dispatch_group_notify(self._group, self._syncQueue) {
                let future = task()
                future.continueWith(ec: GCDAsyncExecutionContext(self._syncQueue),
                    ct: CancellationTokenNone()) { _ in
                    dispatch_resume(self.queue)
                }
            }
        }
    }


    /**
     Sets or returns the number of concurrently executing tasks.
    */
    public final var maxConcurrentTasks: UInt {
        get {
            var result: UInt = 0
            dispatch_sync(_syncQueue) {
                result = self._maxConcurrentTasks
            }
            return result
        }
        set (value) {
            dispatch_async(_syncQueue) {
                self._maxConcurrentTasks = value
            }
        }
    }



}
