# FutureLib

![Status](https://img.shields.io/badge/Status-Alpha-orange.svg)
![Swift 2.0](https://img.shields.io/badge/Swift-2.0-orange.svg?style=flat)
![Platforms OS X | iOS](https://img.shields.io/badge/Platforms-OS%20X%20%7C%20iOS-lightgray.svg?style=flat)
![Carthage Compatible](https://img.shields.io/badge/Carthage-Compatible-4BC51D.svg?style=flat)


**FutureLib** is a pure Swift 2 library implementing Futures & Promises inspired by
[Scala](http://docs.scala-lang.org/overviews/core/futures.html), [Promises/A+](https://github.com/promises-aplus/promises-spec) and a cancellation concept with `CancellationRequest` and `CancellationToken` similar to [Cancellation in Managed Threads](https://msdn.microsoft.com/en-us/library/dd997364.aspx) in Microsoft's Task Parallel Library (TPL).


## Features
- Employs the asynchronous "non-blocking" style.
- Supports composition of tasks.
- Supports a powerful cancellation concept by means of "cancellation tokens".
- Greatly simplifies error handling in asynchronous code.
- Continuations will execute on a specified _execution context_ which is used to
define the concurrency relationships.
- Provides means to abandon operations when there are no futures anymore.

## Usage

An introduction to FutureLib.

#### Obtain a Future from an asynchronous call:

For example, fetch a `User` from a remote server from a web service:

````Swift
let future = fetchUser(1234)
````

where the signature for function `fetchUser` may look as this:

````Swift
func fetchUser(userId: Int) -> Future<User>
````

Class `Future` is a generic, which has a type alias `ValueType` which equals the given type parameter.

##### Register a Continuation which will be called when the Future has been _completed_:

````Swift
future.onComplete { result in
    do {
        let user = try result.value()
        print("User: \(user)")
    }
    catch let error {
        print("Error: \(error)")
    }
}
````
A `future` becomes _completed_ when its corresponding `promise` has been either _fulfilled_ with a value or _rejected_ with an error by the underlying implementation of `fetchUser`.

The continuation is a [closure](https://developer.apple.com/library/ios/documentation/Swift/Conceptual/Swift_Programming_Language/Closures.html) which will be called when the future has been completed. Its parameter `result` is of type `Result<T>`, where `T` equals the `ValueType` of the future. In this example it's `Result<User>`. Parameter `result` contains _either_ the requested value of type `User` _or_ an error of type `ErrorType`. In the code snippet above it is shown how one can obtain the success value of the result (in this case a `User` object) and also handle a potential error.


#### Register a Continuation when the Future has been completed with success:

````Swift
future.onSucces { value in
  print("User: \(value)")
}
````
The continuation will be called only when the future's corresponding promise has been fulfilled with a value, that is a `User` in this example. The parameter `value` equals the `Future`'s `ValueType`, that is `User` in this example.

#### Register a Continuation when the Future has been completed with a failure:

````Swift
future.onError { error in
  print("Error: \(error)")
}
````
The continuation will be called only when the future's corresponding promise has been rejected with an error. The error can be any value conforming to protocol `ErrorType`.

#### Execution Context

A `Future` can have many continuations and these will be called when the future has been completed. This raises the question _where_ do they execute in relation to the calling context and in relation to any other continuation and any other code that may potentially execute concurrently. And how are potential concurrency issues solved? That's what the _Execution Context_ defines.

Each continuation will execute on its specified _execution context_. An execution context can be specified when the continuation will be registered for the future. An example of an execution context is a _dispatch queue_ - but there can be many others.

Here is an example which specifies the execution context where the continuation will execute:

#### Register a Continuation and specify the Execution Context:
````Swift
let ec = GCDAsyncExecutionContext(dispatch_get_main_queue())
future.onSucces(on: ec) { value in
  print("User: \(value)")
}
````

`GCDAsyncExecutionContext(dispatch_get_main_queue())` returns an execution context which asynchronously dispatches the continuation onto the "dispatch main queue".

> Note: Continuations SHOULD always be dispatched _asynchronously_.

Execution contexts are also used to define concurrency relationships between continuations and other code. For example, you could have many continuations which access the same shared variable (not necessarily on the same future). In this scenario one could specify an execution context which meets the required concurrency constraints - for example a suitable GCD dispatch queue.

If a execution context is not specified, a continuation will run on a private execution context which will execute in parallel to all other continuations and any other code with no constraints regarding concurrency.


#### Register a continuation with a cancellation option:

 Oftentimes, at some time in a program the result of a pending future isn't required anymore and the registered closure should not run when the future becomes completed.

 Thus, there's a way where we can _unregister_ a continuation by means of a `Cancellation Token` which also frees the closure and all its captured references.

 ````Swift
 let cr = CancellationRequest()
 let future = fetchUser(465677)
 future.onComplete(cancellationToken: cr.token) { result in
     do {
         let user = try result.value()
         print("User: \(user)")
     }
     catch let error {
         print("Error: \(error)")  // prints: Error: Error Domain=NSURLErrorDomain
                                   // Code=-999 "cancelled" UserInfo=0x7ff911c76e50 {...}
     }
 }

 ````
 And later, somewhere else:
 ````Swift
 cr.cancel()
 ````
 Assuming the future is still in a pending state when a cancellation has been requested with `cr.cancel()`, the effect is that the continuation will be _unregistered_ from the future and then called with an argument `result` which has been initialized with a with the special error: `CancellationError.Cancelled` error - even though the future is not yet completed.

Likewise, a continuation registered with `onError` will be invoked with an argument error which equals `CancellationError.Cancelled` - even though the future is not yet completed:
````Swift
let cr = CancellationRequest()
future.onError(cancellationToken: cr.token) { error in
  print("Error: \(error)") // prints: Error: Error Domain=NSURLErrorDomain
                           // Code=-999 "cancelled" UserInfo=0x7ff911c76e50 {...}
}
cr.cancel()
````


In contrast, a continuation registered with `onSuccess` will not be called when it has been unregistered:
````Swift
let cr = CancellationRequest()
fetchUser(465677)
.onSuccess(cancellationToken: cr.token) { result in
  print("User: \(value)") // will not be called
}
cr.cancel()
````


When looking closer to the samples above, we might spot an issue: what happens with the asynchronously executing network request? Does it get cancelled in some way? The answer is "No"  - but we will find a better solution later on.

#### Live time of a Future

If a future has at least one continuation it will not deinit. If a future has no continuations and if there is no strong reference to the future elsewhere, the future will be "deinited" and freed.

All continuations will be automatically removed after the future has been completed.
Any individual continuation can be unregistered by means of a cancellation token.

Take a look at the following example:

````Swift
fetchUser(465677)
.onSuccess(cancellationToken: cr.token) { result in
  print("User: \(value)")
}
````
The future returned from `fetchUser` and its continuation will stay alive up until it's pending or the continuation has been cancelled.

When the future will be completed with success, its sole continuation will run and subsequently removed. Since there is also no other reference to the future it will be deinited.

When the future will be completed with an error, its sole continuation will be removed. Since there is also no other reference to the future it will be deinited.

When the cancellation token has been cancelled the sole continuation will be removed. Since there is also no other reference to the future it will be deinited.



#### A Future's associated Promise

A future cannot be created directly. In order to obtain a future one needs to create a `Promise` first. We then obtain the future - the so called _root future_ - as follows:

````Swift
let promise = Promise<String>()
let future = promise.future!
````
Usually, creating a promise and eventually resolving that promise is the responsibility of the task or operation which produces the result. Once you have a future, other "children" futures can be created by means of certain methods defined in class `Future`.

Only a _root future_ has an associated promise.

When a root future will be deinited its associated promise will still exist. The promise will be owned by the corresponding task which is responsible to resolve the promise. Resolving a promise whose associated future does not exist anymore is not a fatal error, though. Doing so just issues a diagnostics message.

That is, a root future can be destroyed even though there is still an associated promise and also a running task which is calculating the result.




#### Creating a Promise:

````Swift
let pendingPromise = Promise<String>()
let fulfilledPromise = Promise<String>(value: "OK")
let rejectedPromise = Promise<String>(error: MyError.Failed)
````

#### Wrap an asynchronous method with completion handler into a method returning a `Future`:
````Swift
func fetchUser(userId: Int) -> Future<[User]> {
  let promise = Promise<[User]>();
  fetchUserWithId(userId) { (user, error) in
    if let e = error {
      promise.reject(e)
    }
    else {
      promise.fulfill(user!)
    }
  }
  return promise.future!
}
````

#### Register a Handler which gets called when the root future deinits:

An asynchronous operation may have more then _one_ consumers for its result. Thus, a certain consumer should not explicitly cancel the asynchronous task just because _it_ is not interested in the result anymore. The others might still have a strong interest in eventually obtaining the result. On the other hand, if _all_ consumers abandon their interest in the result, the operation isn't required to run until completion wasting resources. Instead, it should be cancelled.

So, how can we accomplished this? There is an easy approach:

An asynchronous task can setup a handler using method `onRevocation` which gets invoked when the root future deinits:
````Swift
func fetchUsers(url: NSURL) -> Future<[User]> {
  let promise = Promise<[User]>();
  ...
  promise.onRevocation {
      ... // cancel the task
  }
  return promise.future!
}
````

The root future only deinits if it has no continuations and if there are no more strong references elsewhere.

Lets assume we have two consumers:

````Swift
let rootFuture = fetchUser(123)

rootFuture.onComplete(cancellationToken: ct1) { result in
  ...
}
rootFuture.onComplete(cancellationToken: ct2) { result in
  ...
}
rootFuture = nil
````
Once we set `rootFuture` to nil and cancel both `ct1` and `ct2` the rootFuture has no continuations anymore and there's also no strong reference elsewhere. Thus, `rootFuture` will  be deinited.
