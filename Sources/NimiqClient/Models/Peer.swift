/// Peer address state returned by the server.
public enum PeerAddressState : Int, Decodable {
    /// New peer.
    case new = 1
    /// Established peer.
    case established = 2
    /// Already tried peer.
    case tried = 3
    /// Peer failed.
    case failed = 4
    /// Balled peer.
    case banned = 5
}

/// Peer connection state returned by the server.
public enum PeerConnectionState : Int, Decodable {
    /// New connection.
    case new = 1
    /// Connecting.
    case connecting = 2
    /// Connected.
    case connected = 3
    /// Negotiating connection.
    case negotiating = 4
    /// Connection established.
    case established = 5
    /// Connection closed.
    case closed = 6
}

/// Commands to change the state of a peer.
public enum PeerStateCommand : String {
    /// Connect.
    case connect
    /// Disconnect.
    case disconnect
    /// Ban.
    case ban
    /// Unban.
    case unban
}

/// Peer information returned by the server.
public struct Peer : Decodable {
    /// Peer id.
    public var id: String
    /// Peer address.
    public var address: String
    /// Peer address state.
    public var addressState: PeerAddressState
    /// Peer connection state.
    public var connectionState: PeerConnectionState?
    /// Node version the peer is running.
    public var version: Int?
    /// Time offset with the peer (in miliseconds).
    public var timeOffset: Int?
    /// Hash of the head block of the peer.
    public var headHash: String?
    /// Latency to the peer.
    public var latency: Int?
    /// Received bytes.
    public var rx: Int?
    /// Sent bytes.
    public var tx: Int?
}
