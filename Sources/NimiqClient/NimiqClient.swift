import Foundation

// MARK: JSONRPC Models

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

/// Error returned in the response from the JSONRPC server.
struct ResponseError: Decodable {
    var code: Int
    var message: String
}

/// Used to decode the JSONRPC response returned by the server.
struct Root<T:Decodable>: Decodable {
    var jsonrpc: String
    var result: T?
    var id: Int
    var error: ResponseError?
}

/// Nimiq account returned by the server. The especific type is in the associated value.
enum RawAccount : Decodable {
    case account(Account)
    case vesting(VestingContract)
    case htlc(HTLC)

    var value: Any {
         switch self {
         case .account(let value):
             return value
         case .vesting(let value):
             return value
         case .htlc(let value):
             return value
         }
    }

    private enum CodingKeys: String, CodingKey {
        case account, vestingContract, hashedTimeLockedContract
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        do {
            self = .htlc(try container.decode(HTLC.self))
        } catch {
            do {
                self = .vesting(try container.decode(VestingContract.self))
            } catch {
                self = .account(try container.decode(Account.self))
            }
        }
    }
}

/// Transaction returned by the server. The especific type is in the associated value.
enum HashOrTransaction : Decodable {
    case hash(Hash)
    case transaction(Transaction)

    var value: Any {
         switch self {
         case .hash(let value):
             return value
         case .transaction(let value):
             return value
         }
    }

    private enum CodingKeys: String, CodingKey {
        case hash, transaction
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        do {
            self = .transaction(try container.decode(Transaction.self))
        } catch {
            self = .hash(try container.decode(Hash.self))
        }
    }
}

/// Syncing status returned by the server. The especific type is in the associated value.
enum SyncStatusOrBool : Decodable {
    case syncStatus(SyncStatus)
    case bool(Bool)

    var value: Any {
         switch self {
         case .syncStatus(let value):
             return value
         case .bool(let value):
             return value
         }
    }

    private enum CodingKeys: String, CodingKey {
        case syncStatus, bool
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        do {
            self = .syncStatus(try container.decode(SyncStatus.self))
        } catch {
            self = .bool(try container.decode(Bool.self))
        }
    }
}

// MARK: -
// MARK: JSONRPC Client

/// Used in convenience initializer in the NimiqClient class.
public struct Config {
    /// Protocol squeme, `"http"` or `"https"`.
    public var scheme: String
    /// Authorized user.
    public var user: String
    /// Password for the authorized user.
    public var password: String
    /// Host IP address.
    public var host: String
    /// Host port.
    public var port: Int

    /// Config initialization.
    /// - Parameter scheme: Protocol squeme, `"http"` or `"https"`.
    /// - Parameter user: Authorized user.
    /// - Parameter password: Password for the authorized user.
    /// - Parameter host: Host IP address.
    /// - Parameter port: Host port.
    public init(scheme: String = "http", user: String = "", password: String = "", host: String = "127.0.0.1", port: Int = 8648) {
        self.scheme = scheme
        self.host = host
        self.port = port
        self.user = user
        self.password = password
    }
}

/// Thrown when something when wrong with the JSONRPC request.
public enum Error: Swift.Error, Equatable {
    /// Internal error during a JSON RPC request.
    case internalError(_ message: String)
    /// Exception on the remote server.
    case remoteError(_ message: String)
    /// Error with connection.
    case connectionError(_ message: String)
}

/// Nimiq JSONRPC Client
public class NimiqClient {

    /// Number in the sequence for the next request.
    public var id: Int = 0

    /// URL of the JSONRPC server.
    private let url: String
    
    /// Base64 string containing authentication parameters.
    private let auth: String

    /// URLSession used for HTTP requests sent to the JSONRPC server.
    private let session: URLSession

    /// Client initialization from a Config structure using shared URLSession.
    /// When no parameter is given, it uses de default configuration in the server (`http://:@127.0.0.1:8648`).
    /// - Parameter config: Options used for the configuration.
    public convenience init(config: Config? = nil) {
        if config != nil {
            self.init(scheme: config!.scheme, user: config!.user, password: config!.password, host: config!.host, port: config!.port)
        } else {
            self.init(scheme: "http", user: "", password: "", host: "127.0.0.1", port: 8648)
        }
    }

