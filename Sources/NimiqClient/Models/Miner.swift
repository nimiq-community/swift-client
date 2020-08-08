/// Pool connection state information returned by the server.
public enum PoolConnectionState : Int, Decodable {
    /// Connected.
    case connected = 0
    /// Connecting.
    case connecting = 1
    /// Closed.
    case closed = 2
}

/// Work instructions receipt returned by the server.
public struct WorkInstructions : Decodable {
    /// Hex-encoded block header. This is what should be passed through the hash function.
    /// The last 4 bytes describe the nonce, the 4 bytes before are the current timestamp.
    /// Most implementations allow the miner to arbitrarily choose the nonce and to update the timestamp without requesting new work instructions.
    public var data: String
    /// Hex-encoded block without the header. When passing a mining result to submitBlock, append the suffix to the data string with selected nonce.
    public var suffix: String
    /// Compact form of the hash target to submit a block to this client.
    public var target: Int
    /// Field to describe the algorithm used to mine the block. Always nimiq-argon2 for now.
    public var algorithm: String
}
