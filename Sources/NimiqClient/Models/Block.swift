/// Block returned by the server.
public struct Block : Decodable {
    /// Height of the block.
    public var number: Int
    /// Hex-encoded 32-byte hash of the block.
    public var hash: Hash
    /// Hex-encoded 32-byte Proof-of-Work hash of the block.
    public var pow: Hash
    /// Hex-encoded 32-byte hash of the predecessor block.
    public var parentHash: Hash
    /// The nonce of the block used to fulfill the Proof-of-Work.
    public var nonce: Int
    /// Hex-encoded 32-byte hash of the block body Merkle root.
    public var bodyHash: Hash
    /// Hex-encoded 32-byte hash of the accounts tree root.
    public var accountsHash: Hash
    /// Block difficulty, encoded as decimal number in string.
    public var difficulty: String
    /// UNIX timestamp of the block
    public var timestamp: Int
    /// Number of confirmations for this transaction (number of blocks on top of the block where this transaction was in).
    public var confirmations: Int
    /// Hex-encoded 20 byte address of the miner of the block.
    public var miner: String
    /// User friendly address (NQ-address) of the miner of the block.
    public var minerAddress: Address
    /// Hex-encoded value of the extra data field, maximum of 255 bytes.
    public var extraData: String
    /// Block size in byte.
    public var size: Int
    /// Array of transactions. Either represented by the transaction hash or a Transaction object.
    public var transactions: [Any]

    private enum CodingKeys: String, CodingKey {
        case number, hash, pow, parentHash, nonce, bodyHash, accountsHash, difficulty, timestamp, confirmations, miner, minerAddress, extraData, size, transactions
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        number = try container.decode(Int.self, forKey: .number)
        hash = try container.decode(Hash.self, forKey: .hash)
        pow = try container.decode(Hash.self, forKey: .pow)
        parentHash = try container.decode(Hash.self, forKey: .parentHash)
        nonce = try container.decode(Int.self, forKey: .nonce)
        bodyHash = try container.decode(Hash.self, forKey: .bodyHash)
        accountsHash = try container.decode(Hash.self, forKey: .accountsHash)
        difficulty = try container.decode(String.self, forKey: .difficulty)
        timestamp = try container.decode(Int.self, forKey: .timestamp)
        confirmations = try container.decode(Int.self, forKey: .confirmations)
        miner = try container.decode(String.self, forKey: .miner)
        minerAddress = try container.decode(Address.self, forKey: .minerAddress)
        extraData = try container.decode(String.self, forKey: .extraData)
        size = try container.decode(Int.self, forKey: .size)
        do {
            transactions = try container.decode([Transaction].self, forKey: .transactions)
        } catch {
            transactions = try container.decode([Hash].self, forKey: .transactions)
        }
    }
}

/// Block template header returned by the server.
public struct BlockTemplateHeader : Decodable {
    /// Version in block header.
    public var version: Int
    /// 32-byte hex-encoded hash of the previous block.
    public var prevHash: Hash
    /// 32-byte hex-encoded hash of the interlink.
    public var interlinkHash: Hash
    /// 32-byte hex-encoded hash of the accounts tree.
    public var accountsHash: Hash
    /// Compact form of the hash target for this block.
    public var nBits: Int
    /// Height of the block in the block chain (also known as block number).
    public var height: Int
}

/// Block template body returned by the server.
public struct BlockTemplateBody : Decodable {
    /// 32-byte hex-encoded hash of the block body.
    public var hash: Hash
    /// 20-byte hex-encoded miner address.
    public var minerAddr: String
    /// Hex-encoded value of the extra data field.
    public var extraData: String
    /// Array of hex-encoded transactions for this block.
    public var transactions: [String]
    /// Array of hex-encoded pruned accounts for this block.
    public var prunedAccounts: [String]
    /// Array of hex-encoded hashes that verify the path of the miner address in the merkle tree.
    /// This can be used to change the miner address easily.
    public var merkleHashes: [Hash]
}

/// Block template returned by the server.
public struct BlockTemplate : Decodable {
    /// Block template header returned by the server.
    public var header: BlockTemplateHeader
    /// Hex-encoded interlink.
    public var interlink: String
    /// Block template body returned by the server.
    public var body: BlockTemplateBody
    /// Compact form of the hash target to submit a block to this client.
    public var target: Int
}
