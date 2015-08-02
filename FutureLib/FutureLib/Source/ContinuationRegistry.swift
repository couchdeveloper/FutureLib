//
//  ContinuationRegistry.swift
//  ContinuationRegistry
//
//  Created by Andreas Grosam on 01.08.15.
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//



internal struct Callback<T> {
    let continuation : T -> ()
    let id : Int32
    init(id: Int32, f: T->()) {
        self.id = id
        continuation = f
    }
}

/**
    A ContinuationRegistry manages continuations registered for a future.
*/
internal enum ContinuationRegistry<T> {
    
    typealias CallbackType = Callback<T>
    
    init() {
        self = Empty
    }
    
    case Empty
    case Single(T->())
    case Multiple(ContinuationRegistryMultiple<T>)
    
    var count : Int {
        switch self {
            case .Empty: return 0
            case .Single: return 1
            case .Multiple(let cr): return cr.count
        }
    }
    
    mutating func register(f:T->()) -> Int32 {
        switch self {
            case .Empty:
                self = Single(f)
                return -1;
            
            case .Single(let first):
                let cr = ContinuationRegistryMultiple<T>(id: -1, f:first)
                self = Multiple(cr)
                return cr.register(f)
            
            case .Multiple(let cr):
                return cr.register(f)
        }
    }
    
    mutating func unregister(id: Int32) -> CallbackType? {
        switch self {
        case .Empty: return nil
        case .Single(let first):
            let callback = CallbackType(id: -1, f: first)
            self = Empty
            return callback
        case .Multiple(let cr):
            return cr.unregister(id)
        }
    }
    
    func run(value: T) {
        switch self {
        case .Empty: break
        case .Single(let f):
            f(value)
        case .Multiple(let cr):
            cr.run(value)
        }
    }
        
}




internal final class ContinuationRegistryMultiple<T> {
    
    typealias CallbackType = Callback<T>
    
    private var _id : Int32 = 0
    private var _callbacks : ContiguousArray<CallbackType> = ContiguousArray()
    
    init() {
        _callbacks.reserveCapacity(2)
    }
    
    init(id: Int32, f:T->()) {
        assert(id < 0)
        _callbacks.reserveCapacity(4)
        _callbacks.append(Callback(id: id,f: f))
    }
    
    deinit {
        //assert(_callbacks.count == 0)
    }
    
    var count : Int {
        return _callbacks.count
    }
    
    func register(f:T->()) -> Int32 {
        let id = ++_id;
        let callback = Callback<T>(id: id, f:f)
        _callbacks.append(callback)
        return id
    }
    
    func unregister(id: Int32) -> CallbackType? {
        var cb : CallbackType? = nil
        if let idx = _callbacks.indexOf({$0.id == id}) {
            cb = _callbacks.removeAtIndex(idx)
        }
        return cb
    }
    
    func run(value: T) {
        for c in _callbacks {
            c.continuation(value)
        }
    }
    
}

