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