    /// Client initialization.
    /// - Parameter scheme: Protocol squeme, `"http"` or `"https"`.
    /// - Parameter user: Authorized user.
    /// - Parameter password: Password for the authorized user.
    /// - Parameter host: Host IP address.
    /// - Parameter port: Host port.
    /// - Parameter session: Used to make all requests. If ommited the shared URLSession is used.
    public init(scheme: String = "http", user: String = "", password: String = "", host: String = "127.0.0.1", port: Int = 8648, session: URLSession? = nil){
        self.url = "\(scheme)://\(host):\(port)"
        self.auth = "\(user):\(password)".data(using: String.Encoding.utf8)!.base64EncodedString()
        if session != nil {
            self.session = session!
        } else {
            self.session = URLSession.shared
        }
    }

    /// Used in all JSONRPC requests to fetch the data.
    /// - Parameter method: JSONRPC method.
    /// - Parameter params: Parameters used by the request.
    /// - Returns: If succesfull, returns the model reperestation of the result, `nil` otherwise.
    private func call<T:Decodable>(method: String, params: [Any]) throws -> T? {
        var responseObject: Root<T>? = nil
        var clientError: Error? = nil

        // make JSON object to send to the server
        let callObject:[String:Any] = [
            "jsonrpc": "2.0",
            "method": method,
            "params": params,
            "id": id
        ]

        // prepare the request
        let data = try JSONSerialization.data(withJSONObject: callObject, options: [])
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        request.httpBody = data
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Basic \(auth)", forHTTPHeaderField: "Authorization")
        // TODO: find a better way to fix the error when the server terminates the connection prematurely
        request.addValue("close", forHTTPHeaderField: "Connection")

        let semaphore = DispatchSemaphore(value: 0)

        // send the request
        let task = session.dataTask(with: request, completionHandler: { data, response, error in
            if error == nil {
                // serialize the data into an object
                do {
                    responseObject = try JSONDecoder().decode(Root<T>.self, from: data! )

                } catch {
                    clientError = Error.internalError(error.localizedDescription)
                }
            } else {
                clientError = Error.connectionError(error!.localizedDescription)
            }

            // signal that the request was completed
            semaphore.signal()
        })
        task.resume()

        // wait for the response
        semaphore.wait()

        // throw if there are any errors
        if clientError != nil {
            throw clientError!
        }

        if let error = responseObject?.error {
            throw Error.remoteError("\(error.message) (Code: \(error.code)")
        }

        // increase the JSONRPC client request id for the next request
        self.id = self.id + 1

        return responseObject?.result
    }

    /// Returns a list of addresses owned by client.
    /// - Returns: Array of Accounts owned by the client.
    public func accounts() throws -> [Any]? {
        let result: [RawAccount] = try call(method: "accounts", params: [])!
        var converted: [Any] = [Any]()
        for rawAccount in result {
            converted.append(rawAccount.value)
        }
        return converted
    }

    /// Returns the height of most recent block.
    /// - Returns: The current block height the client is on.
    public func blockNumber() throws -> Int? {
        return try call(method: "blockNumber", params: [])
    }

    /// Returns information on the current consensus state.
    /// - Returns: Consensus state. `established` is the value for a good state, other values indicate bad.
    public func consensus() throws -> ConsensusState? {
        return try call(method: "consensus", params: [])
    }

    /// Returns or overrides a constant value.
    /// When no parameter is given, it returns the value of the constant. When giving a value as parameter,
    /// it sets the constant to the given value. To reset the constant use `resetConstant()` instead.
    /// - Parameter string: The class and name of the constant (format should be `Class.CONSTANT`).
    /// - Parameter value: The new value of the constant.
    /// - Returns: The value of the constant.
    public func constant(_ constant: String, value: Int? = nil) throws -> Int? {
        var params:[Any] = [constant]
        if value != nil {
            params.append(value!)
        }
        return try call(method: "constant", params: params)
    }

    /// Creates a new account and stores its private key in the client store.
    /// - Returns: Information on the wallet that was created using the command.
    public func createAccount() throws -> Wallet? {
        return try call(method: "createAccount", params: [])
    }

    /// Creates and signs a transaction without sending it. The transaction can then be send via `sendRawTransaction()` without accidentally replaying it.
    /// - Parameter transaction: The transaction object.
    /// - Returns: Hex-encoded transaction.
    public func createRawTransaction(_ transaction: OutgoingTransaction) throws -> String? {
        let params:[String:Any?] = [
            "from": transaction.from,
            "fromType": transaction.fromType?.rawValue,
            "to": transaction.to,
            "toType": transaction.toType?.rawValue,
            "value": transaction.value,
            "fee": transaction.fee,
            "data": transaction.data
        ]
        return try call(method: "createRawTransaction", params: [params])
    }

