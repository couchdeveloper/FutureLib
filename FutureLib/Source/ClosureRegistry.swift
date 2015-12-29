//
//  ClosureRegistry.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//



internal struct Callback<T> {
    let continuation: T -> ()
    let id: Int
    init(id: Int, f: T->()) {
        self.id = id
        continuation = f
    }
}

/**
 A ClosureRegistry manages closures.
 */
internal enum ClosureRegistry<T> {

    typealias CallbackType = Callback<T>

    init() {
        self = Empty
    }

    case Empty
    case Single(T->())
    case Multiple(ClosureRegistryMultiple<T>)

    var count: Int {
        switch self {
            case .Empty: return 0
            case .Single: return 1
            case .Multiple(let cr): return cr.count
        }
    }

    mutating func register(f: T->()) -> Int {
        switch self {
            case .Empty:
                self = Single(f)
                return 0;

            case .Single(let first):
                let cr = ClosureRegistryMultiple<T>(id: 0, f: first)
                self = Multiple(cr)
                return cr.register(f)

            case .Multiple(let cr):
                return cr.register(f)
        }
    }

    mutating func unregister(id: Int) -> CallbackType? {
        switch self {
        case .Empty: return nil
        case .Single(let first):
            let callback = CallbackType(id: 0, f: first)
            self = Empty
            return callback
        case .Multiple(let cr):
            return cr.unregister(id)
        }
    }

    func resume(value: T) {
        switch self {
        case .Empty: break
        case .Single(let f):
            f(value)
        case .Multiple(let cr):
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

    init(id: Int, f: T->()) {
        assert(id == 0)
        _callbacks.reserveCapacity(4)
        _callbacks.append(Callback(id: id,f: f))
    }

//    deinit { }

    final var count: Int {
        return _callbacks.count
    }

    final func register(f: T->()) -> Int {
        let id = ++_id;
        let callback = Callback<T>(id: id, f: f)
        _callbacks.append(callback)
        return id
    }

    final func unregister(id: Int) -> CallbackType? {
        var cb: CallbackType? = nil
        if let idx = _callbacks.indexOf({$0.id == id}) {
            cb = _callbacks.removeAtIndex(idx)
        }
        return cb
    }

    final func resume(value: T) {
        for c in _callbacks {
            c.continuation(value)
        }
    }

}
