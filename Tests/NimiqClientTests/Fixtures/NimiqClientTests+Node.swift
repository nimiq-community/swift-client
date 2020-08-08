import Foundation

extension NimiqClientTests {

    static func consensusSyncing() -> Data {
        return """
            {
                "jsonrpc": "2.0",
                "result": "syncing",
                "id": 1
            }
            """.data(using: .utf8)!
    }

    static func constant() -> Data {
        return """
            {
                "jsonrpc": "2.0",
                "result": 5,
                "id": 1
            }
            """.data(using: .utf8)!
    }

    static func log() -> Data {
        return """
            {
                "jsonrpc": "2.0",
                "result": true,
                "id": 1
            }
            """.data(using: .utf8)!
    }

    static func minFeePerByte() -> Data {
        return """
            {
                "jsonrpc": "2.0",
                "result": 0,
                "id": 1
            }
            """.data(using: .utf8)!
    }

    static func syncingNotSyncing() -> Data {
        return """
            {
                "jsonrpc": "2.0",
                "result": false,
                "id": 1
            }
            """.data(using: .utf8)!
    }

    static func syncing() -> Data {
        return """
            {
                "jsonrpc": "2.0",
                "result": {
                    "startingBlock": 578430,
                    "currentBlock": 586493,
                    "highestBlock": 586493
                },
                "id": 1
            }
            """.data(using: .utf8)!
    }
}