    /// Returns details for the account of given address.
    /// - Parameter address: Address to get account details.
    /// - Returns: Details about the account. Returns the default empty basic account for non-existing accounts.
    public func getAccount(address: Address) throws -> Any? {
        let result: RawAccount = try call(method: "getAccount", params: [address])!
        return result.value
    }

    /// Returns the balance of the account of given address.
    /// - Parameter address: Address to check for balance.
    /// - Returns: The current balance at the specified address (in smalest unit).
    public func getBalance(address: Address) throws -> Int? {
        return try call(method: "getBalance", params: [address])
    }

    /// Returns information about a block by hash.
    /// - Parameter hash: Hash of the block to gather information on.
    /// - Parameter fullTransactions: If `true` it returns the full transaction objects, if `false` only the hashes of the transactions.
    /// - Returns: A block object or `nil` when no block was found.
    public func getBlockByHash(_ hash: Hash, fullTransactions: Bool = false) throws -> Block? {
        return try call(method: "getBlockByHash", params: [hash, fullTransactions])
    }

    /// Returns information about a block by block number.
    /// - Parameter height: The height of the block to gather information on.
    /// - Parameter fullTransactions: If `true` it returns the full transaction objects, if `false` only the hashes of the transactions.
    /// - Returns: A block object or `nil` when no block was found.
    public func getBlockByNumber(height: Int, fullTransactions: Bool = false) throws -> Block? {
        return try call(method: "getBlockByNumber", params: [height, fullTransactions])
    }

    /// Returns a template to build the next block for mining. This will consider pool instructions when connected to a pool.
    /// If `address` and `extraData` are provided the values are overriden.
    /// - Parameter address: The address to use as a miner for this block. This overrides the address provided during startup or from the pool.
    /// - Parameter extraData: Hex-encoded value for the extra data field. This overrides the extra data provided during startup or from the pool.
    /// - Returns: A block template object.
    public func getBlockTemplate(address: Address? = nil, extraData: String = "") throws -> BlockTemplate? {
        var params: [Any] = [Any]()
        if address != nil {
            params.append(address!)
            params.append(extraData)
        }
        return try call(method: "getBlockTemplate", params: params)

    }

    /// Returns the number of transactions in a block from a block matching the given block hash.
    /// - Parameter hash: Hash of the block.
    /// - Returns: Number of transactions in the block found, or `nil`, when no block was found.
    public func getBlockTransactionCountByHash(_ hash: Hash) throws -> Int? {
        return try call(method: "getBlockTransactionCountByHash", params: [hash])
    }

    /// Returns the number of transactions in a block matching the given block number.
    /// - Parameter height: Height of the block.
    /// - Returns: Number of transactions in the block found, or `nil`, when no block was found.
    public func getBlockTransactionCountByNumber(height: Int) throws -> Int? {
        return try call(method: "getBlockTransactionCountByNumber", params: [height])
    }

    /// Returns information about a transaction by block hash and transaction index position.
    /// - Parameter hash: Hash of the block containing the transaction.
    /// - Parameter index: Index of the transaction in the block.
    /// - Returns: A transaction object or `nil` when no transaction was found.
    public func getTransactionByBlockHashAndIndex(hash: Hash, index: Int) throws -> Transaction? {
        return try call(method: "getTransactionByBlockHashAndIndex", params: [hash, index])
    }

    /// Returns information about a transaction by block number and transaction index position.
    /// - Parameter height: Height of the block containing the transaction.
    /// - Parameter index: Index of the transaction in the block.
    /// - Returns: A transaction object or `nil` when no transaction was found.
    public func getTransactionByBlockNumberAndIndex(height: Int, index: Int) throws -> Transaction? {
        return try call(method: "getTransactionByBlockNumberAndIndex", params: [height, index])
    }

    /// Returns the information about a transaction requested by transaction hash.
    /// - Parameter hash: Hash of a transaction.
    /// - Returns: A transaction object or `nil` when no transaction was found.
    public func getTransactionByHash(_ hash: Hash) throws -> Transaction? {
        return try call(method: "getTransactionByHash", params: [hash])
    }

