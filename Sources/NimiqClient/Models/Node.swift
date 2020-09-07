/// Consensus state returned by the server.
public enum ConsensusState: String, Decodable {
    /// Connecting.
    case connecting
    /// Syncing blocks.
    case syncing
    /// Consensus established.
    case established
}

/// Syncing status returned by the server.
public struct SyncStatus : Decodable {
    /// The block at which the import started (will only be reset, after the sync reached his head).
    public var startingBlock: Int
    /// The current block, same as blockNumber.
    public var currentBlock: Int
    /// The estimated highest block.
    public var highestBlock: Int
}

/// Used to set the log level in the JSONRPC server.
public enum LogLevel : String {
    /// Trace level log.
    case trace
    /// Verbose level log.
    case verbose
    /// Debugging level log.
    case debug
    /// Info level log.
    case info
    /// Warning level log.
    case warn
    /// Error level log.
    case error
    /// Assertions level log.
    case assert
}

/// Syncing status returned by the server. The especific type is in the associated value.
internal struct SyncStatusOrBool : Decodable {
    let syncStatus: Any

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        do {
            syncStatus = try container.decode(SyncStatus.self)
        } catch {
            syncStatus = try container.decode(Bool.self)
        }
    }
}
