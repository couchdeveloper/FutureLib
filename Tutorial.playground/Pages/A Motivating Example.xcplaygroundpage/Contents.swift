//: [Previous](@previous)
//: ## Why do we need futures?
//:
//: ### A motivating example
//:
//: Suppose, there is an image hosting site which stores images made by registered users. A user can be "followed by" one or more other users. Each user can upload a large amout of imgages. 
//:
//: **Your objective:**
//:
//: 1. Fetch all immages from your followers and store them locally.
//: 2. Since this may potentially take a significant time, provide a means to cancel the operation.
//: 3. Additionally, ensure that not more than _four_ concurrent network requests are active.
//: 4. Find a robust and correct implementation.
//: 5. Should be implemented in less than 15 lines of code. Yep - less than 15! (network code and support code does not count)
//:   
//: **Already given:**
//: 1. An API call which returns the ids of your friends as an array of ids:   
//:    `func fetchFriends() -> Future<[Int]>`    
//:
//: 2. An API call which fetches an image from the server and stores it locally in a file and returns the file path:   
//:    `func fetchImage(url: String) -> Future<String>`
//:
//: 3. An API call to fetch a user:   
//:    `func fetchUser(id: Int) -> Future<User>`   
//:
//: > The above network functions just simulate a network request - they are just "mocks". It's not the purpose of this demo to implement these method as real network requests.
//:   
//: #### We could solve this challenge using `NSOperationQueue` and `NSOperation` but ...
//: If we had just the system frameworks available, we would implement this challenge utilizing `NSOperation` and `NSOperationQueue`. When doing this, however, we will very quickly face a few problems, which turnes out, are hard to solve: first, in order to implement cancellation, we require to create three subclasses of `NSOperation`, namely `FetchFollowersOperation`, `FetchUserOperation` and `FetchImageOperation`. We have to find a correct implementation of a "thread-safe" subclass of `NSOperation` - which is actually surprisingly elaborated and difficult. The next problem we encounter is, that we need a way to pass the result of the first to the second, and the second to the third operation. To be honest, I actually have no idea how this can be accomplished in an _elegant_ and _concise_ approach. A robust and correct implementation may require at least two hundred lines of code.
//:

//: #### Utilizing FutureLib
import FutureLib
import Foundation
import XCPlayground
XCPlaygroundPage.currentPage.needsIndefiniteExecution = true

//: The model classes `User`and `Image` are already given:
struct User {
    let id: Int
    let recentImageUrls: [String]
    init (_ id: Int) {
        self.id = id
        recentImageUrls = (0..<arc4random_uniform(6)).map {"api/images/\(id)/\($0)"}
    }
}

struct Image {
    let imageUrl: String
    init (_ url: String) {
        imageUrl = url
    }
}

// The first API call which fetches the ids of all followers of the signed-in user:
func fetchFollowers() -> Future<[Int]> {
    NSLog("start fetching followers...")
    return Promise.resolveAfter(1.0) {
        NSLog("finished fetching followers.")
        return [Int](1...10)
    }.future!
}

// Given a user ID, fetch a user:
func fetchUser(id: Int) -> Future<User> {
    NSLog("start fetching user[\(id)]...")
    return Promise.resolveAfter(1.0) {
        NSLog("finished fetching user[\(id)].")
        return User(id)
    }.future!
}

// Given a URL fetch the image and store it to a file and return the file path:
func fetchImage(url: String) -> Future<String> {
    NSLog("start fetching image[\(url)]...")
    return Promise.resolveAfter(4.0) {
        NSLog("finished fetching image[\(url)].")
        let components = url.componentsSeparatedByString("/")
        return "file:///var/tmp/images/\(components[components.count-2])/image-\(components[components.count-1]))"
    }.future!
}


//: Now, the function `downloadRecentImagesFromFollowers` implements the complete task:
//:
//: The following asynchronous function `downloadRecentImagesFromMyFollowers` already *almost* does what we have listed in our requirements above - with just a few lines of code. That is, it fetches all followers, then for each follower it fetches the most recent images and stores it locally. When finished, it completes its returned future with an array of array of file paths, grouped by the user id, where the downloaded images are located.
func downloadRecentImagesFromFollowers() -> Future<[[String]]> {
    return fetchFollowers().flatMap { userIds in
        userIds.traverse { userId -> Future<[String]> in
            fetchUser(userId).flatMap { user in
                user.recentImageUrls.traverse { url in
                    return fetchImage(url)
                }
            }
        }
    }
}

//: Print each image, once `downloadRecentImagesFromMyFollowers()` finished successfully:
downloadRecentImagesFromFollowers().map { arrayImages in
    arrayImages.flatten().forEach { print($0) }
}.wait()



//: What's still missing is, that we cannot cancel this function yet. Once started, we need to wait until it is finished - well, not really: FutureLib provides an extremely convenient approach to implement cancellation:

//: In order to implement cancellation in this case, we pass a cancellation token to the innermost continuation. This is completely sufficient. If a cancellation has been requested, the innermost continuation will be unregistered and then called with a cancellation error. This in turn will complete all dependend futures with the same error. Additionally, any continuation will be deinitialized. This in turn deinitializes the future returned from underlying tasks. When this future will be deinitialized, the taks will be noticed and subsequently aborts its operation. In this case, this is just the timer - a real implemenation performing a network request can be easily implemented to behave exactly the same as well.
print("\n\n========================")
print("\n\nDemonstrate cancellation")
func downloadRecentImagesFromFollowers2(ct: CancellationTokenType) -> Future<[[String]]> {
    let ret: Future<[[String]]> = fetchFollowers().flatMap { userIds in
        userIds.traverse { userId -> Future<[String]> in
            fetchUser(userId).flatMap { user in
                user.recentImageUrls.traverse(ct: ct) { url in
                    return fetchImage(url)
                }
            }
        }
    }
    return ret
}

let cr = CancellationRequest()
let future2 = downloadRecentImagesFromFollowers2(cr.token).map { arrayImages in
    arrayImages.flatten().forEach { print($0) }
}

//: Later, if we need to cancel for some reason, we call `cancel`:
DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(3000)) {
    cr.cancel()
}
future2.onFailure { error in
    print("Error: \(error)")
}

future2.wait()

print("\n\n========================")
print("\n\nDemonstrate execution context")


//: Still, we are not yet finished: tasks started with the `traverse` method will execute concurrently, no matter how many. However, we want to limit the maximum number of requests to four. We need two "execution contexts" which limit the maximum number of concurrent tasks, which we pass the `traverse` method as argument. A `TaskQueue` exists specifically for that purpose. This will limit the maximum number of concurrent network requests:
let ec1 = TaskQueue(maxConcurrentTasks: 4)
let ec2 = TaskQueue(maxConcurrentTasks: 4)

func downloadRecentImagesFromFollowers3(ct: CancellationTokenType) -> Future<[[String]]> {
    let ret: Future<[[String]]> = fetchFollowers().flatMap { userIds in
        userIds.traverse(ec: ec1) { userId -> Future<[String]> in
            fetchUser(userId).flatMap { user in
                user.recentImageUrls.traverse(ec: ec2, ct: ct) { url in
                    return fetchImage(url)
                }
            }
        }
    }
    return ret
}

let cr3 = CancellationRequest()
downloadRecentImagesFromFollowers3(cr3.token).map { arrayImages in
    arrayImages.flatten().forEach { print($0) }
}
.onFailure { error in
        print("Error: \(error)")
}



//: [Next](@next)
