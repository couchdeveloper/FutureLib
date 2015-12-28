# FutureLib

![Status](https://img.shields.io/badge/Status-Alpha-orange.svg) [![GitHub license](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0) [![Swift 2.0](https://img.shields.io/badge/Swift-2.0-orange.svg?style=flat)](https://developer.apple.com/swift/)  ![Platforms OS X | iOS](https://img.shields.io/badge/Platforms-OS%20X%20%7C%20iOS-lightgray.svg?style=flat)  [![Carthage Compatible](https://img.shields.io/badge/Carthage-Compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

--------------------------------
**FutureLib** is a pure Swift 2 library implementing Futures & Promises inspired by
[Scala](http://docs.scala-lang.org/overviews/core/futures.html), [Promises/A+](https://github.com/promises-aplus/promises-spec) and a cancellation concept with `CancellationRequest` and `CancellationToken` similar to [Cancellation in Managed Threads](https://msdn.microsoft.com/en-us/library/dd997364.aspx) in Microsoft's Task Parallel Library (TPL).

FutureLib helps you to write concise and comprehensible code to implement correct asynchronous programs which include error handling and cancellation.

## Features
- Employs the asynchronous "non-blocking" style.
- Supports composition of tasks.
- Supports a powerful cancellation concept by means of "cancellation tokens".
- Greatly simplifies error handling in asynchronous code.
- Continuations can be specified to run on a certain "Execution Context".

--------------------------

## Contents
[TOC]

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
<!-- END doctoc generated TOC please keep comment here to allow auto update -->



## Getting Started

The following sections show how to use futures and promises in short examples.  A more detailed description can be found in the [documentation](file://documentation.md).


### What is a Future?

A future represents the _eventual result_ of an _asynchronous_ function.  Say, the computed value is of type `T`,  the asynchronous function _immediately_ returns a value of type `Future<T>`:

```swift
func doSomethingAsync() -> Future<Int> 
```

When the function returns, the returned future is not yet _completed_ - but there executes a background task which computes the value and eventually _completes_ the future. We can say, the returned future is a _placeholder_ for the result of the asynchronous function. 

The underlying task may fail. In this case the future will be _completed_ with an _error_. Note however, that the asynchronous function itself does not throw an error.

> A Future is a placeholder for the result of a computation which is not yet finished. Eventually it will be completed with _either_ the _value_ or an _error_.

In order to represent that kind of result, a future uses an enum type `Result<T>` internally. `Result` is a kind of variant, or _discriminated union_ which contains _either_ a value _or_ an error. 

> In FutureLib, `Result<T>` can contain either a value of type `T` or a value conforming to the Swift protocol `ErrorType`.

Usually, we obtain a future from an asynchronous function like `doSomethingAsync()` above. In order to retrieve the result, we register a _continuation_ which gets called when the future completes. However, as a client we cannot complete a future ourself - it's some kind of read-only.

> A Future is of _read only_. We cannot complete it directly, we can only retrieve its result - once it is completed.

So, how does the underlying task complete the future? Well, this will be accomplished with a _Promise_:



### What is a Promise?

With a Promise we can complete a future. Usually, a Promise will be created and eventually resolved by the underlying task. A promise has one and only one _associated_ future. A promise can be _resolved_ with either the computed value or an error. Resolving a promise with a `Result` immediately completes its associated future with the same value.

> A Promise will be created and resolved by the underlying task. Resolving a Promise immediately completes its Future accordingly.

The sample below shows how to use a promise and how to return its associated future to the caller.  In this sample, a function with a completion handler will be wrapped into a function that returns a future:

```swift
public func doSomethingAsync -> Future<Int> {
	// First, create a promise:
	let promise = Promise<Int>()

    // Start the asynchronous work:
    doSomethingAsyncWithCompletion { (data, error) -> Void in
	    if let e = error {
            promise.reject(e)
        }
        else {
            promise.fulfill(data!)
        }
    }

	// Return the pending future:
    return promise.future!
}
```


### Retrieving the Value of the Future

Once we have a future, how do we obtain the value - respectively the error - from the future?  And _when_ should we attempt to retrieve it?

Well, it should be clear, that we can obtain the value only _after_ the future has been completed with _either_ the computed value _or_ an error.


There are blocking and non-blocking variants to obtain the result of the future. The blocking variants are rarely used:

#### Blocking Access

```func value() throws -> T ```

Method `value ` blocks the current thread until the future is completed. If the future has been completed with success it returns the success value of its result, otherwise it throws the error value.
The use of this method is discouraged however since it blocks the current tread. It might be merely be useful in Unit tests or other testing code.

#### Non-Blocking Access

  ```  var result: Result<ValueType>? ```

If the future is completed returns its result, otherwise it returns `nil`. The property is sometimes useful when it's known that the future is already completed.

The most flexible and useful approach to retrieve the result in a non-blocking manner is to use _Continuations_:

#### Non-Blocking Access with Continuations

In order to retrieve the result from a future in a non-blocking manner we can use a _Continuation_. A continuation is a closure which will be _registered_ with certain methods defined for that future. The continuation will be called when the future has been completed.

There are several variants of continuations, including those that are registered with_combinators_ which differ in their signature. Most continuations have a parameter _result_ as `Result<T>`,  _value_ as `T` or _error_ as `ErrorType` which will be set accordingly from the future's result and passed as an argument.

### Basic Methods Registering Continuations

The most basic method which registers a continuation is `onComplete`:

#### `func onComplete<U>(f: Result<T> -> U)`

Method `onComplete` registers a continuation which will be called when the future has been completed. It gets passed the _result_ as a `Result<T>` of the future as its argument:

```swift
future.onComplete { result in
    // result is of type Result<T>
}
```
where `result` is of type `Result<T>` where `T` is the type of the computed value of the function `doSomethingAsync`. _result_ may contain either a value of type `T` or an error, conforming to protocol `ErrorType`.

> Almost all methods which register a continuation are implemented in terms of `onComplete`.

There a few approaches to get the actual value of a result:

```swift
	let result:Result<Int> = ...
	switch result {
	case .Success(let value):
	    print("Value: \(value)")
	case .Failure(let error):
		print("Error: \(error)")
	}
```

The next basic methods are `onSuccess` and `onFailure`, which get called when the future completes with success respectively with an error. 


#### `func onSuccess<U>(f: T -> throws U)`

With method `onSuccess` we register a continuation which gets called when the future has been completed with success:
```swift
future.onSuccess { value in
	// value is of type T
}
```

#### `func onFailure<U>(f: T -> U)`

With `onFailure` we register a continuation which gets called when the future has been completed with an error:
```swift
future.onFailure { error in
	// error conforms to protocol `ErrorType`
}
```


### Combinators

Continuations will also be registered with _Combinators_.  A combinator is a method which returns a new future. There are quite a few combinators, most notable `map` and `flatMap` .  There are however quite a few more combinators which build upon the basic ones.

With combinators we can combine two or more futures and build more complex asynchronous patterns and programs.

#### `func map<U>(f: T throws -> U) -> Future<U>`

Method `map` returns a new future which is completed with the result of the function `f` which is applied to the success value of `self`. If `self` has been completed with an error, or if the function `f` throws and error, the returned future will be  completed with the same error. The continuation will not be called when `self` fails.

Since the return type of combinators like `map` is again a future we can combine them in various ways. For example:

```swift
fetchUserAsync(url).map { user in
    print("User: \(user)")
    return user.name()
}.map { name in
    print("Name: \(name)")
}
.onError { error in
    print("Error: \(error)")
}
```

Note, that the mapping function will be called asynchronously with respect to the caller! In fact the entire expression is asynchronous! Here, the type of the expression above is `Void` since `onError` returns `Void`.

####  `func flatMap<U>(f: T -> Future<U>) -> Future<U>`
Method `flatMap` returns a new future which is completed with the _eventual_ result of the function `f` which is applied to the success value of `self`. If `self` has been completed with an error the returned future will be  completed with the same error. The continuation will not be called when `self` fails.

An example:

```swift
fetchUserAsync(url).flatMap { user in
    return fetchImageAsync(user.imageUrl)
}.map { image in
	dispatch_async(dispatch_get_main_queue()) {
	    self.image = image
	}
}
.onError { error in
    print("Error: \(error)")
}
```

Note: there are simpler ways to specify the execution environment (here the main dispatch queue) where the continuation should be executed.


#### `func recover(f: ErrorType throws -> T) -> Future<T>`

Returns a new future which will be completed with `self`'s success value or with the return value of the mapping function `f` when `self` fails.

#### `func recoverWith(f: ErrorType -> Future<T>) -> Future<T>`

Returns a new future which will be completed with `self`'s success value or with the deferred result of the mapping function `f` when `self` fails.

Usually, `recover` or `recoverWith` will be needed when a subsequent operation will be required to be processed even when the previous task returned an error. We then "recover" from the error by returning a suitable value which may indicate this error or use a default value for example:

```swift
let future = computeString().recover { error in
    NSLog("Error: \(error)")
    return ""
}
```




#### `func filter(predicate: T throws -> Bool) -> Future<T>`
Method `filter` returns a new future which is completed with the success value of `self` if the function `predicate` applied to the value returns `true`. Otherwise, the returned future will be completed with the error `FutureError.NoSuchElement`. If `self` will be completed with an error or if the predicate throws an error, the returned future will be completed with the same error.

```swift 
computeString().filter { str in
	
}
```

#### `func transform<U>(s: T throws -> U, f: ErrorType -> ErrorType)-> Future<U>`

Returns a new Future which is completed with the result of function `s` applied to the successful result of `self` or with the result of function `f` applied to the error value of `self`. If `s` throws an error, the returned future will be completed with the same error.


#### `func zip(other: Future<U>) -> Future<(T, U)>`
Returns a new future which is completed with a tuple of the success value of `self` and `other`. If `self` or other fails with an error, the returned future will be completed with the same error.


### Sequences of Futures and Extensions to Sequences

An extension method which can be applied to any sequence type is `traverse`:

#### `func traverse<U>(task: T -> Future<U>) -> Future<[U]>`

For any sequence of `T`, the asynchronous method `traverse` applies the function `task` to each value of the sequence (thus, getting a sequence of tasks) and then completes the returned future with an array of `U`s once all tasks have been completed successfully.

```swift 
let ids = [14, 34, 28]
ids.traverse { id in
    return fetchUser(id)
}.onSuccess { users in
    // user is of type [User]
}
```

The tasks will be executed concurrently, unless an _execution context_ is specified which defines certain concurrency constraints (e.g., restricting the number of concurrent tasks to a fixed number).


#### `func sequence() -> Future<[T]>`

For a sequence of futures `Future<T>` the method `sequence` returns a new future `Future<[T]>` which is completed with an array of `T`, where each element in the array is the success value of the corresponding future in `self` in the same order.

```swift
[
    fetchUser(14),
    fetchUser(34),
    fetchUser(28)
].sequence { users in
    // user is of type [User]
}


```

#### `func results() -> Future<Result<T>>`

For a sequence of futures `Future<T>`, the method `result` returns a new future which is completed with an array of `Result<T>`, where each element in the array corresponds to the result of the future in `self` in the same order.

```swift
[
    fetchUser(14),
    fetchUser(34),
    fetchUser(28)
].results { results in
    // results is of type [Result<User>]
}
```

#### `func fold<U>(initial: U, combine T throws -> U) -> Future<U>`

For a sequence of futures `Future<T>` returns a new future `Future<U>`  which will be completed with the result of the function `combine` repeatedly applied to  the success value for each future in `self` and the accumulated value  initialized with `initial`.

That is, it transforms a `SequenceOf<Future<T>>` into a `Future<U>` whose result is the combined value of the success values of each future.

The `combine` method will be called asynchronously in order with the futures  in `self` once it has been completed with success. Note that the future's  underlying task will execute concurrently with each other and may complete  in any order.

### Examples for Combining Futures


Given a few asynchronous functions which return a future:

```swift
func task1() -> Future<Int> {...}
func task2(value: Int = 0) -> Future<Int> {...}
func task3(value: Int = 0) -> Future<Int> {...}
```
##### Combining Futures - Example 1a

Suppose we want to chain them in a manner that the subsequent task gets the result from the previous task as input. Finally, we want to print the result of the last task:

```swift
task1().flatMap { arg1 in
    return task2(arg1).flatMap { arg2 in
        return task3(arg2).map { arg3 in
            print("Result: \(arg3)")
        }
    }
}
```

##### Combining Futures - Example 1b
When the first task finished successfully, execute the next task - and so force:

```swift
task1()
.flatMap { arg1 in
    return task2(arg1)
}
.flatMap { arg2 in
    return task3(arg2)
}
.map { arg3 in
    print("Result: \(arg3)")
}
```
The task are independent on each other but they require that they will be called in order.

##### Combining Futures - Example 1c

This is example 1b, in a more concise form:

```swift
task1()
.flatMap(f: task2)
.flatMap(f: task3)
.map {
    print("Result: \($0)")
}
```

##### Combining Futures - Example 2

Now, suppose we want to compute the values of task1, task2 and task3 concurrently and then pass all three computed values as arguments to task4:
```swift
func task4(arg1: Int, arg2: Int, arg3: Int) -> Future<Int> {...}

let f1 = task1()
let f2 = task2()
let f3 = task3()

f1.flatMap { arg1 in
    return f2.flatMap { arg2 in
        return f3.flatMap { arg3 in
            return task4(arg1, arg2:arg2, arg3:arg3)
            .map { value in
                print("Result: \(value)")
            }
        }
    }
}
```

Unfortunately, we cannot easily simplify the code like in the first example. We can improve it when we apply certain operators that work like syntactic sugar which make the code more understandable. Other languages have special constructs like [do-notation](https://en.wikibooks.org/wiki/Haskell/do_notation) or [For-Comprehensions](http://docs.scala-lang.org/tutorials/FAQ/yield.html) in order to make such constructs more comprehensible.



### Specify an Execution Context where callbacks will execute

The continuations registered above will execute concurrently and we should not make any assumptions about the execution environment where the callbacks will be eventually executed. However, there's a way to explicitly specify this execution environment by means of an _Execution Context_ with an additional parameter for all methods which register a continuation:

As an example, define a GCD based execution context which uses an underlying serial dispatch queue where closures will be submitted asynchronously on the specified queue with the given quality of service class:
```swift
let queue = dispatch_queue_create("sync queue", 
dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL,
			QOS_CLASS_USER_INITIATED, 0))

let ec = GCDAsyncExecutionContext(queue)
```

Then, pass this execution context to the parameter `ec`:
```swift
future.onSucces(ec: ec) { value in
	// we are executing on the queue "sync queue"
	let data = value.0    
	let response = value.1
	...
}
```

When the future completes, it will now submit the given closure asynchronously to the dispatch queue.

If we now register more than one continuation with this execution context, all continuations will be submitted virtually at the same time when the future completes, but since the queue is serial, they will be serially executed in the order as they have been submitted.

Note that continuations will _always_ execute on a certain  _Execution Context_.  If no execution context is explicitly specified a _private_ one is implicitly given, which means we should not make any assumptions about where and when the callbacks execute.

An execution context can be created in various flavors and for many concrete underlying execution environments. See more chapter "Execution Context".


### Cancelling a Continuation

Once a continuation has been registered, it can be "unregistered" by means of a _Cancellation Token_:

First create a _Cancellation Request_ which we can send a "cancel" signal when required:
```swift
let cr = CancellationRequest()
```

Then obtain the cancellation token from the cancellation request, which the future can monitor to test whether there is a cancellation requested:
```swift
let ct = cr.token
```
This cancellation token will be passed as an additional parameter to any function which register a continuation. We can share the same token for multiple continuations or anywhere where a cancellation token is required:

```swift
future.onSucces(ct: ct) { value in
	...
}
future.onFailure(ct: ct) { error in
	...
}
```

Internally, the future will register a "cancellation handler" with the cancellation token for each continuation will be registered with a cancellation token. The cancellation handler will be called when there is a cancellation requested. A cancellation handler simply "unregisters" the previously registered continuation. If this happens and if the continuation takes a `Result<T>` or an `ErrorType` as parameter, the continuation will also be called with a corresponding error, namely a `CancellationError.Cancelled` error.

We may later request a cancellation with:
```swift
cr.cancel()
```

When a cancellation has been requested and the future is not yet completed, a continuation which takes a success value as parameter, e.g. a closure registered with`onSuccess`, will be unregistered and subsequently deallocated.

On the other hand, a continuation which takes a `Result` or an error value as parameter, e.g. continuations registered with`onComplete` and `onFailure`, will be first unregistered and then called with a corresponding argument, that is with an error set to `CancellationError.Cancelled`.  If the future is not yet completed, it won't be completed due to the cancellation request, though. That is, when the completion handler executes, the corresponding future may not yet be completed:
```swift
future.onFailure(ct: ct) { error in
	if CancellationError.Cancelled.isEqual(error) {
		// the continuation has been cancelled
	}
}
```

`CancellationRequest` and `CancellationToken` build a powerful and flexible approach to implement a cancellation mechanism which can be leveraged in other domains and other libraries as well.


### Wrap an asynchronous function with a completion handler into a function which returns a corresponding future

Traditionally, system libraries and third party libraries pass the result of an asynchronous function via a completion handler. Using futures as the means to pass the result is just another alternative. However, in order unleash the power of futures for these functions with a completion handler, we need to convert the function into a function which returns a future. This is entirely possible  - and also quite simple.

Here, the `Promise` enters the scene!

As an example, use an extension for `NSURLSession` which performs a very basic GET request using a `NSURLSessionDadtaTask` which can be cancelled by means of a cancellation token. Without focussing too much on a "industrial strength" implementation it aims to demonstrate how to use a promise - and also a cancellation token:

Get a future from an asynchronous function that returns a `Future<T>`

```swift
func get(
    url: NSURL,
    cancellationToken: CancellationTokenType = CancellationTokenNone())
    -> Future<(NSData, NSHTTPURLResponse)>
{
	// First, create a Promise with the appropriate type parameter:
    let promise = Promise<(NSData, NSHTTPURLResponse)>()

	// Define the session and its completion handler. If the request
	// failed, we reject the promise with the given error - otherwise
	// we fulfill it with a tuple of NSData and the response:
    let dataTask = self.dataTaskWithURL(url) {
    (data, response, error) -> Void in
        if let e = error {
            promise.reject(e)
        }
        else {
            promise.fulfill(data!, response as! NSHTTPURLResponse)
            // Note: "real" code would check the data for nil and
            // response for the correct type.
        }
    }

	// In case someone requested a cancellation, cancel the task:
    cancellationToken.onCancel {
        dataTask.cancel() // this will subsequently fail the task with
                          // a corresponding error, which will be used
                          // to reject the promise.
    }

	// start the task
    dataTask.resume()

	// Return the associated future from the new promise above. Note that
	// the property `future` returns a weak Future<T>, so we need to
	// explicitly unwrap it before we return it:
    return promise.future!
}
```

Now we can use it as follows:
```swift
let cr = CancellationRequest()
session.get(url, cr.token)
.map { (data, response) in
	guard 200 == response.statusCode else {
		throw URLSessionError.InvalidStatusCode(code: response.statusCode)
	}
	guard response.MIMEType != nil &&
	!response.MIMEType!.lowercaseString.hasPrefix("application/json") else {
        throw URLSessionError.InvalidMIMEType(mimeType: response.MIMEType!)
    }
    ...
    let json = ...
    return json
}
```

## Documentation
TBD


## Installation

### Carthage

> **Note:** Carthage only supports dynamic frameworks which are supported in Mac OS X and iOS 8 and later.

1. Follow the instruction [Installing Carthage](https://github.com/Carthage/Carthage) to install Carthage on your system.
2. Follow the instructions [Adding frameworks to an application](https://github.com/Carthage/Carthage), while adding  
    `github couchdeveloper/FutureLib`
    to the file `Cartfile.private`.		


### CocoaPods
TBD

