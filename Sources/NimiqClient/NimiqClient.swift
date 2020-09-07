import Foundation

/// Used in convenience initializer in the NimiqClient class.
public struct Config {
    /// Protocol squeme, `"http"` or `"https"`.
    public let scheme: String
    /// Authorized user.
    public let user: String
    /// Password for the authorized user.
    public let password: String
    /// Host IP address.
    public let host: String
    /// Host port.
    public let port: Int

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
}

/// Nimiq JSONRPC Client
public class NimiqClient {

    /// Error returned in the response from the JSONRPC server.
    private struct ResponseError: Decodable {
        var code: Int
        var message: String
    }

    /// Used to decode the JSONRPC response returned by the server.
    private struct Root<T:Decodable>: Decodable {
        var jsonrpc: String
        var result: T?
        var id: Int
        var error: ResponseError?
    }

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
    public init(scheme: String = "http", user: String = "", password: String = "", host: String = "127.0.0.1", port: Int = 8648){
        self.url = "\(scheme)://\(host):\(port)"
        self.auth = "\(user):\(password)".data(using: String.Encoding.utf8)!.base64EncodedString()
        self.session = URLSession.shared
    }

    /// Used in all JSONRPC requests to fetch the data.
    /// - Parameter method: JSONRPC method.
    /// - Parameter params: Parameters used by the request.
    /// - Returns: If succesfull, returns the model reperestation of the result, `nil` otherwise.
    private func call<T:Decodable>(method: String, with params: Any...) throws -> T? {
        var responseObject: Root<T>? = nil
        var clientError: Error? = nil

        // increase the JSONRPC client request id
        id += 1

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
                clientError = Error.internalError(error!.localizedDescription)
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

        return responseObject?.result
    }

    /// Returns a list of addresses owned by client.
    /// - Returns: Array of Accounts owned by the client.
    public func accounts() throws -> [Any]? {
        let result: [RawAccount] = try call(method: "accounts")!
        var converted: [Any] = [Any]()
        for container in result {
            converted.append(container.account)
        }
        return converted
    }

    /// Returns the height of most recent block.
    /// - Returns: The current block height the client is on.
    public func blockNumber() throws -> Int? {
        return try call(method: "blockNumber")
    }

    /// Returns information on the current consensus state.
    /// - Returns: Consensus state. `established` is the value for a good state, other values indicate bad.
    public func consensus() throws -> ConsensusState? {
        return try call(method: "consensus")
    }

    /// Returns the value of the constant.
    /// - Parameter constant: The class and name of the constant (format should be `Class.CONSTANT`).
    /// - Returns: The value of the constant.
    public func constant(_ constant: String) throws -> Int? {
        return try call(method: "constant", with: constant)
    }

    /// Overrides the value of a constant. It sets the constant to the given value. To reset the constant use `resetConstant()` instead.
    /// - Parameter constant: The class and name of the constant (format should be `Class.CONSTANT`).
    /// - Parameter value: The new value of the constant.
    /// - Returns: The new value of the constant.
    public func setConstant(_ constant: String, to value: Int) throws -> Int? {
        return try call(method: "constant", with: constant, value)
    }

    /// Creates a new account and stores its private key in the client store.
    /// - Returns: Information on the wallet that was created using the command.
    public func createAccount() throws -> Wallet? {
        return try call(method: "createAccount")
    }

    /// Creates and signs a transaction without sending it. The transaction can then be send via `sendRawTransaction()` without accidentally replaying it.
    /// - Parameter transaction: The transaction object.
    /// - Returns: Hex-encoded transaction.
    public func createRawTransaction(from transaction: OutgoingTransaction) throws -> String? {
        let params:[String:Any?] = [
            "from": transaction.from,
            "fromType": transaction.fromType?.rawValue,
            "to": transaction.to,
            "toType": transaction.toType?.rawValue,
            "value": transaction.value,
            "fee": transaction.fee,
            "data": transaction.data
        ]
        return try call(method: "createRawTransaction", with: params)
    }

    /// Returns details for the account of given address.
    /// - Parameter address: Address to get account details.
    /// - Returns: Details about the account. Returns the default empty basic account for non-existing accounts.
    public func getAccount(forAddress address: String) throws -> Any? {
        let result: RawAccount = try call(method: "getAccount", with: address)!
        return result.account
    }

