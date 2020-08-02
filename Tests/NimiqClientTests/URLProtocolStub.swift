import Foundation

class URLProtocolStub: URLProtocol {
    // test data
    static var testData: Data?
    static var latestRequest: [String: Any]?
    static var latestRequestMethod: String?
    static var latestRequestParams: [Any]?

    // handle all types of request
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    // send back the request as is
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        latestRequest = nil
        latestRequestMethod = nil
        latestRequestParams = nil

        if let bodyStream = request.httpBodyStream {
            bodyStream.open()

            // Will read 16 chars per iteration. Can use bigger buffer if needed
            let bufferSize: Int = 16

            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)

            var data = Data()

            while bodyStream.hasBytesAvailable {

                let readDat = bodyStream.read(buffer, maxLength: bufferSize)
                data.append(buffer, count: readDat)
            }

            buffer.deallocate()

            bodyStream.close()

            do {
                latestRequest = (try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments)) as? [String: Any]
                latestRequestMethod = latestRequest!["method"] as? String
                latestRequestParams = latestRequest!["params"] as? [Any]
            } catch {

            }
        }

        return request
    }

    override func startLoading() {
        // load test data
        self.client?.urlProtocol(self, didLoad: URLProtocolStub.testData!)

        // request has finished
        self.client?.urlProtocolDidFinishLoading(self)
    }

    // doesn't need to do anything
    override func stopLoading() { }
}
