import Foundation




public protocol Cancelable {
    func cancel()
}

extension dispatch_queue_t {

    public func async(f: () -> ()) {
        dispatch_async(self, f)
    }


    public func sync(f: () -> ()) {
        dispatch_sync(self, f)
    }


    public func after(delay: Double, tolerance: Double = 0.0, f: () -> ()) -> Cancelable {
        let timer = Timer(delay: delay, tolerance: tolerance, queue: self) { timer in
            f()
        }
        timer.resume()
        return timer
    }


}

public func schedule_after(delay: Double, tolerance: Double = 0.0, f: () -> ()) {
    dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0).after(delay, tolerance: tolerance, f: f)
}