    /// Returns the balance of the account of given address.
    /// - Parameter address: Address to check for balance.
    /// - Returns: The current balance at the specified address (in smalest unit).
    public func getBalance(forAddress address: String) throws -> Int? {
        return try call(method: "getBalance", with: address)
    }

    /// Returns information about a block by hash.
    /// - Parameter hash: Hash of the block to gather information on.
    /// - Parameter withTransactions: If `true` it returns the full transaction objects, if `false` only the hashes of the transactions.
    /// - Returns: A block object or `nil` when no block was found.
    public func getBlock(forHash hash: String, withTransactions: Bool? = nil) throws -> Block? {
        if withTransactions != nil {
            return try call(method: "getBlockByHash", with: hash, withTransactions!)
        } else {
            return try call(method: "getBlockByHash", with: hash)
        }
    }

    /// Returns information about a block by block number.
    /// - Parameter height: The height of the block to gather information on.
    /// - Parameter withTransactions: If `true` it returns the full transaction objects, if `false` only the hashes of the transactions.
    /// - Returns: A block object or `nil` when no block was found.
    public func getBlock(atHeight height: Int, withTransactions: Bool? = nil) throws -> Block? {
        if withTransactions != nil {
            return try call(method: "getBlockByNumber", with: height, withTransactions!)
        } else {
            return try call(method: "getBlockByNumber", with: height)
        }
    }

    /// Returns a template to build the next block for mining. This will consider pool instructions when connected to a pool.
    /// If `address` and `extraData` are provided the values are overriden.
    /// - Parameter address: The address to use as a miner for this block. This overrides the address provided during startup or from the pool.
    /// - Parameter extraData: Hex-encoded value for the extra data field. This overrides the extra data provided during startup or from the pool.
    /// - Returns: A block template object.
    public func getBlockTemplate(forAddress address: String? = nil, withExtraData extraData: String = "") throws -> BlockTemplate? {
        if address != nil {
            return try call(method: "getBlockTemplate", with: address!, extraData)
        } else {
            return try call(method: "getBlockTemplate")
        }
    }

    /// Returns the number of transactions in a block from a block matching the given block hash.
    /// - Parameter hash: Hash of the block.
    /// - Returns: Number of transactions in the block found, or `nil`, when no block was found.
    public func getBlockTransactionCount(forHash hash: String) throws -> Int? {
        return try call(method: "getBlockTransactionCountByHash", with: hash)
    }

    /// Returns the number of transactions in a block matching the given block number.
    /// - Parameter height: Height of the block.
    /// - Returns: Number of transactions in the block found, or `nil`, when no block was found.
    public func getBlockTransactionCount(atHeight height: Int) throws -> Int? {
        return try call(method: "getBlockTransactionCountByNumber", with: height)
    }

    /// Returns information about a transaction by block hash and transaction index position.
    /// - Parameter hash: Hash of the block containing the transaction.
    /// - Parameter index: Index of the transaction in the block.
    /// - Returns: A transaction object or `nil` when no transaction was found.
    public func getTransactionInBlock(forHash hash: String, index: Int) throws -> Transaction? {
        return try call(method: "getTransactionByBlockHashAndIndex", with: hash, index)
    }

    /// Returns information about a transaction by block number and transaction index position.
    /// - Parameter height: Height of the block containing the transaction.
    /// - Parameter index: Index of the transaction in the block.
    /// - Returns: A transaction object or `nil` when no transaction was found.
    public func getTransactionInBlock(atHeight height: Int, index: Int) throws -> Transaction? {
        return try call(method: "getTransactionByBlockNumberAndIndex", with: height, index)
    }

    /// Returns the information about a transaction requested by transaction hash.
    /// - Parameter hash: Hash of a transaction.
    /// - Returns: A transaction object or `nil` when no transaction was found.
    public func getTransaction(forHash hash: String) throws -> Transaction? {
        return try call(method: "getTransactionByHash", with: hash)
    }

    /// Returns the receipt of a transaction by transaction hash.
    /// - Parameter hash: Hash of a transaction.
    /// - Returns: A transaction receipt object, or `nil` when no receipt was found.
    public func getTransactionReceipt(forHash hash: String) throws -> TransactionReceipt? {
        return try call(method: "getTransactionReceipt", with: hash)
    }