    /// Returns the receipt of a transaction by transaction hash.
    /// - Parameter hash: Hash of a transaction.
    /// - Returns: A transaction receipt object, or `nil` when no receipt was found.
    public func getTransactionReceipt(hash: Hash) throws -> TransactionReceipt? {
        return try call(method: "getTransactionReceipt", params: [hash])
    }

    /// Returns the latest transactions successfully performed by or for an address.
    /// Note that this information might change when blocks are rewinded on the local state due to forks.
    /// - Parameter address: Address of which transactions should be gathered.
    /// - Parameter numberOfTransactions: Number of transactions that shall be returned.
    /// - Returns: Array of transactions linked to the requested address.
    public func getTransactionsByAddress(_ address: Address, numberOfTransactions: Int = 1000) throws -> [Transaction]? {
        return try call(method: "getTransactionsByAddress", params: [address, numberOfTransactions])
    }

    /// Returns instructions to mine the next block. This will consider pool instructions when connected to a pool.
    /// - Parameter address: The address to use as a miner for this block. This overrides the address provided during startup or from the pool.
    /// - Parameter extraData: Hex-encoded value for the extra data field. This overrides the extra data provided during startup or from the pool.
    /// - Returns: Mining work instructions.
    public func getWork(address: Address? = nil, extraData: String = "") throws -> WorkInstructions? {
        var params: [Any] = [Any]()
        if address != nil {
            params.append(address!)
            params.append(extraData)
        }
        return try call(method: "getWork", params: params)
    }

    /// Returns the number of hashes per second that the node is mining with.
    /// - Returns: Number of hashes per second.
    public func hashrate() throws -> Float? {
        return try call(method: "hashrate", params: [])
    }

    /// Sets the log level of the node.
    /// - Parameter tag: Tag: If `"*"` the log level is set globally, otherwise the log level is applied only on this tag.
    /// - Parameter level: Minimum log level to display.
    /// - Returns: `true` if the log level was changed, `false` otherwise.
    public func log(tag: String, level: LogLevel) throws -> Bool? {
        return try call(method: "log", params: [tag, level.rawValue])
    }

    /// Returns information on the current mempool situation. This will provide an overview of the number of transactions sorted into buckets based on their fee per byte (in smallest unit).
    /// - Returns: Mempool information.
    public func mempool() throws -> MempoolInfo? {
        return try call(method: "mempool", params: [])
    }

    /// Returns transactions that are currently in the mempool.
    /// - Parameter fullTransactions: If `true` includes full transactions, if `false` includes only transaction hashes.
    /// - Returns: Array of transactions (either represented by the transaction hash or a transaction object).
    public func mempoolContent(fullTransactions: Bool = false) throws -> [Any]? {
        let result: [HashOrTransaction] = try call(method: "mempoolContent", params: [fullTransactions])!
        var converted: [Any] = [Any]()
        for transaction in result {
            converted.append(transaction.value)
        }
        return converted
    }

    /// Returns the miner address.
    /// - Returns: The miner address configured on the node.
    public func minerAddress() throws -> String? {
        return try call(method: "minerAddress", params: [])
    }

    /// Returns or sets the number of CPU threads for the miner.
    /// When no parameter is given, it returns the current number of miner threads.
    /// When a value is given as parameter, it sets the number of miner threads to that value.
    /// - Parameter threads: The number of threads to allocate for mining.
    /// - Returns: The number of threads allocated for mining.
    public func minerThreads(_ threads: Int? = nil) throws -> Int? {
        var params: [Int] = [Int]()
        if threads != nil {
            params.append(threads!)
        }
        return try call(method: "minerThreads", params: params)
    }

    /// Returns or sets the minimum fee per byte.
    /// When no parameter is given, it returns the current minimum fee per byte.
    /// When a value is given as parameter, it sets the minimum fee per byte to that value.
    /// - Parameter fee: The new minimum fee per byte.
    /// - Returns: The new minimum fee per byte.
    public func minFeePerByte(fee: Int? = nil) throws -> Int? {
        var params: [Int] = [Int]()
        if fee != nil {
            params.append(fee!)
        }
        return try call(method: "minFeePerByte", params: params)
    }

    /// Returns true if client is actively mining new blocks.
    /// When no parameter is given, it returns the current state.
    /// When a value is given as parameter, it sets the current state to that value.
    /// - Parameter state: The state to be set.
    /// - Returns: `true` if the client is mining, otherwise `false`.
    public func mining(state: Bool? = nil) throws -> Bool? {
        var params: [Bool] = [Bool]()
        if state != nil {
            params.append(state!)
        }
        return try call(method: "mining", params: params)
    }

