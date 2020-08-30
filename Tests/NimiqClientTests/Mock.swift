import Foundation

public class Mock : URLSessionDataTask {
    // test data
    static var testData: Data?
    static var latestRequest: [String: Any]?
    static var latestRequestMethod: String?
    static var latestRequestParams: [Any]?

    typealias CompletionHandler = (NSData?, URLResponse?, NSError?) -> Void

    private let completion: CompletionHandler

    init(request: URLRequest, completion: @escaping CompletionHandler) {
        Mock.latestRequest = nil
        Mock.latestRequestMethod = nil
        Mock.latestRequestParams = nil

        // store request data, method and parameters
        if let data = request.httpBody {
            do {
                Mock.latestRequest = (try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments)) as? [String: Any]
                Mock.latestRequestMethod = Mock.latestRequest!["method"] as? String
                Mock.latestRequestParams = Mock.latestRequest!["params"] as? [Any]
            } catch {

            }
        }

        self.completion = completion
    }

    /// Run completion handler with the test data.
    public override func resume() {
        completion(Mock.testData! as NSData, nil, nil)
    }

    /// Exchange implementation of  dataTask method in URLSession with `swizzledDataTaskWithRequest`
    static func doSwizzling() {
        let originalSelector = Selector("dataTaskWithRequest:completionHandler:")
        let swizzledSelector = #selector(Mock.swizzledDataTaskWithRequest(with:completionHandler:))

        let originalMethod = class_getInstanceMethod(URLSession.self, originalSelector)!
        let swizzledMethod = class_getInstanceMethod(Mock.self, swizzledSelector)!

        method_exchangeImplementations(originalMethod, swizzledMethod)
    }

    /// Get the mock URLSessionDataTask
    @objc func swizzledDataTaskWithRequest(with request: URLRequest, completionHandler: @escaping (NSData?, URLResponse?, NSError?) -> Void) -> URLSessionDataTask {
        return Mock(request: request, completion: completionHandler as CompletionHandler)
    }
}