    /// Returns the latest transactions successfully performed by or for an address.
    /// Note that this information might change when blocks are rewinded on the local state due to forks.
    /// - Parameter address: Address of which transactions should be gathered.
    /// - Parameter numberOfTransactions: Number of transactions that shall be returned.
    /// - Returns: Array of transactions linked to the requested address.
    public func getTransactions(forAddress address: String, numberOfTransactions: Int? = nil) throws -> [Transaction]? {
        if numberOfTransactions != nil {
            return try call(method: "getTransactionsByAddress", with: address, numberOfTransactions!)
        } else {
            return try call(method: "getTransactionsByAddress", with: address)
        }
    }

    /// Returns instructions to mine the next block. This will consider pool instructions when connected to a pool.
    /// - Parameter address: The address to use as a miner for this block. This overrides the address provided during startup or from the pool.
    /// - Parameter extraData: Hex-encoded value for the extra data field. This overrides the extra data provided during startup or from the pool.
    /// - Returns: Mining work instructions.
    public func getWork(forAddress address: String? = nil, withExtraData extraData: String = "") throws -> WorkInstructions? {
        if address != nil {
            return try call(method: "getWork", with: address!, extraData)
        }
        return try call(method: "getWork")
    }

    /// Returns the number of hashes per second that the node is mining with.
    /// - Returns: Number of hashes per second.
    public func hashrate() throws -> Float? {
        return try call(method: "hashrate")
    }

    /// Sets the log level of the node.
    /// - Parameter tag: Tag: If `"*"` the log level is set globally, otherwise the log level is applied only on this tag.
    /// - Parameter level: Minimum log level to display.
    /// - Returns: `true` if the log level was changed, `false` otherwise.
    public func setLog(tag: String, to level: LogLevel) throws -> Bool? {
        return try call(method: "log", with: tag, level.rawValue)
    }

    /// Returns information on the current mempool situation. This will provide an overview of the number of transactions sorted into buckets based on their fee per byte (in smallest unit).
    /// - Returns: Mempool information.
    public func mempool() throws -> MempoolInfo? {
        return try call(method: "mempool")
    }

    /// Returns transactions that are currently in the mempool.
    /// - Parameter withTransactions: If `true` includes full transactions, if `false` includes only transaction hashes.
    /// - Returns: Array of transactions (either represented by the transaction hash or a transaction object).
    public func mempoolContent(withTransactions: Bool? = nil) throws -> [Any]? {
        var result: [HashOrTransaction]
        if withTransactions != nil {
            result = try call(method: "mempoolContent", with: withTransactions!)!
        } else {
            result = try call(method: "mempoolContent")!
        }
        return result.map { tx in tx.transaction }
    }

    /// Returns the miner address.
    /// - Returns: The miner address configured on the node.
    public func minerAddress() throws -> String? {
        return try call(method: "minerAddress")
    }

    /// Returns the number of CPU threads for the miner.
    /// - Returns: The number of threads allocated for mining.
    public func minerThreads() throws -> Int? {
        return try call(method: "minerThreads")
    }

    /// Sets the number of CPU threads for the miner.
    /// - Parameter threads: The number of threads to allocate for mining.
    /// - Returns: The new number of threads allocated for mining.
    public func setMinerThreads(to threads: Int) throws -> Int? {
        return try call(method: "minerThreads", with: threads)
    }

    /// Returns the minimum fee per byte.
    /// - Returns: The new minimum fee per byte.
    public func minFeePerByte() throws -> Int? {
        return try call(method: "minFeePerByte")
    }

    /// Sets the minimum fee per byte.
    /// - Parameter fee: The new minimum fee per byte.
    /// - Returns: The new minimum fee per byte.
    public func setMinFeePerByte(to fee: Int) throws -> Int? {
        return try call(method: "minFeePerByte", with: fee)
    }

    /// Returns true if client is actively mining new blocks.
    /// - Returns: `true` if the client is mining, otherwise `false`.
    public func isMining() throws -> Bool? {
        return try call(method: "mining")
    }

