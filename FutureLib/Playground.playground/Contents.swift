//: Playground - noun: a place where people can play

import Foundation
import Cocoa
import FutureLib





enum GetDataError : ErrorType {
    case ContentIsNil
    case ResponseIsNil
    case ErrorResponse(response: NSHTTPURLResponse, message: String)
    case Error(message: String)
}


extension NSURLSession {
    
    public func getData(
        url: NSURL,
        cancellationToken: CancellationTokenType = CancellationTokenNone(),
        allowedStatusCodes: AnySequence<Int> = AnySequence([200]))
        -> Future<(NSData, NSHTTPURLResponse)>
    {
        let promise = Promise<(NSData, NSHTTPURLResponse)>()
        let dataTask: NSURLSessionDataTask = self.dataTaskWithURL(url) { (data, response, error) -> Void in
            if let e = error {
                promise.reject(e)
            }
            else {
                if response == nil { fatalError("Error: expected a URLResponse") }
                let httpResponse = response as! NSHTTPURLResponse
                if (allowedStatusCodes.contains(httpResponse.statusCode)) {
                    if data == nil { fatalError("Error: expected content") }
                    promise.fulfill(data!, httpResponse)
                }
                else {
                    var message: String?
                    let encodingName = response?.textEncodingName
                    if let charset = encodingName {
                        let ns_encoding = CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding(charset))
                        message = String(data: data!, encoding: ns_encoding)
                    }
                    if message == nil  {
                        message = ""
                    }
                    promise.reject(GetDataError.ErrorResponse(response: httpResponse, message: message!))
                }
            }
        }
        cancellationToken.onCancel {
            dataTask.cancel()
            print("DataTask cancelled")
        }
        dataTask.resume()
        return promise.future!
    }

}



func fetchUser(userId: Int, cancellationToken: CancellationTokenType = CancellationTokenNone()) -> Future<NSDictionary> {
    let promise = Promise<NSDictionary>()
    //let url = NSURL(string: String(format: "https://api.stackexchange.com/2.2/users/%d?site=stackoverflow", userId))!
    let url = NSURL(string: String(format: "https://api.example.com/2.2/users/%d?site=stackoverflow", userId))!
    NSURLSession.sharedSession().getData(url, cancellationToken: cancellationToken).onComplete { result in
        do {
            let tuple = try result.value()
            let data = tuple.0
            let response = tuple.1
            if response.MIMEType == "application/json" {
                let d = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0)) as! NSDictionary
                promise.fulfill(d)
            }
            else {
                promise.reject(GetDataError.Error(message: "Error: expected MIMEType equals application/json"))
            }
        }
        catch let error  {
            promise.reject(error)
        }
    }    
    return promise.future!
}



fetchUser(465677).onComplete { result in
    do {
        let user = try result.value()
        print("User \(465677): \(user)")
    }
    catch let error as NSError {
        print("Error: \(error)")
    }
    catch {}
}


sleep(2)


// Cancellation:

let cr = CancellationRequest()
fetchUser(465677, cancellationToken: cr.token).onComplete() { result in
    do {
        let user = try result.value()
        print("User \(465677): \(user)")
    }
    catch let error {
        print("Error: \(error)")
    }
}
cr.cancel()

sleep(2)