    /// Returns number of peers currently connected to the client.
    /// - Returns: Number of connected peers.
    public func peerCount() throws -> Int? {
        return try call(method: "peerCount", params: [])
    }

    /// Returns list of peers known to the client.
    /// - Returns: The list of peers.
    public func peerList() throws -> [Peer]? {
        return try call(method: "peerList", params: [])
    }

    /// Returns the state of the peer.
    /// When no command is given, it returns peer state.
    /// When a value is given for command, it sets the peer state to that value.
    /// - Parameter address: The address of the peer.
    /// - Parameter command: The command to send.
    /// - Returns: The current state of the peer.
    public func peerState(address: String, command: PeerStateCommand? = nil) throws -> Peer? {
        var params: [Any] = [Any]()
        params.append(address)
        if let commandString = command?.rawValue  {
            params.append(commandString)
        }
        return try call(method: "peerState", params: params)
    }

    /// Returns or sets the mining pool.
    /// When no parameter is given, it returns the current mining pool.
    /// When a value is given as parameter, it sets the mining pool to that value.
    /// - Parameter address: The mining pool connection string (`url:port`) or boolean to enable/disable pool mining.
    /// - Returns: The mining pool connection string, or `nil` if not enabled.
    public func pool(address: Any? = nil) throws -> String? {
        var params: [Any] = [Any]()
        if let addressString = address as? String {
            params.append(addressString)
        } else if let addressBool = address as? Bool {
            params.append(addressBool)
        }
        return try call(method: "pool", params: params)
    }

    /// Returns the confirmed mining pool balance.
    /// - Returns: The confirmed mining pool balance (in smallest unit).
    public func poolConfirmedBalance() throws -> Int? {
        return try call(method: "poolConfirmedBalance", params: [])
    }

    /// Returns the connection state to mining pool.
    /// - Returns: The mining pool connection state.
    public func poolConnectionState() throws -> PoolConnectionState? {
        return try call(method: "poolConnectionState", params: [])
    }

    /// Sends a signed message call transaction or a contract creation, if the data field contains code.
    /// - Parameter transaction: The hex encoded signed transaction
    /// - Returns: The Hex-encoded transaction hash.
    public func sendRawTransaction(_ transaction: String) throws -> Hash? {
        return try call(method: "sendRawTransaction", params: [transaction])
    }

    /// Creates new message call transaction or a contract creation, if the data field contains code.
    /// - Parameter transaction: The hex encoded signed transaction
    /// - Returns: The Hex-encoded transaction hash.
    public func sendTransaction(_ transaction: OutgoingTransaction) throws -> Hash? {
        let params:[String:Any?] = [
            "from": transaction.from,
            "fromType": transaction.fromType?.rawValue,
            "to": transaction.to,
            "toType": transaction.toType?.rawValue,
            "value": transaction.value,
            "fee": transaction.fee,
            "data": transaction.data
        ]
        return try call(method: "sendTransaction", params: [params])
    }

    /// Submits a block to the node. When the block is valid, the node will forward it to other nodes in the network.
    /// - Parameter block: Hex-encoded full block (including header, interlink and body). When submitting work from getWork, remember to include the suffix.
    /// - Returns: Always `nil`.
    @discardableResult public func submitBlock(_ block: String) throws -> String? {
        return try call(method: "submitBlock", params: [block])
    }

    /// Returns an object with data about the sync status or `false`.
    /// - Returns: An object with sync status data or `false`, when not syncing.
    public func syncing() throws -> Any? {
        let result: SyncStatusOrBool = try call(method: "syncing", params: [])!
        return result.value
    }

    /// Deserializes hex-encoded transaction and returns a transaction object.
    /// - Parameter transaction: The hex encoded signed transaction.
    /// - Returns: The transaction object.
    public func getRawTransactionInfo(transaction: String) throws -> Transaction? {
        return try call(method: "getRawTransactionInfo", params: [transaction])
    }

    /// Resets the constant to default value.
    /// - Parameter constant: Name of the constant.
    /// - Returns: The new value of the constant.
    public func resetConstant(_ constant: String) throws -> Int? {
        return try call(method: "constant", params: [constant, "reset"])
    }
}