    /// Sets the client mining state.
    /// - Parameter state: The state to be set.
    /// - Returns: `true` if the client is mining, otherwise `false`.
    public func setMining(to state: Bool) throws -> Bool? {
        return try call(method: "mining", with: state)
    }

    /// Returns number of peers currently connected to the client.
    /// - Returns: Number of connected peers.
    public func peerCount() throws -> Int? {
        return try call(method: "peerCount")
    }

    /// Returns list of peers known to the client.
    /// - Returns: The list of peers.
    public func peerList() throws -> [Peer]? {
        return try call(method: "peerList")
    }

    /// Returns the state of the peer.
    /// - Parameter address: The address of the peer.
    /// - Returns: The current state of the peer.
    public func peerState(forAddress address: String) throws -> Peer? {
        return try call(method: "peerState", with: address)
    }

    /// Sets the state of the peer.
    /// - Parameter address: The address of the peer.
    /// - Parameter command: The command to send.
    /// - Returns: The new state of the peer.
    public func setPeerState(forAddress address: String, to command: PeerStateCommand) throws -> Peer? {
        return try call(method: "peerState", with: address, command.rawValue)
    }

    /// Returns the mining pool.
    /// - Returns: The mining pool connection string, or `nil` if not enabled.
    public func pool() throws -> String? {
        return try call(method: "pool")
    }

    /// Sets the mining pool.
    /// - Parameter address: The mining pool connection string (`url:port`) or boolean to enable/disable pool mining.
    /// - Returns: The new mining pool connection string, or `nil` if not enabled.
    public func setPool(toAddress address: Any) throws -> String? {
        return try call(method: "pool", with: address)
    }

    /// Returns the confirmed mining pool balance.
    /// - Returns: The confirmed mining pool balance (in smallest unit).
    public func poolConfirmedBalance() throws -> Int? {
        return try call(method: "poolConfirmedBalance")
    }

    /// Returns the connection state to mining pool.
    /// - Returns: The mining pool connection state.
    public func poolConnectionState() throws -> PoolConnectionState? {
        return try call(method: "poolConnectionState")
    }

    /// Sends a signed message call transaction or a contract creation, if the data field contains code.
    /// - Parameter transaction: The hex encoded signed transaction
    /// - Returns: The Hex-encoded transaction hash.
    public func sendRawTransaction(_ transaction: String) throws -> String? {
        return try call(method: "sendRawTransaction", with: transaction)
    }

    /// Creates new message call transaction or a contract creation, if the data field contains code.
    /// - Parameter transaction: The hex encoded signed transaction
    /// - Returns: The Hex-encoded transaction hash.
    public func sendTransaction(_ transaction: OutgoingTransaction) throws -> String? {
        let params:[String:Any?] = [
            "from": transaction.from,
            "fromType": transaction.fromType?.rawValue,
            "to": transaction.to,
            "toType": transaction.toType?.rawValue,
            "value": transaction.value,
            "fee": transaction.fee,
            "data": transaction.data
        ]
        return try call(method: "sendTransaction", with: params)
    }

    /// Submits a block to the node. When the block is valid, the node will forward it to other nodes in the network.
    /// - Parameter block: Hex-encoded full block (including header, interlink and body). When submitting work from getWork, remember to include the suffix.
    /// - Returns: Always `nil`.
    @discardableResult public func submitBlock(_ block: String) throws -> String? {
        return try call(method: "submitBlock", with: block)
    }

    /// Returns an object with data about the sync status or `false`.
    /// - Returns: An object with sync status data or `false`, when not syncing.
    public func syncing() throws -> Any? {
        let result: SyncStatusOrBool = try call(method: "syncing")!
        return result.syncStatus
    }

    /// Deserializes hex-encoded transaction and returns a transaction object.
    /// - Parameter transaction: The hex encoded signed transaction.
    /// - Returns: The transaction object.
    public func getRawTransactionInfo(from transaction: String) throws -> Transaction? {
        return try call(method: "getRawTransactionInfo", with: transaction)
    }

    /// Resets the constant to default value.
    /// - Parameter constant: Name of the constant.
    /// - Returns: The new value of the constant.
    public func resetConstant(_ constant: String) throws -> Int? {
        return try call(method: "constant", with: constant, "reset")
    }
}
