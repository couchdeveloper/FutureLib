//
//  ClosureRegistry.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//


internal struct Callback<T> {
    let continuation: (T) -> ()
    let id: Int
    init(id: Int, f: @escaping (T)->()) {
        self.id = id
        continuation = f
    }
}


final class Continuations<T> {
    private var _cr: ClosureRegistry<T>
    init() {
        _cr = .empty
    }
    
    func register(_ f: @escaping (T)->()) -> Int {
        return _cr.register(f)
    }
    
    func unregister(_ id: Int) -> Callback<T>? {
        return _cr.unregister(id)
    }    
    
    func resume(_ value: T) { 
        _cr.resume(value)
    }
    
    var count: Int {
        return _cr.count
    }
}



/**
 A ClosureRegistry manages closures.
 */
internal enum ClosureRegistry<T> {

    typealias CallbackType = Callback<T>

    init() {
        self = .empty
    }

    case empty
    case single((T)->())
    case multiple(ClosureRegistryMultiple<T>)

    var count: Int {
        switch self {
            case .empty: return 0
            case .single: return 1
            case .multiple(let cr): return cr.count
        }
    }

    mutating func register(_ f: @escaping (T)->()) -> Int {
        switch self {
            case .empty:
                self = .single(f)
                return 0

            case .single(let first):
                let cr = ClosureRegistryMultiple<T>(id: 0, f: first)
                self = .multiple(cr)
                return cr.register(f)

            case .multiple(let cr):
                return cr.register(f)
        }
    }

    mutating func unregister(_ id: Int) -> CallbackType? {
        switch self {
        case .empty: return nil
        case .single(let first):
            let callback = CallbackType(id: 0, f: first)
            self = .empty
            return callback
        case .multiple(let cr):
            return cr.unregister(id)
        }
    }

    func resume(_ value: T) {
        switch self {
        case .empty: break
        case .single(let f):
            f(value)
        case .multiple(let cr):
            cr.resume(value)
        }
    }

}




internal final class ClosureRegistryMultiple<T> {

    typealias CallbackType = Callback<T>

    private var _id: Int = 0
    private var _callbacks: ContiguousArray<CallbackType> = ContiguousArray()

    init() {
        _callbacks.reserveCapacity(2)
    }

    init(id: Int, f: @escaping (T)->()) {
        assert(id == 0)
        _callbacks.reserveCapacity(4)
        _callbacks.append(Callback(id: id, f: f))
    }

//    deinit { }

    final var count: Int {
        return _callbacks.count
    }

    final func register(_ f: @escaping (T)->()) -> Int {
        _id += 1
        let callback = Callback<T>(id: _id, f: f)
        _callbacks.append(callback)
        return _id
    }

    final func unregister(_ id: Int) -> CallbackType? {
        var cb: CallbackType? = nil
        if let idx = _callbacks.index(where: {$0.id == id}) {
            cb = _callbacks.remove(at: idx)
        }
        return cb
    }

    final func resume(_ value: T) {
        for c in _callbacks {
            c.continuation(value)
        }
    }

}
