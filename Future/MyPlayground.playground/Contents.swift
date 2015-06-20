//: Playground - noun: a place where people can play

import Cocoa
import Future




let futureLogger = Log
futureLogger.logLevel = Logger.Severity.Info


//let Log = Logger(category: "Playground", verbosity: Logger.Severity.Info)

let promise = Promise<String>()



func run() {
    let future = promise.future!
    
    let mq = dispatch_get_main_queue()
    future.then() { s -> String in
        //Log.writeln("=")
        return s
    }
    .then() { s -> String in
        //Log.writeln("==")
        return s
    }
    .then() { s -> String in
        //Log.writeln("===")
        return s
    }
    .then() { s -> String in
        //Log.writeln("====")
        return s
    }
    .onSuccess() { s -> () in
        Log.writeln("*****")
    }
}

run()

Log.writeln("*****")
promise.fulfill("OK")
//promise.reject(NSError(domain: "Test", code: -1, userInfo: nil))



let runLoop = NSRunLoop.currentRunLoop()
runLoop.run()
