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

    /// Returns the dispatch queue where enqueued tasks will be started.
    public let queue: DispatchQueue

    private var _maxConcurrentTasks: UInt = 1
    private var _concurrentTasks: UInt = 0
    private let _group = DispatchGroup()
    private let _syncQueue = DispatchQueue(label: "task_queue.sync_queue", attributes: DispatchQueueAttributes.serial)
    private var _suspended = false

    /**
     Designated initializer.

     - parameter maxConcurrentTasks: The number of tasks which can be executed
     concurrently.
     - parameter queue: The dispatch queue where to start the tasks. This should
     be a serial dispatch queue.
    */
    public init(maxConcurrentTasks: UInt = 1,
        queue: DispatchQueue =
        DispatchQueue(label: "task_queue.queue", attributes: DispatchQueueAttributes.serial)) {
        self.queue = queue
        _maxConcurrentTasks = maxConcurrentTasks
        queue.setTarget(queue: _syncQueue)
    }

    /**
     Enqueues the given task and returns immediately.

     The task will be executed when the current number
     of active tasks is smaller than `maxConcurrentTasks`.

     - parameter task: The task which will be enqueued.
    */
    public final func enqueue(_ task: TaskType) {
        queue.async {
            self._enqueue(task)
        }
    }


    private final func _enqueue(_ task: TaskType) {
        self._group.enter()
        _concurrentTasks += 1
        if _concurrentTasks >= _maxConcurrentTasks && !_suspended {
            _suspended = true
            queue.suspend()
        }
        assert(_concurrentTasks <= _maxConcurrentTasks)
        let future = task()
        _ = future.continueWith(ec: GCDAsyncExecutionContext(self._syncQueue),
            ct: CancellationTokenNone()) { _ in
            self._concurrentTasks -= 1    
            if self._concurrentTasks < self._maxConcurrentTasks && self._suspended {
                self._suspended = false
                self.queue.resume()
            }
            self._group.leave()
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
    public final func enqueueBarrier(_ task: TaskType) {
        queue.async {
            self.queue.suspend()
            self._group.notify(queue: self._syncQueue) {
                let future = task()
                _ = future.continueWith(ec: GCDAsyncExecutionContext(self._syncQueue),
                    ct: CancellationTokenNone()) { _ in
                    self.queue.resume()
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
            _syncQueue.sync {
                result = self._maxConcurrentTasks
            }
            return result
        }
        set (value) {
            _syncQueue.async {
                self._maxConcurrentTasks = value
            }
        }
    }



}
