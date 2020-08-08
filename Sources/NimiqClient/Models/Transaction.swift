/// Used to pass the data to send transaccions.
public struct OutgoingTransaction {
    /// The address the transaction is send from.
    public var from: Address
    /// The account type at the given address.
    public var fromType: AccountType? = .basic
    /// The address the transaction is directed to.
    public var to: Address
    /// The account type at the given address.
    public var toType: AccountType? = .basic
    /// Integer of the value (in smallest unit) sent with this transaction.
    public var value: Int
    /// Integer of the fee (in smallest unit) for this transaction.
    public var fee: Int
    /// Hex-encoded contract parameters or a message.
    public var data: String? = nil

    /// OutgoingTransaction initialization.
    /// - Parameter from: The address the transaction is send from.
    /// - Parameter fromType: The account type at the given address.
    /// - Parameter to: The address the transaction is directed to.
    /// - Parameter toType: The account type at the given address.
    /// - Parameter value: Integer of the value (in smallest unit) sent with this transaction.
    /// - Parameter fee: Integer of the fee (in smallest unit) for this transaction.
    /// - Parameter data: Hex-encoded contract parameters or a message.
    public init(from: Address, fromType: AccountType? = .basic, to: Address, toType: AccountType? = .basic, value: Int, fee: Int, data: String? = nil) {
        self.from = from
        self.fromType = fromType
        self.to = to
        self.toType = toType
        self.value = value
        self.fee = fee
        self.data = data
    }
}

/// Transaction returned by the server.
public struct Transaction : Decodable {
    /// Hex-encoded hash of the transaction.
    public var hash: Hash
    /// Hex-encoded hash of the block containing the transaction.
    public var blockHash: Hash?
    /// Height of the block containing the transaction.
    public var blockNumber: Int?
    /// UNIX timestamp of the block containing the transaction.
    public var timestamp: Int?
    /// Number of confirmations of the block containing the transaction.
    public var confirmations: Int? = 0
    /// Index of the transaction in the block.
    public var transactionIndex: Int?
    /// Hex-encoded address of the sending account.
    public var from: String
    /// Nimiq user friendly address (NQ-address) of the sending account.
    public var fromAddress: Address
    /// Hex-encoded address of the recipient account.
    public var to: String
    /// Nimiq user friendly address (NQ-address) of the recipient account.
    public var toAddress: Address
    /// Integer of the value (in smallest unit) sent with this transaction.
    public var value: Int
    /// Integer of the fee (in smallest unit) for this transaction.
    public var fee: Int
    /// Hex-encoded contract parameters or a message.
    public var data: String? = nil
    /// Bit-encoded transaction flags.
    public var flags: Int
}

/// Transaction receipt returned by the server.
public struct TransactionReceipt : Decodable {
    /// Hex-encoded hash of the transaction.
    public var transactionHash: Hash
    /// Integer of the transactions index position in the block.
    public var transactionIndex: Int
    /// Hex-encoded hash of the block where this transaction was in.
    public var blockHash: Hash
    /// Block number where this transaction was in.
    public var blockNumber: Int
    /// Number of confirmations for this transaction (number of blocks on top of the block where this transaction was in).
    public var confirmations: Int
    /// Timestamp of the block where this transaction was in.
    public var timestamp: Int
}
