//: [Previous](@previous)

import Foundation
import AppKit
import FutureLib

import XCPlayground
XCPlaygroundPage.currentPage.needsIndefiniteExecution = true


//: # NSProgress Demo
//: Demonstrates a sample implementation of a task whose progress can be tracked utilizing `NSProgress`.


//: ## Class Task
//: In order to track progress of a task, we require a task to expose its "progress" via a property, `progress`.
//:
//: A parent progress _may_ be _implicitly_ given by a call-site through using _thread local storage_. This example
//: does not use thread local storage, instead it requires the init function to provide additional parameters where
//: the parent progress and its "pending unit count" value can be passed to the task instance.
//: > Note: Here, the parameter `workUnits` in the `init` function just defines the _number of steps_ this task reports its progress. It does not have an effect on the progress at all. A real task implementation would use other means to report progress resulting in a reasonable number of steps. 
class Task {
    private var timer: FutureLib.Timer!
    private let ec = GCDAsyncExecutionContext(dispatch_queue_create("task sync_queue", DISPATCH_QUEUE_SERIAL))
    private let promise: Promise<Int64>
    
    let progress: NSProgress

    init(workUnits: Int64) {
        self.promise = Promise()
        self.progress = NSProgress(totalUnitCount: workUnits)
        self.progress.cancellable = false
        self.progress.pausable = false
        self.timer = Timer(delay: 0, interval: 0.1, tolerance: 0, ec: ec) { timer in
            self.progress.completedUnitCount += 1
            if (self.progress.completedUnitCount >= self.progress.totalUnitCount) {
                timer.cancel()
                self.promise.fulfill(self.progress.completedUnitCount)
            }
        }
    }
    
    func resume() -> Future<Int64> {
        timer.resume()
        return self.promise.future!
    }
    
}

//: ## Helper Class ProgressObserver
//: `ProgressObserver` is a convenient helper class which observes changes of the progress' `fractionCompleted` property via KVO.
class ProgressObserver: NSObject {
    let progress: NSProgress
    var handler: (Double) -> () = { fractionCompleted in print("ProgressObserver: \(fractionCompleted)") }
    
    init(progress: NSProgress, handler: (Double) -> ()) {
        self.progress = progress
        self.handler = handler
        super.init()
        self.progress.addObserver(self, forKeyPath: "fractionCompleted", options: [.Initial], context: nil)
    }
    
    deinit {
        self.progress.removeObserver(self, forKeyPath: "fractionCompleted", context: nil)
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if let progress = object as? NSProgress {
            self.handler(progress.fractionCompleted)
        }
    }
    
}


//: ## Objective
//: Track the process of three tasks which execute sequentially


//: Create three tasks and - for the sake of the sample - each take the same duration to finish:
let task1 = Task(workUnits: 100)
let task2 = Task(workUnits: 100)
let task3 = Task(workUnits: 100)

//: Next, for each task define a value `weight` which reflects the _supposed_ amount of work in relation to each other:
let weight1: Int64 = 50
let weight2: Int64 = 30
let weight3: Int64 = 20
//: Since a client does not really know the exact durations a tasks take to complete a priori, it should be clear that the weight values are just informed guesses. Ideally,


//: Then, create the "parent progress", tracking the progress form task1, taks2 and task3 whose total amount of units equals the sum of the weight for each task:
let parentProgress = NSProgress(totalUnitCount: weight1 + weight2 + weight3)
//: Here, task1 takes 50 out of 100, task3 takes 30 out of 100 and task3 takes 20 out of 100 unit counts. The sum equals 100 unit count.

//: Next, assign the parent progress the three "child progresses". This yields a parent progress which tracks the sequential execution of the three tasks:
parentProgress.addChild(task1.progress, withPendingUnitCount: weight1)
parentProgress.addChild(task2.progress, withPendingUnitCount: weight2)
parentProgress.addChild(task3.progress, withPendingUnitCount: weight3)




//: Add a Live view
//: > Note: Open the Assistan View "Timeline" pane in order to view the progress indicator!
let frame = CGRect(x: 0, y: 0, width: 200, height: 50)
let containerView = NSView(frame: frame)
let progressView = NSProgressIndicator(frame: frame)
containerView.addSubview(progressView)
progressView.minValue = 0.0
progressView.maxValue = 1.0
progressView.style = .BarStyle
progressView.indeterminate = false
progressView.sizeToFit()

XCPlaygroundPage.currentPage.liveView = containerView
progressView.startAnimation(nil)

//: Now, the parent progress' `fractionCompleted` property may be bound to an UI element displaying the progress for the three tasks.
//: Create the observer, which prints the the current progress to the console:
let observer = ProgressObserver(progress: parentProgress, handler: { value -> () in
    dispatch_async(dispatch_get_main_queue()) {
        //print(value)
        value
        progressView.doubleValue = value
    }
})



//: Start the task in sequence:
task1.resume().flatMap { _ -> Future<Int64> in
    print("task 1 finished")
    return task2.resume().flatMap { _ -> Future<Int64> in
        print("task 2 finished")
        return task3.resume()
    }
}.onComplete { _ in
    dispatch_async(dispatch_get_main_queue()) {
        progressView.stopAnimation(nil)
        print("task 3 finished")
    }
    
}


//: [Next](@next)
