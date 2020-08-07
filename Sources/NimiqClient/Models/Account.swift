/// Type of a Nimiq account.
public enum AccountType: Int, Decodable {
    /// Normal Nimiq account.
    case basic = 0
    /// Vesting contract.
    case vesting = 1
    /// Hashed Timelock Contract.
    case htlc = 2
}

/// Normal Nimiq account object returned by the server.
public class Account: Decodable {
    /// Hex-encoded 20 byte address.
    public var id: String
    /// User friendly address (NQ-address).
    public var address: String
    /// Balance of the account (in smallest unit).
    public var balance: Int
    /// The account type associated with the account.
    public var type: AccountType
}

/// Vesting contract object returned by the server.
public class VestingContract : Account {
    /// Hex-encoded 20 byte address of the owner of the vesting contract.
    public var owner: String
    /// User friendly address (NQ-address) of the owner of the vesting contract.
    public var ownerAddress: String
    /// The block that the vesting contracted commenced.
    public var vestingStart: Int
    /// The number of blocks after which some part of the vested funds is released.
    public var vestingStepBlocks: Int
    /// The amount (in smallest unit) released every vestingStepBlocks blocks.
    public var vestingStepAmount: Int
    /// The total amount (in smallest unit) that was provided at the contract creation.
    public var vestingTotalAmount: Int
    
    private enum CodingKeys: String, CodingKey {
        case owner, ownerAddress, vestingStart, vestingStepBlocks, vestingStepAmount, vestingTotalAmount
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.owner = try container.decode(String.self, forKey: .owner)
        self.ownerAddress = try container.decode(String.self, forKey: .ownerAddress)
        self.vestingStart = try container.decode(Int.self, forKey: .vestingStart)
        self.vestingStepBlocks = try container.decode(Int.self, forKey: .vestingStepBlocks)
        self.vestingStepAmount = try container.decode(Int.self, forKey: .vestingStepAmount)
        self.vestingTotalAmount = try container.decode(Int.self, forKey: .vestingTotalAmount)
        try super.init(from: decoder)
    }
}

/// Hashed Timelock Contract object returned by the server.
public class HTLC : Account {
    /// Hex-encoded 20 byte address of the sender of the HTLC.
    public var sender: String
    /// User friendly address (NQ-address) of the sender of the HTLC.
    public var senderAddress: String
    /// Hex-encoded 20 byte address of the recipient of the HTLC.
    public var recipient: String
    /// User friendly address (NQ-address) of the recipient of the HTLC.
    public var recipientAddress: String
    /// Hex-encoded 32 byte hash root.
    public var hashRoot: String
    /// Hash algorithm.
    public var hashAlgorithm: Int
    /// Number of hashes this HTLC is split into.
    public var hashCount: Int
    /// Block after which the contract can only be used by the original sender to recover funds.
    public var timeout: Int
    /// The total amount (in smallest unit) that was provided at the contract creation.
    public var totalAmount: Int
    
    private enum CodingKeys: String, CodingKey {
        case sender, senderAddress, recipient, recipientAddress, hashRoot, hashAlgorithm, hashCount, timeout, totalAmount
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.sender = try container.decode(String.self, forKey: .sender)
        self.senderAddress = try container.decode(String.self, forKey: .senderAddress)
        self.recipient = try container.decode(String.self, forKey: .recipient)
        self.recipientAddress = try container.decode(String.self, forKey: .recipientAddress)
        self.hashRoot = try container.decode(String.self, forKey: .hashRoot)
        self.hashAlgorithm = try container.decode(Int.self, forKey: .hashAlgorithm)
        self.hashCount = try container.decode(Int.self, forKey: .hashCount)
        self.timeout = try container.decode(Int.self, forKey: .timeout)
        self.totalAmount = try container.decode(Int.self, forKey: .totalAmount)
        try super.init(from: decoder)
    }
}

/// Nimiq wallet returned by the server.
public struct Wallet: Decodable {
    /// Hex-encoded 20 byte address.
    public var id: String
    /// User friendly address (NQ-address).
    public var address: String
    /// Hex-encoded 32 byte Ed25519 public key.
    public var publicKey: String
    /// Hex-encoded 32 byte Ed25519 private key.
    public var privateKey: String?
}
