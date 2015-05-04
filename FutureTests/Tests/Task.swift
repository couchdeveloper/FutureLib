//
//  Task.swift
//  Future
//
//  Created by Andreas Grosam on 03.11.14.
//  Copyright (c) 2014 Andreas Grosam. All rights reserved.
//

import Foundation
import Future


// private Enum - should be a nested class
private enum State<T> {
    case Pending
    case Executing
    case Success([T])
    case Failure(NSError)
    
    init() {
        self = Pending
    }
    init(_ v: T) {
        self = Success([v])
    }
    init(_ error: NSError) {
        self = Failure(error)
    }
    
}

private struct Sync {
    private static var queue_ID_key = "key"
    private static var queue_ID_value = "value"
    
    /// Returns true if the current execution context is the sync_queue
    static func on_sync_queue() -> Bool {
        //return global_on_sync_queue()
        return dispatch_get_specific(&Sync.queue_ID_key) == &Sync.queue_ID_value
    }
    
    private let sync_queue : dispatch_queue_t = {
        let q = dispatch_queue_create("task.sync_queue", DISPATCH_QUEUE_CONCURRENT)!
        dispatch_queue_set_specific(q, &Sync.queue_ID_key, &Sync.queue_ID_value, nil)
        return q
        }()
    
    func read_sync_safe(closure: ()->()) -> () {
        if Sync.on_sync_queue() {
            closure()
        }
        else {
            dispatch_sync(sync_queue, closure)
        }
    }
    func read_sync(closure: ()->()) -> () {
        dispatch_sync(sync_queue, closure)
    }
    func write_async(closure: ()->()) -> () {
        dispatch_barrier_async(sync_queue, closure)
    }
    func write_sync(closure: ()->()) -> () {
        dispatch_barrier_sync(sync_queue, closure)
    }
    
}


public class Task<T> : Cancelable
{
    typealias ValueType = T
    
    private var _state = State<T>()
    private let _sync = Sync()
    
    private var _pendingCancellationError : NSError? = nil
    
    
    init() {
    }
    
    //let label : String {get}
    //let unit : double {get}
    
    
    //func final start() -> Future<T> {}
    
    public final func start() {
        var started = false;
        _sync.write_sync() {
            switch self._state {
            case .Pending:
                self._state = State<T>.Pending
                started = true
            case .Executing, .Success, .Failure:
                return
            }
        }
        if started {
            
        }
    }
    
    var isExecuting: Bool {
        get {
            var result = false
            _sync.read_sync() {
                switch self._state {
                case .Executing: result = true
                case .Pending, .Success, .Failure: break
                }
            }
            return result
        }
    }

    var isFinished: Bool {
        get {
            var result = false
            _sync.read_sync() {
                switch self._state {
                case .Pending, .Executing: break
                case .Success, .Failure: result = true
                }
            }
            return result
        }
    }
    
    var isCancelled: Bool {
        get {
            var result = false
            _sync.read_sync() {
                result = self._pendingCancellationError != nil
            }
            return result
        }
    }
    
    
    public func cancel() -> () {
        let error = NSError(domain: "Task",
                code: -1,
                userInfo: [NSLocalizedFailureReasonErrorKey: "future cancelled"])
        cancel(error)
    }
    
    public func cancel(error:NSError) -> () {
        _sync.write_async() {
            if (self._pendingCancellationError == nil) {
                self._pendingCancellationError = error
            }
        }
    }
    
    
    
    
    private final func pendingCancellation() -> NSError? {
        var error : NSError? = nil
        _sync.read_sync() {
            error = self._pendingCancellationError
        }
        return error
    }
    
    private final func complete(value : T) {
        _sync.write_sync() {
            switch self._state {
                case .Pending: assert(false, "Succesfully completing a task while pending is not allowed."); break
                case .Executing: self._state = State<T>(value)
                case .Success, .Failure: break
            }
        }
    }
    
    private final func complete(error : NSError) {
        _sync.write_sync() {
            switch self._state {
                case .Pending, .Executing: self._state = State<T>(error)
                case .Success, .Failure: break
            }
        }
    }
    
    private final func terminate(error: NSError) -> () {
    }
    private final func terminate() -> () {
    }
    

    
    private final func nextWorkItem() -> (T?) {
        return nil
    }
    
    public func processWorkItem(work: T, f:(Result<T>) -> ()) {
    }
    
    private final func progress() -> () {
        if let error = pendingCancellation() {
            terminate(error)
        } else if let wi = nextWorkItem() {
            processWorkItem(wi) { result in
                switch result {
                case .Success: self.progress()
                case .Failure(let error): self.terminate(error)
                }
            }
        }
        else {
            terminate()
        }
    }
    


//    private func doWork() -> ()
//    {
//        if isCancelled {
//            _result = Result(NSError(domain: "Task",
//                code: -1,
//                userInfo: [NSLocalizedFailureReasonErrorKey: "task cancelled"]))
//            terminate()
//            return
//        }
//        else if (_step == _failAtStep) {
//            _result = Result(_failureReason)
//            terminate()
//            return
//        }
//        else if (_step == _workCount) {
//            _result = "Operation \(label) finished with processed : \(_workCount) item(s)."
//            terminate()
//            return
//        }
//        // dispatch another work item:
//        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_duration * NSEC_PER_SEC));
//    dispatch_after(popTime, _workerQueue, ^(void){
//    #if defined (LOG_VERBOSE)
//    printf("%p: %ld\n", self, (long)_workCount);
//    #endif
//    _step++;
//    printf("%d|", _ID);
//    //[self.promise setProgress:[NSNumber numberWithInteger:_workCount]];
//    [self doWork];
//    });
//    }

        //    - (void) start
//    {
//    if (self.isFinished || self.isExecuting) {
//    return;
//    }
//    self.isExecuting = YES;
//    [self doWork];
//    }
//    
//    - (BOOL) isCancelled {
//    return [super isCancelled];
//    }
//    - (void) cancel {
//    [super cancel];
//    }
//    
//    - (BOOL) isExecuting {
//    return _isExecuting;
//    }
//    - (void) setIsExecuting:(BOOL)isExecuting {
//    if (_isExecuting != isExecuting) {
//    [self willChangeValueForKey:@"isExecuting"];
//    _isExecuting = isExecuting;
//    [self didChangeValueForKey:@"isExecuting"];
//    }
//    }
//    
//    - (BOOL) isFinished {
//    return _isFinished;
//    }
//    - (void) setIsFinished:(BOOL)isFinished {
//    if (_isFinished != isFinished) {
//    [self willChangeValueForKey:@"isFinished"];
//    _isFinished = isFinished;
//    [self didChangeValueForKey:@"isFinished"];
//    }
//    }
//    
//    - (void) terminate {
//    self.isFinished = YES;
//    self.isExecuting = NO;
//    MyOperation_completion_t completion = self.completion;
//    self.completion = nil;
//    if (completion) {
//    id result;
//    id error;
//    if (_step == _failAtStep || self.isCancelled) {
//    result = nil;
//    error = [_result isKindOfClass:[NSError class]] ? _result : [NSError errorWithDomain:@"MyOperation" code:-1 userInfo:@{NSLocalizedFailureReasonErrorKey: _result ? _result : [NSNull null] }];
//    NSLog(@"Operation %d aborted with error %@", (int)_ID, error);
//    
//    } else {
//    result = _result;
//    error = nil;
//    }
//    dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
//    completion(result, error);
//    });
//    }
//    }

}