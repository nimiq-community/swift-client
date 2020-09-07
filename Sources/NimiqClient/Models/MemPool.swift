/// Mempool information returned by the server.
public struct MempoolInfo : Decodable {
    /// Total number of pending transactions in mempool.
    public var total: Int
    /// Array containing a subset of fee per byte buckets from [10000, 5000, 2000, 1000, 500, 200, 100, 50, 20, 10, 5, 2, 1, 0] that currently have more than one transaction.
    public var buckets: [Int]
    /// Number of transaction in the bucket. A transaction is assigned to the highest bucket of a value lower than its fee per byte value.
    public var transactionsPerBucket: [Int:Int]

    private enum CodingKeys: String, CodingKey {
        case total, buckets
        case bucket10000 = "10000"
        case bucket5000 = "5000"
        case bucket2000 = "2000"
        case bucket1000 = "1000"
        case bucket500 = "500"
        case bucket200 = "200"
        case bucket100 = "100"
        case bucket50 = "50"
        case bucket20 = "20"
        case bucket10 = "10"
        case bucket5 = "5"
        case bucket2 = "2"
        case bucket1 = "1"
        case bucket0 = "0"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        total = try container.decode(Int.self, forKey: .total)
        buckets = try container.decode([Int].self, forKey: .buckets)
        transactionsPerBucket = [Int:Int]()
        for key in container.allKeys {
            guard let intKey = Int(key.stringValue) else {
                continue
            }
            transactionsPerBucket[intKey] = try container.decode(Int.self, forKey: key)
        }
    }
}
