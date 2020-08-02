import XCTest
@testable import NimiqClient

final class NimiqClientTests: XCTestCase {

    var client: NimiqClient!

    override func setUp() {
        super.setUp()

        // set up a configuration for the stub
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]

        // create URLSession from configuration
        let session = URLSession(configuration: config)

        // init our JSON RPC client with that
        client = NimiqClient(scheme: "http", user: "user", password: "password", host: "127.0.0.1", port: 8648, session: session)

    }

    override func tearDown() {
        super.tearDown()
    }

    func test_peerCount() {
        URLProtocolStub.testData = Fixtures.peerCount()

        let result = try? client.peerCount()

        XCTAssertEqual("peerCount", URLProtocolStub.latestRequestMethod!)

        XCTAssertEqual(6, result)
    }

    func test_syncingStateWhenSyncing() {
        URLProtocolStub.testData = Fixtures.syncing()

        let result = try? client.syncing()

        XCTAssertEqual("syncing", URLProtocolStub.latestRequestMethod!)

        XCTAssert(result is SyncStatus)
        let syncing = result as! SyncStatus
        XCTAssertEqual(578430, syncing.startingBlock)
        XCTAssertEqual(586493, syncing.currentBlock)
        XCTAssertEqual(586493, syncing.highestBlock)
    }

    func test_syncingStateWhenNotSyncing() {
        URLProtocolStub.testData = Fixtures.syncingNotSyncing()

        let result = try? client.syncing()

        XCTAssertEqual("syncing", URLProtocolStub.latestRequestMethod!)

        XCTAssert(result is Bool)
        let syncing = result as! Bool
        XCTAssertEqual(false, syncing)
    }

    func test_consensusState() {
        URLProtocolStub.testData = Fixtures.consensusSyncing()

        let result = try? client.consensus()

        XCTAssertEqual("consensus", URLProtocolStub.latestRequestMethod!)

        XCTAssertEqual(ConsensusState.syncing, result)
    }

    func test_peerListWithPeers() {
        URLProtocolStub.testData = Fixtures.peerList()

        let result = try? client.peerList()

        XCTAssertEqual("peerList", URLProtocolStub.latestRequestMethod!)

        XCTAssertEqual(result?.count, 2)
        XCTAssertNotNil(result?[0])
        XCTAssertEqual("b99034c552e9c0fd34eb95c1cdf17f5e", result?[0].id)
        XCTAssertEqual("wss://seed1.nimiq-testnet.com:8080/b99034c552e9c0fd34eb95c1cdf17f5e", result?[0].address)
        XCTAssertEqual(PeerAddressState.established, result?[0].addressState)
        XCTAssertEqual(PeerConnectionState.established, result?[0].connectionState)

        XCTAssertNotNil(result?[1])
        XCTAssertEqual("e37dca72802c972d45b37735e9595cf0", result?[1].id)
        XCTAssertEqual("wss://seed4.nimiq-testnet.com:8080/e37dca72802c972d45b37735e9595cf0", result?[1].address)
        XCTAssertEqual(PeerAddressState.failed, result?[1].addressState)
        XCTAssertEqual(nil, result?[1].connectionState)
    }

    func test_peerListWhenEmpty() {
        URLProtocolStub.testData = Fixtures.peerListEmpty()

        let result = try? client.peerList()

        XCTAssertEqual("peerList", URLProtocolStub.latestRequestMethod!)

        XCTAssertEqual(result?.count, 0)
    }

    func test_peerNormal() {
        URLProtocolStub.testData = Fixtures.peerStateNormal()

        let result = try? client.peerState(address: "wss://seed1.nimiq-testnet.com:8080/b99034c552e9c0fd34eb95c1cdf17f5e")

        XCTAssertEqual("peerState", URLProtocolStub.latestRequestMethod!)
        XCTAssertEqual("wss://seed1.nimiq-testnet.com:8080/b99034c552e9c0fd34eb95c1cdf17f5e", URLProtocolStub.latestRequestParams![0] as? String)

        XCTAssertNotNil(result)
        XCTAssertEqual("b99034c552e9c0fd34eb95c1cdf17f5e", result?.id)
        XCTAssertEqual("wss://seed1.nimiq-testnet.com:8080/b99034c552e9c0fd34eb95c1cdf17f5e", result?.address)
        XCTAssertEqual(PeerAddressState.established, result?.addressState)
        XCTAssertEqual(PeerConnectionState.established, result?.connectionState)
    }

    func test_peerFailed() {
        URLProtocolStub.testData = Fixtures.peerStateFailed()

        let result = try? client.peerState(address: "wss://seed4.nimiq-testnet.com:8080/e37dca72802c972d45b37735e9595cf0")

        XCTAssertEqual("peerState", URLProtocolStub.latestRequestMethod!)
        XCTAssertEqual("wss://seed4.nimiq-testnet.com:8080/e37dca72802c972d45b37735e9595cf0", URLProtocolStub.latestRequestParams![0] as? String)

        XCTAssertNotNil(result)
        XCTAssertEqual("e37dca72802c972d45b37735e9595cf0", result?.id)
        XCTAssertEqual("wss://seed4.nimiq-testnet.com:8080/e37dca72802c972d45b37735e9595cf0", result?.address)
        XCTAssertEqual(PeerAddressState.failed, result?.addressState)
        XCTAssertEqual(nil, result?.connectionState)
    }

    func test_peerError() {
        URLProtocolStub.testData = Fixtures.peerStateError()

        XCTAssertThrowsError(try client.peerState(address: "unknown")) { error in
            guard case Error.remoteError( _) = error else {
                return XCTFail()
            }
        }
    }

    func test_setPeerNormal() {
        URLProtocolStub.testData = Fixtures.peerStateNormal()

        let result = try? client.peerState(address: "wss://seed1.nimiq-testnet.com:8080/b99034c552e9c0fd34eb95c1cdf17f5e", command: PeerStateCommand.connect)

        XCTAssertEqual("peerState", URLProtocolStub.latestRequestMethod!)
        XCTAssertEqual("wss://seed1.nimiq-testnet.com:8080/b99034c552e9c0fd34eb95c1cdf17f5e", URLProtocolStub.latestRequestParams![0] as? String)
        XCTAssertEqual("connect", URLProtocolStub.latestRequestParams![1] as? String)

        XCTAssertNotNil(result)
        XCTAssertEqual("b99034c552e9c0fd34eb95c1cdf17f5e", result?.id)
        XCTAssertEqual("wss://seed1.nimiq-testnet.com:8080/b99034c552e9c0fd34eb95c1cdf17f5e", result?.address)
        XCTAssertEqual(PeerAddressState.established, result?.addressState)
        XCTAssertEqual(PeerConnectionState.established, result?.connectionState)
    }

    func test_sendRawTransaction() {
        URLProtocolStub.testData = Fixtures.sendTransaction()

        let result = try? client.sendRawTransaction("00c3c0d1af80b84c3b3de4e3d79d5c8cc950e044098c969953d68bf9cee68d7b53305dbaac7514a06dae935e40d599caf1bd8a243c00000000000000010000000000000001000dc2e201b5a1755aec80aa4227d5afc6b0de0fcfede8541f31b3c07b9a85449ea9926c1c958628d85a2b481556034ab3d67ff7de28772520813c84aaaf8108f6297c580c")

        XCTAssertEqual("sendRawTransaction", URLProtocolStub.latestRequestMethod!)
        XCTAssertEqual("00c3c0d1af80b84c3b3de4e3d79d5c8cc950e044098c969953d68bf9cee68d7b53305dbaac7514a06dae935e40d599caf1bd8a243c00000000000000010000000000000001000dc2e201b5a1755aec80aa4227d5afc6b0de0fcfede8541f31b3c07b9a85449ea9926c1c958628d85a2b481556034ab3d67ff7de28772520813c84aaaf8108f6297c580c", URLProtocolStub.latestRequestParams![0] as? String)

        XCTAssertEqual("81cf3f07b6b0646bb16833d57cda801ad5957e264b64705edeef6191fea0ad63", result)
    }

    func test_createRawTransaction() {
        URLProtocolStub.testData = Fixtures.createRawTransactionBasic()

        let transaction = OutgoingTransaction(
            from: "NQ39 NY67 X0F0 UTQE 0YER 4JEU B67L UPP8 G0FM",
            fromType: AccountType.basic,
            to: "NQ16 61ET MB3M 2JG6 TBLK BR0D B6EA X6XQ L91U",
            toType: AccountType.basic,
            value: 100000,
            fee: 1
        )

        let result = try? client.createRawTransaction(transaction)

        XCTAssertEqual("createRawTransaction", URLProtocolStub.latestRequestMethod!)

        let param = URLProtocolStub.latestRequestParams![0] as! [String: Any]
        XCTAssert(NSDictionary(dictionary: param).isEqual(to: [
            "from": "NQ39 NY67 X0F0 UTQE 0YER 4JEU B67L UPP8 G0FM",
            "fromType": 0,
            "to": "NQ16 61ET MB3M 2JG6 TBLK BR0D B6EA X6XQ L91U",
            "toType": 0,
            "value": 100000,
            "fee": 1,
            "data": nil
            ] as [String: Any?] as [AnyHashable : Any]))

        XCTAssertEqual("00c3c0d1af80b84c3b3de4e3d79d5c8cc950e044098c969953d68bf9cee68d7b53305dbaac7514a06dae935e40d599caf1bd8a243c00000000000186a00000000000000001000af84c01239b16cee089836c2af5c7b1dbb22cdc0b4864349f7f3805909aa8cf24e4c1ff0461832e86f3624778a867d5f2ba318f92918ada7ae28d70d40c4ef1d6413802", result)
    }

    func test_sendTransaction() {
        URLProtocolStub.testData = Fixtures.sendTransaction()

        let transaction = OutgoingTransaction(
            from: "NQ39 NY67 X0F0 UTQE 0YER 4JEU B67L UPP8 G0FM",
            fromType: AccountType.basic,
            to: "NQ16 61ET MB3M 2JG6 TBLK BR0D B6EA X6XQ L91U",
            toType: AccountType.basic,
            value: 1,
            fee: 1
        )

        let result = try? client.sendTransaction(transaction)

        XCTAssertEqual("sendTransaction", URLProtocolStub.latestRequestMethod!)

        let param = URLProtocolStub.latestRequestParams![0] as! [String: Any]
        XCTAssert(NSDictionary(dictionary: param).isEqual(to: [
            "from": "NQ39 NY67 X0F0 UTQE 0YER 4JEU B67L UPP8 G0FM",
            "fromType": 0,
            "to": "NQ16 61ET MB3M 2JG6 TBLK BR0D B6EA X6XQ L91U",
            "toType": 0,
            "value": 1,
            "fee": 1,
            "data": nil
            ] as [String: Any?] as [AnyHashable : Any]))

        XCTAssertEqual("81cf3f07b6b0646bb16833d57cda801ad5957e264b64705edeef6191fea0ad63", result)
    }

    func test_getRawTransactionInfo() {
        URLProtocolStub.testData = Fixtures.getRawTransactionInfoBasic()

        let result = try? client.getRawTransactionInfo(transaction: "00c3c0d1af80b84c3b3de4e3d79d5c8cc950e044098c969953d68bf9cee68d7b53305dbaac7514a06dae935e40d599caf1bd8a243c00000000000186a00000000000000001000af84c01239b16cee089836c2af5c7b1dbb22cdc0b4864349f7f3805909aa8cf24e4c1ff0461832e86f3624778a867d5f2ba318f92918ada7ae28d70d40c4ef1d6413802")

        XCTAssertEqual("getRawTransactionInfo", URLProtocolStub.latestRequestMethod!)
        XCTAssertEqual("00c3c0d1af80b84c3b3de4e3d79d5c8cc950e044098c969953d68bf9cee68d7b53305dbaac7514a06dae935e40d599caf1bd8a243c00000000000186a00000000000000001000af84c01239b16cee089836c2af5c7b1dbb22cdc0b4864349f7f3805909aa8cf24e4c1ff0461832e86f3624778a867d5f2ba318f92918ada7ae28d70d40c4ef1d6413802", URLProtocolStub.latestRequestParams![0] as? String)

        XCTAssertNotNil(result)
        XCTAssertEqual("7784f2f6eaa076fa5cf0e4d06311ad204b2f485de622231785451181e8129091", result?.hash)
        XCTAssertEqual("b7cc7f01e0e6f0e07dd9249dc598f4e5ee8801f5", result?.from)
        XCTAssertEqual("NQ39 NY67 X0F0 UTQE 0YER 4JEU B67L UPP8 G0FM", result?.fromAddress)
        XCTAssertEqual("305dbaac7514a06dae935e40d599caf1bd8a243c", result?.to)
        XCTAssertEqual("NQ16 61ET MB3M 2JG6 TBLK BR0D B6EA X6XQ L91U", result?.toAddress)
        XCTAssertEqual(100000, result?.value)
        XCTAssertEqual(1, result?.fee)
    }

    func test_getTransactionByBlockHashAndIndex() {
        URLProtocolStub.testData = Fixtures.getTransactionFull()

        let result = try? client.getTransactionByBlockHashAndIndex(hash: "bc3945d22c9f6441409a6e539728534a4fc97859bda87333071fad9dad942786", index: 0)

        XCTAssertEqual("getTransactionByBlockHashAndIndex", URLProtocolStub.latestRequestMethod!)
        XCTAssertEqual("bc3945d22c9f6441409a6e539728534a4fc97859bda87333071fad9dad942786", URLProtocolStub.latestRequestParams![0] as? String)
        XCTAssertEqual(0, URLProtocolStub.latestRequestParams![1] as? Int)

        XCTAssertNotNil(result)
        XCTAssertEqual("78957b87ab5546e11e9540ce5a37ebbf93a0ebd73c0ce05f137288f30ee9f430", result?.hash)
        XCTAssertEqual("bc3945d22c9f6441409a6e539728534a4fc97859bda87333071fad9dad942786", result?.blockHash)
        XCTAssertEqual(0, result?.transactionIndex)
        XCTAssertEqual("355b4fe2304a9c818b9f0c3c1aaaf4ad4f6a0279", result?.from)
        XCTAssertEqual("NQ16 6MDL YQHG 9AE8 32UY 1GX1 MAPL MM7N L0KR", result?.fromAddress)
        XCTAssertEqual("4f61c06feeb7971af6997125fe40d629c01af92f", result?.to)
        XCTAssertEqual("NQ05 9VGU 0TYE NXBH MVLR E4JY UG6N 5701 MX9F", result?.toAddress)
        XCTAssertEqual(2636710000, result?.value)
        XCTAssertEqual(0, result?.fee)
    }

    func test_getTransactionByBlockHashAndIndexWhenNotFound() {
        URLProtocolStub.testData = Fixtures.getTransactionNotFound()

        let result = try? client.getTransactionByBlockHashAndIndex(hash: "bc3945d22c9f6441409a6e539728534a4fc97859bda87333071fad9dad942786", index: 5)

        XCTAssertEqual("getTransactionByBlockHashAndIndex", URLProtocolStub.latestRequestMethod!)
        XCTAssertEqual("bc3945d22c9f6441409a6e539728534a4fc97859bda87333071fad9dad942786", URLProtocolStub.latestRequestParams![0] as? String)
        XCTAssertEqual(5, URLProtocolStub.latestRequestParams![1] as? Int)

        XCTAssertNil(result)
    }

    func test_getTransactionByBlockNumberAndIndex() {
        URLProtocolStub.testData = Fixtures.getTransactionFull()

        let result = try? client.getTransactionByBlockNumberAndIndex(height: 11608, index: 0)

        XCTAssertEqual("getTransactionByBlockNumberAndIndex", URLProtocolStub.latestRequestMethod!)
        XCTAssertEqual(11608, URLProtocolStub.latestRequestParams![0] as? Int)
        XCTAssertEqual(0, URLProtocolStub.latestRequestParams![1] as? Int)

        XCTAssertNotNil(result)
        XCTAssertEqual("78957b87ab5546e11e9540ce5a37ebbf93a0ebd73c0ce05f137288f30ee9f430", result?.hash)
        XCTAssertEqual(11608, result?.blockNumber)
        XCTAssertEqual(0, result?.transactionIndex)
        XCTAssertEqual("355b4fe2304a9c818b9f0c3c1aaaf4ad4f6a0279", result?.from)
        XCTAssertEqual("NQ16 6MDL YQHG 9AE8 32UY 1GX1 MAPL MM7N L0KR", result?.fromAddress)
        XCTAssertEqual("4f61c06feeb7971af6997125fe40d629c01af92f", result?.to)
        XCTAssertEqual("NQ05 9VGU 0TYE NXBH MVLR E4JY UG6N 5701 MX9F", result?.toAddress)
        XCTAssertEqual(2636710000, result?.value)
        XCTAssertEqual(0, result?.fee)
    }

    func test_getTransactionByBlockNumberAndIndexWhenNotFound() {
        URLProtocolStub.testData = Fixtures.getTransactionNotFound()

        let result = try? client.getTransactionByBlockNumberAndIndex(height: 11608, index: 0)

        XCTAssertEqual("getTransactionByBlockNumberAndIndex", URLProtocolStub.latestRequestMethod!)
        XCTAssertEqual(11608, URLProtocolStub.latestRequestParams![0] as? Int)
        XCTAssertEqual(0, URLProtocolStub.latestRequestParams![1] as? Int)

        XCTAssertNil(result)
    }

    func test_getTransactionByHash() {
        URLProtocolStub.testData = Fixtures.getTransactionFull()

        let result = try? client.getTransactionByHash("78957b87ab5546e11e9540ce5a37ebbf93a0ebd73c0ce05f137288f30ee9f430")

        XCTAssertEqual("getTransactionByHash", URLProtocolStub.latestRequestMethod!)
        XCTAssertEqual("78957b87ab5546e11e9540ce5a37ebbf93a0ebd73c0ce05f137288f30ee9f430", URLProtocolStub.latestRequestParams![0] as? String)

        XCTAssertNotNil(result)
        XCTAssertEqual("78957b87ab5546e11e9540ce5a37ebbf93a0ebd73c0ce05f137288f30ee9f430", result?.hash)
        XCTAssertEqual(11608, result?.blockNumber)
        XCTAssertEqual("355b4fe2304a9c818b9f0c3c1aaaf4ad4f6a0279", result?.from)
        XCTAssertEqual("NQ16 6MDL YQHG 9AE8 32UY 1GX1 MAPL MM7N L0KR", result?.fromAddress)
        XCTAssertEqual("4f61c06feeb7971af6997125fe40d629c01af92f", result?.to)
        XCTAssertEqual("NQ05 9VGU 0TYE NXBH MVLR E4JY UG6N 5701 MX9F", result?.toAddress)
        XCTAssertEqual(2636710000, result?.value)
        XCTAssertEqual(0, result?.fee)
    }

    func test_getTransactionByHashWhenNotFound() {
        URLProtocolStub.testData = Fixtures.getTransactionNotFound()

        let result = try? client.getTransactionByHash("78957b87ab5546e11e9540ce5a37ebbf93a0ebd73c0ce05f137288f30ee9f430")

        XCTAssertEqual("getTransactionByHash", URLProtocolStub.latestRequestMethod!)
        XCTAssertEqual("78957b87ab5546e11e9540ce5a37ebbf93a0ebd73c0ce05f137288f30ee9f430", URLProtocolStub.latestRequestParams![0] as? String)

        XCTAssertNil(result)
    }

    func test_getTransactionByHashForContractCreation() {
        URLProtocolStub.testData = Fixtures.getTransactionContractCreation()

        let result = try? client.getTransactionByHash("539f6172b19f63be376ab7e962c368bb5f611deff6b159152c4cdf509f7daad2")

        XCTAssertEqual("getTransactionByHash", URLProtocolStub.latestRequestMethod!)
        XCTAssertEqual("539f6172b19f63be376ab7e962c368bb5f611deff6b159152c4cdf509f7daad2", URLProtocolStub.latestRequestParams![0] as? String)

        XCTAssertNotNil(result)
        XCTAssertEqual("539f6172b19f63be376ab7e962c368bb5f611deff6b159152c4cdf509f7daad2", result?.hash)
        XCTAssertEqual("96fef80f517f0b2704476dee48da147049b591e8f034e5bf93f1f6935fd51b85", result?.blockHash)
        XCTAssertEqual(1102500, result?.blockNumber)
        XCTAssertEqual(1590148157, result?.timestamp)
        XCTAssertEqual(7115, result?.confirmations)
        XCTAssertEqual("d62d519b3478c63bdd729cf2ccb863178060c64a", result?.from)
        XCTAssertEqual("NQ53 SQNM 36RL F333 PPBJ KKRC RE33 2X06 1HJA", result?.fromAddress)
        XCTAssertEqual("a22eaf17848130c9b370e42ff7d345680df245e1", result?.to)
        XCTAssertEqual("NQ87 L8PA X5U4 G4QC KCTG UGPY FLS5 D06Y 4HF1", result?.toAddress)
        XCTAssertEqual(5000000000, result?.value)
        XCTAssertEqual(0, result?.fee)
        XCTAssertEqual("d62d519b3478c63bdd729cf2ccb863178060c64af5ad55071730d3b9f05989481eefbda7324a44f8030c63b9444960db429081543939166f05116cebc37bd6975ac9f9e3bb43a5ab0b010010d2de", result?.data)
        XCTAssertEqual(1, result?.flags)
    }

    func test_getTransactionReceipt() {
        URLProtocolStub.testData = Fixtures.getTransactionReceiptFound()

        let result = try? client.getTransactionReceipt(hash: "fd8e46ae55c5b8cd7cb086cf8d6c81f941a516d6148021d55f912fb2ca75cc8e")

        XCTAssertEqual("getTransactionReceipt", URLProtocolStub.latestRequestMethod!)
        XCTAssertEqual("fd8e46ae55c5b8cd7cb086cf8d6c81f941a516d6148021d55f912fb2ca75cc8e", URLProtocolStub.latestRequestParams![0] as? String)

        XCTAssertNotNil(result)
        XCTAssertEqual("fd8e46ae55c5b8cd7cb086cf8d6c81f941a516d6148021d55f912fb2ca75cc8e", result?.transactionHash)
        XCTAssertEqual(-1, result?.transactionIndex)
        XCTAssertEqual(11608, result?.blockNumber)
        XCTAssertEqual("bc3945d22c9f6441409a6e539728534a4fc97859bda87333071fad9dad942786", result?.blockHash)
        XCTAssertEqual(1523412456, result?.timestamp)
        XCTAssertEqual(718846, result?.confirmations)
    }

    func test_getTransactionReceiptWhenNotFound() {
        URLProtocolStub.testData = Fixtures.getTransactionReceiptNotFound()

        let result = try? client.getTransactionReceipt(hash: "unknown")

        XCTAssertEqual("getTransactionReceipt", URLProtocolStub.latestRequestMethod!)
        XCTAssertEqual("unknown", URLProtocolStub.latestRequestParams![0] as? String)

        XCTAssertNil(result)
    }

    func test_getTransactionsByAddress() {
        URLProtocolStub.testData = Fixtures.getTransactionsFound()

        let result = try? client.getTransactionsByAddress("NQ05 9VGU 0TYE NXBH MVLR E4JY UG6N 5701 MX9F")

        XCTAssertEqual("getTransactionsByAddress", URLProtocolStub.latestRequestMethod!)
        XCTAssertEqual("NQ05 9VGU 0TYE NXBH MVLR E4JY UG6N 5701 MX9F", URLProtocolStub.latestRequestParams![0] as? String)

        XCTAssertEqual(3, result?.count)
        XCTAssertNotNil(result?[0])
        XCTAssertEqual("a514abb3ee4d3fbedf8a91156fb9ec4fdaf32f0d3d3da3c1dbc5fd1ee48db43e", result?[0].hash)
        XCTAssertNotNil(result?[1])
        XCTAssertEqual("c8c0f586b11c7f39873c3de08610d63e8bec1ceaeba5e8a3bb13c709b2935f73", result?[1].hash)
        XCTAssertNotNil(result?[2])
        XCTAssertEqual("fd8e46ae55c5b8cd7cb086cf8d6c81f941a516d6148021d55f912fb2ca75cc8e", result?[2].hash)
    }

    func test_getTransactionsByAddressWhenNoFound() {
        URLProtocolStub.testData = Fixtures.getTransactionsNotFound()

        let result = try? client.getTransactionsByAddress("NQ10 9VGU 0TYE NXBH MVLR E4JY UG6N 5701 MX9F")

        XCTAssertEqual("getTransactionsByAddress", URLProtocolStub.latestRequestMethod!)
        XCTAssertEqual("NQ10 9VGU 0TYE NXBH MVLR E4JY UG6N 5701 MX9F", URLProtocolStub.latestRequestParams![0] as? String)

        XCTAssertEqual(0, result?.count)
    }

    func test_mempoolContentHashesOnly() {
        URLProtocolStub.testData = Fixtures.mempoolContentHashesOnly()

        let result = try? client.mempoolContent()

        XCTAssertEqual("mempoolContent", URLProtocolStub.latestRequestMethod!)
        XCTAssertEqual(false, URLProtocolStub.latestRequestParams![0] as? Bool)

        XCTAssertEqual(3, result?.count)
        XCTAssertNotNil(result?[0])
        XCTAssertEqual("5bb722c2afe25c18ba33d453b3ac2c90ac278c595cc92f6188c8b699e8fb006a", result?[0] as? String)
        XCTAssertNotNil(result?[1])
        XCTAssertEqual("f59a30e0a7e3348ef569225db1f4c29026aeac4350f8c6e751f669eddce0c718", result?[1] as? String)
        XCTAssertNotNil(result?[2])
        XCTAssertEqual("9cd9c1d0ffcaebfcfe86bc2ae73b4e82a488de99c8e3faef92b05432bb94519c", result?[2] as? String)
    }

    func test_mempoolContentFullTransactions() {
        URLProtocolStub.testData = Fixtures.mempoolContentFullTransactions()

        let result = try? client.mempoolContent(fullTransactions: true)

        XCTAssertEqual("mempoolContent", URLProtocolStub.latestRequestMethod!)
        XCTAssertEqual(true, URLProtocolStub.latestRequestParams![0] as? Bool)

        XCTAssertEqual(3, result?.count)
        XCTAssertNotNil(result?[0])
        XCTAssertEqual("5bb722c2afe25c18ba33d453b3ac2c90ac278c595cc92f6188c8b699e8fb006a", (result?[0] as? Transaction)?.hash)
        XCTAssertNotNil(result?[1])
        XCTAssertEqual("f59a30e0a7e3348ef569225db1f4c29026aeac4350f8c6e751f669eddce0c718", (result?[1] as? Transaction)?.hash)
        XCTAssertNotNil(result?[2])
        XCTAssertEqual("9cd9c1d0ffcaebfcfe86bc2ae73b4e82a488de99c8e3faef92b05432bb94519c", (result?[2] as? Transaction)?.hash)
    }

    func test_mempoolWhenFull() {
        URLProtocolStub.testData = Fixtures.mempool()

        let result = try? client.mempool()

        XCTAssertEqual("mempool", URLProtocolStub.latestRequestMethod!)

        XCTAssertNotNil(result)
        XCTAssertEqual(3, result?.total)
        XCTAssertEqual([1], result?.buckets)
        XCTAssertEqual(3, result?.transactionsPerBucket[1])
    }

    func test_mempoolWhenEmpty() {
        URLProtocolStub.testData = Fixtures.mempoolEmpty()

        let result = try? client.mempool()

        XCTAssertEqual("mempool", URLProtocolStub.latestRequestMethod!)

        XCTAssertNotNil(result)
        XCTAssertEqual(0, result?.total)
        XCTAssertEqual([], result?.buckets)
        XCTAssertEqual(0, result?.transactionsPerBucket.count)
    }

    func test_minFeePerByte() {
        URLProtocolStub.testData = Fixtures.minFeePerByte()

        let result = try? client.minFeePerByte()

        XCTAssertEqual("minFeePerByte", URLProtocolStub.latestRequestMethod!)

        XCTAssertEqual(0, result)
    }

    func test_setMinFeePerByte() {
        URLProtocolStub.testData = Fixtures.minFeePerByte()

        let result = try? client.minFeePerByte(fee: 0)

        XCTAssertEqual("minFeePerByte", URLProtocolStub.latestRequestMethod!)
        XCTAssertEqual(0, URLProtocolStub.latestRequestParams![0] as? Int)

        XCTAssertEqual(0, result)
    }

    func test_mining() {
        URLProtocolStub.testData = Fixtures.miningState()

        let result = try? client.mining()

        XCTAssertEqual("mining", URLProtocolStub.latestRequestMethod!)

        XCTAssertEqual(false, result)
    }

    func test_setMining() {
        URLProtocolStub.testData = Fixtures.miningState()

        let result = try? client.mining(state: false)

        XCTAssertEqual("mining", URLProtocolStub.latestRequestMethod!)
        XCTAssertEqual(false, URLProtocolStub.latestRequestParams![0] as? Bool)

        XCTAssertEqual(false, result)
    }

    func test_hashrate() {
        URLProtocolStub.testData = Fixtures.hashrate()

        let result = try? client.hashrate()

        XCTAssertEqual("hashrate", URLProtocolStub.latestRequestMethod!)

        XCTAssertEqual(52982.2731, result)
    }

    func test_minerThreads() {
        URLProtocolStub.testData = Fixtures.minerThreads()

        let result = try? client.minerThreads()

        XCTAssertEqual("minerThreads", URLProtocolStub.latestRequestMethod!)

        XCTAssertEqual(2, result)
    }

    func test_setMinerThreads() {
        URLProtocolStub.testData = Fixtures.minerThreads()

        let result = try? client.minerThreads(2)

        XCTAssertEqual("minerThreads", URLProtocolStub.latestRequestMethod!)
        XCTAssertEqual(2, URLProtocolStub.latestRequestParams![0] as? Int)

        XCTAssertEqual(2, result)
    }

    func test_minerAddress() {
        URLProtocolStub.testData = Fixtures.minerAddress()

        let result = try? client.minerAddress()

        XCTAssertEqual("minerAddress", URLProtocolStub.latestRequestMethod!)

        XCTAssertEqual("NQ39 NY67 X0F0 UTQE 0YER 4JEU B67L UPP8 G0FM", result)
    }

    func test_pool() {
        URLProtocolStub.testData = Fixtures.poolSushipool()

        let result = try? client.pool()

        XCTAssertEqual("pool", URLProtocolStub.latestRequestMethod!)

        XCTAssertEqual("us.sushipool.com:443", result)
    }

    func test_setPool() {
        URLProtocolStub.testData = Fixtures.poolSushipool()

        let result = try? client.pool(address: "us.sushipool.com:443")

        XCTAssertEqual("pool", URLProtocolStub.latestRequestMethod!)
        XCTAssertEqual("us.sushipool.com:443", URLProtocolStub.latestRequestParams![0] as? String)

        XCTAssertEqual("us.sushipool.com:443", result)
    }

    func test_getPoolWhenNoPool() {
        URLProtocolStub.testData = Fixtures.poolNoPool()

        let result = try? client.pool()

        XCTAssertEqual("pool", URLProtocolStub.latestRequestMethod!)

        XCTAssertEqual(nil, result)
    }

    func test_poolConnectionState() {
        URLProtocolStub.testData = Fixtures.poolConnectionState()

        let result = try? client.poolConnectionState()

        XCTAssertEqual("poolConnectionState", URLProtocolStub.latestRequestMethod!)

        XCTAssertEqual(PoolConnectionState.closed, result)
    }

    func test_poolConfirmedBalance() {
        URLProtocolStub.testData = Fixtures.poolConfirmedBalance()

        let result = try? client.poolConfirmedBalance()

        XCTAssertEqual("poolConfirmedBalance", URLProtocolStub.latestRequestMethod!)

        XCTAssertEqual(12000, result)
    }

    func test_getWork() {
        URLProtocolStub.testData = Fixtures.getWork()

        let result = try? client.getWork()

        XCTAssertEqual("getWork", URLProtocolStub.latestRequestMethod!)

        XCTAssertEqual("00015a7d47ddf5152a7d06a14ea291831c3fc7af20b88240c5ae839683021bcee3e279877b3de0da8ce8878bf225f6782a2663eff9a03478c15ba839fde9f1dc3dd9e5f0cd4dbc96a30130de130eb52d8160e9197e2ccf435d8d24a09b518a5e05da87a8658ed8c02531f66a7d31757b08c88d283654ed477e5e2fec21a7ca8449241e00d620000dc2fa5e763bda00000000", result?.data)
        XCTAssertEqual("11fad9806b8b4167517c162fa113c09606b44d24f8020804a0f756db085546ff585adfdedad9085d36527a8485b497728446c35b9b6c3db263c07dd0a1f487b1639aa37ff60ba3cf6ed8ab5146fee50a23ebd84ea37dca8c49b31e57d05c9e6c57f09a3b282b71ec2be66c1bc8268b5326bb222b11a0d0a4acd2a93c9e8a8713fe4383e9d5df3b1bf008c535281086b2bcc20e494393aea1475a5c3f13673de2cf7314d201b7cc7f01e0e6f0e07dd9249dc598f4e5ee8801f50000000000", result?.suffix)
        XCTAssertEqual(503371296, result?.target)
        XCTAssertEqual("nimiq-argon2", result?.algorithm)
    }

    func test_getWorkWithOverride() {
        URLProtocolStub.testData = Fixtures.getWork()

        let result = try? client.getWork(address: "NQ46 NTNU QX94 MVD0 BBT0 GXAR QUHK VGNF 39ET", extraData: "")

        XCTAssertEqual("getWork", URLProtocolStub.latestRequestMethod!)
        XCTAssertEqual("NQ46 NTNU QX94 MVD0 BBT0 GXAR QUHK VGNF 39ET", URLProtocolStub.latestRequestParams![0] as? String)
        XCTAssertEqual("", URLProtocolStub.latestRequestParams![1] as? String)

        XCTAssertEqual("00015a7d47ddf5152a7d06a14ea291831c3fc7af20b88240c5ae839683021bcee3e279877b3de0da8ce8878bf225f6782a2663eff9a03478c15ba839fde9f1dc3dd9e5f0cd4dbc96a30130de130eb52d8160e9197e2ccf435d8d24a09b518a5e05da87a8658ed8c02531f66a7d31757b08c88d283654ed477e5e2fec21a7ca8449241e00d620000dc2fa5e763bda00000000", result?.data)
        XCTAssertEqual("11fad9806b8b4167517c162fa113c09606b44d24f8020804a0f756db085546ff585adfdedad9085d36527a8485b497728446c35b9b6c3db263c07dd0a1f487b1639aa37ff60ba3cf6ed8ab5146fee50a23ebd84ea37dca8c49b31e57d05c9e6c57f09a3b282b71ec2be66c1bc8268b5326bb222b11a0d0a4acd2a93c9e8a8713fe4383e9d5df3b1bf008c535281086b2bcc20e494393aea1475a5c3f13673de2cf7314d201b7cc7f01e0e6f0e07dd9249dc598f4e5ee8801f50000000000", result?.suffix)
        XCTAssertEqual(503371296, result?.target)
        XCTAssertEqual("nimiq-argon2", result?.algorithm)
    }

    func test_getBlockTemplate() {
        URLProtocolStub.testData = Fixtures.getWorkBlockTemplate()

        let result = try? client.getBlockTemplate()

        XCTAssertEqual("getBlockTemplate", URLProtocolStub.latestRequestMethod!)

        XCTAssertEqual(901883, result?.header.height)
        XCTAssertEqual(503371226, result?.target)
        XCTAssertEqual("17e250f1977ae85bdbe09468efef83587885419ee1074ddae54d3fb5a96e1f54", result?.body.hash)
    }

    func test_getBlockTemplateWithOverride() {
        URLProtocolStub.testData = Fixtures.getWorkBlockTemplate()

        let result = try? client.getBlockTemplate(address: "NQ46 NTNU QX94 MVD0 BBT0 GXAR QUHK VGNF 39ET", extraData: "")

        XCTAssertEqual("getBlockTemplate", URLProtocolStub.latestRequestMethod!)
        XCTAssertEqual("NQ46 NTNU QX94 MVD0 BBT0 GXAR QUHK VGNF 39ET", URLProtocolStub.latestRequestParams![0] as? String)
        XCTAssertEqual("", URLProtocolStub.latestRequestParams![1] as? String)

        XCTAssertEqual(901883, result?.header.height)
        XCTAssertEqual(503371226, result?.target)
        XCTAssertEqual("17e250f1977ae85bdbe09468efef83587885419ee1074ddae54d3fb5a96e1f54", result?.body.hash)
    }

    func test_submitBlock() {
        URLProtocolStub.testData = Fixtures.submitBlock()

        let blockHex = "000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f6ba2bbf7e1478a209057000471d73fbdc28df0b717747d929cfde829c4120f62e02da3d162e20fa982029dbde9cc20f6b431ab05df1764f34af4c62a4f2b33f1f010000000000015ac3185f000134990001000000000000000000000000000000000000000007546573744e657400000000"

        try! client.submitBlock(blockHex)

        XCTAssertEqual("submitBlock", URLProtocolStub.latestRequestMethod!)
        XCTAssertEqual(blockHex, URLProtocolStub.latestRequestParams![0] as? String)
    }

    func test_accounts() {
        URLProtocolStub.testData = Fixtures.accounts()

        let result = try? client.accounts()

        XCTAssertEqual(URLProtocolStub.latestRequestMethod!, "accounts")

        XCTAssertEqual(3, result?.count)

        XCTAssertNotNil(result?[0])
        let account = result?[0] as! Account
        XCTAssertEqual("f925107376081be421f52d64bec775cc1fc20829", account.id)
        XCTAssertEqual("NQ33 Y4JH 0UTN 10DX 88FM 5MJB VHTM RGFU 4219", account.address)
        XCTAssertEqual(0, account.balance)
        XCTAssertEqual(AccountType.basic, account.type)

        XCTAssertNotNil(result?[1])
        let vesting = result?[1] as! VestingContract
        XCTAssertEqual("ebcbf0de7dae6a42d1c12967db9b2287bf2f7f0f", vesting.id)
        XCTAssertEqual("NQ09 VF5Y 1PKV MRM4 5LE1 55KV P6R2 GXYJ XYQF", vesting.address)
        XCTAssertEqual(52500000000000, vesting.balance)
        XCTAssertEqual(AccountType.vesting, vesting.type)
        XCTAssertEqual("fd34ab7265a0e48c454ccbf4c9c61dfdf68f9a22", vesting.owner)
        XCTAssertEqual("NQ62 YLSA NUK5 L3J8 QHAC RFSC KHGV YPT8 Y6H2", vesting.ownerAddress)
        XCTAssertEqual(1, vesting.vestingStart)
        XCTAssertEqual(259200, vesting.vestingStepBlocks)
        XCTAssertEqual(2625000000000, vesting.vestingStepAmount)
        XCTAssertEqual(52500000000000, vesting.vestingTotalAmount)

        XCTAssertNotNil(result?[2])
        let htlc = result?[2] as! HTLC
        XCTAssertEqual("4974636bd6d34d52b7d4a2ee4425dc2be72a2b4e", htlc.id)
        XCTAssertEqual("NQ46 NTNU QX94 MVD0 BBT0 GXAR QUHK VGNF 39ET", htlc.address)
        XCTAssertEqual(1000000000, htlc.balance)
        XCTAssertEqual(AccountType.htlc, htlc.type)
        XCTAssertEqual("d62d519b3478c63bdd729cf2ccb863178060c64a", htlc.sender)
        XCTAssertEqual("NQ53 SQNM 36RL F333 PPBJ KKRC RE33 2X06 1HJA", htlc.senderAddress)
        XCTAssertEqual("f5ad55071730d3b9f05989481eefbda7324a44f8", htlc.recipient)
        XCTAssertEqual("NQ41 XNNM A1QP 639T KU2R H541 VTVV LUR4 LH7Q", htlc.recipientAddress)
        XCTAssertEqual("df331b3c8f8a889703092ea05503779058b7f44e71bc57176378adde424ce922", htlc.hashRoot)
        XCTAssertEqual(1, htlc.hashAlgorithm)
        XCTAssertEqual(1, htlc.hashCount)
        XCTAssertEqual(1105605, htlc.timeout)
        XCTAssertEqual(1000000000, htlc.totalAmount)
    }

    func test_createAccount() {
        URLProtocolStub.testData = Fixtures.createAccount()

        let result = try? client.createAccount()

        XCTAssertEqual("createAccount", URLProtocolStub.latestRequestMethod!)

        XCTAssertNotNil(result)
        XCTAssertEqual("b6edcc7924af5a05af6087959c7233ec2cf1a5db", result?.id)
        XCTAssertEqual("NQ46 NTNU QX94 MVD0 BBT0 GXAR QUHK VGNF 39ET", result?.address)
        XCTAssertEqual("4f6d35cc47b77bf696b6cce72217e52edff972855bd17396b004a8453b020747", result?.publicKey)
    }

    func test_getBalance() {
        URLProtocolStub.testData = Fixtures.getBalance()

        let result = try? client.getBalance(address: "NQ46 NTNU QX94 MVD0 BBT0 GXAR QUHK VGNF 39ET")

        XCTAssertEqual("getBalance", URLProtocolStub.latestRequestMethod!)
        XCTAssertEqual("NQ46 NTNU QX94 MVD0 BBT0 GXAR QUHK VGNF 39ET", URLProtocolStub.latestRequestParams![0] as? String)

        XCTAssertEqual(1200000, result)
    }

    func test_getAccount() {
        URLProtocolStub.testData = Fixtures.getAccountBasic()

        let result = try? client.getAccount(address: "NQ46 NTNU QX94 MVD0 BBT0 GXAR QUHK VGNF 39ET")

        XCTAssertEqual("getAccount", URLProtocolStub.latestRequestMethod!)
        XCTAssertEqual("NQ46 NTNU QX94 MVD0 BBT0 GXAR QUHK VGNF 39ET", URLProtocolStub.latestRequestParams![0] as? String)

        XCTAssert(result is Account)
        let account = result as! Account
        XCTAssertEqual("b6edcc7924af5a05af6087959c7233ec2cf1a5db", account.id)
        XCTAssertEqual("NQ46 NTNU QX94 MVD0 BBT0 GXAR QUHK VGNF 39ET", account.address)
        XCTAssertEqual(1200000, account.balance)
        XCTAssertEqual(AccountType.basic, account.type)
    }

    func test_getAccountForVestingContract() {
        URLProtocolStub.testData = Fixtures.getAccountVesting()

        let result = try? client.getAccount(address: "NQ09 VF5Y 1PKV MRM4 5LE1 55KV P6R2 GXYJ XYQF")

        XCTAssertEqual("getAccount", URLProtocolStub.latestRequestMethod!)
        XCTAssertEqual("NQ09 VF5Y 1PKV MRM4 5LE1 55KV P6R2 GXYJ XYQF", URLProtocolStub.latestRequestParams![0] as? String)

        XCTAssert(result is VestingContract)
        let contract = result as! VestingContract
        XCTAssertEqual("ebcbf0de7dae6a42d1c12967db9b2287bf2f7f0f", contract.id)
        XCTAssertEqual("NQ09 VF5Y 1PKV MRM4 5LE1 55KV P6R2 GXYJ XYQF", contract.address)
        XCTAssertEqual(52500000000000, contract.balance)
        XCTAssertEqual(AccountType.vesting, contract.type)
        XCTAssertEqual("fd34ab7265a0e48c454ccbf4c9c61dfdf68f9a22", contract.owner)
        XCTAssertEqual("NQ62 YLSA NUK5 L3J8 QHAC RFSC KHGV YPT8 Y6H2", contract.ownerAddress)
        XCTAssertEqual(1, contract.vestingStart)
        XCTAssertEqual(259200, contract.vestingStepBlocks)
        XCTAssertEqual(2625000000000, contract.vestingStepAmount)
        XCTAssertEqual(52500000000000, contract.vestingTotalAmount)
    }

    func test_getAccountForHashedTimeLockedContract() {
        URLProtocolStub.testData = Fixtures.getAccountVestingHtlc()

        let result = try? client.getAccount(address: "NQ46 NTNU QX94 MVD0 BBT0 GXAR QUHK VGNF 39ET")

        XCTAssertEqual("getAccount", URLProtocolStub.latestRequestMethod!)
        XCTAssertEqual("NQ46 NTNU QX94 MVD0 BBT0 GXAR QUHK VGNF 39ET", URLProtocolStub.latestRequestParams![0] as? String)

        XCTAssert(result is HTLC)
        let contract = result as! HTLC
        XCTAssertEqual("4974636bd6d34d52b7d4a2ee4425dc2be72a2b4e", contract.id)
        XCTAssertEqual("NQ46 NTNU QX94 MVD0 BBT0 GXAR QUHK VGNF 39ET", contract.address)
        XCTAssertEqual(1000000000, contract.balance)
        XCTAssertEqual(AccountType.htlc, contract.type)
        XCTAssertEqual("d62d519b3478c63bdd729cf2ccb863178060c64a", contract.sender)
        XCTAssertEqual("NQ53 SQNM 36RL F333 PPBJ KKRC RE33 2X06 1HJA", contract.senderAddress)
        XCTAssertEqual("f5ad55071730d3b9f05989481eefbda7324a44f8", contract.recipient)
        XCTAssertEqual("NQ41 XNNM A1QP 639T KU2R H541 VTVV LUR4 LH7Q", contract.recipientAddress)
        XCTAssertEqual("df331b3c8f8a889703092ea05503779058b7f44e71bc57176378adde424ce922", contract.hashRoot)
        XCTAssertEqual(1, contract.hashAlgorithm)
        XCTAssertEqual(1, contract.hashCount)
        XCTAssertEqual(1105605, contract.timeout)
        XCTAssertEqual(1000000000, contract.totalAmount)
    }

    func test_blockNumber() {
        URLProtocolStub.testData = Fixtures.blockNumber()

        let result = try? client.blockNumber()

        XCTAssertEqual("blockNumber", URLProtocolStub.latestRequestMethod!)

        XCTAssertEqual(748883, result)
    }

    func test_getBlockTransactionCountByHash() {
        URLProtocolStub.testData = Fixtures.blockTransactionCountFound()

        let result = try? client.getBlockTransactionCountByHash("bc3945d22c9f6441409a6e539728534a4fc97859bda87333071fad9dad942786")

        XCTAssertEqual("getBlockTransactionCountByHash", URLProtocolStub.latestRequestMethod!)
        XCTAssertEqual("bc3945d22c9f6441409a6e539728534a4fc97859bda87333071fad9dad942786", URLProtocolStub.latestRequestParams![0] as? String)

        XCTAssertEqual(2, result)
    }

    func test_getBlockTransactionCountByHashWhenNotFound() {
        URLProtocolStub.testData = Fixtures.blockTransactionCountNotFound()

        let result = try? client.getBlockTransactionCountByHash("bc3945d22c9f6441409a6e539728534a4fc97859bda87333071fad9dad942786")

        XCTAssertEqual("getBlockTransactionCountByHash", URLProtocolStub.latestRequestMethod!)
        XCTAssertEqual("bc3945d22c9f6441409a6e539728534a4fc97859bda87333071fad9dad942786", URLProtocolStub.latestRequestParams![0] as? String)

        XCTAssertEqual(nil, result)
    }

    func test_getBlockTransactionCountByNumber() {
        URLProtocolStub.testData = Fixtures.blockTransactionCountFound()

        let result = try? client.getBlockTransactionCountByNumber(height: 11608)

        XCTAssertEqual("getBlockTransactionCountByNumber", URLProtocolStub.latestRequestMethod!)
        XCTAssertEqual(11608, URLProtocolStub.latestRequestParams![0] as? Int)

        XCTAssertEqual(2, result)
    }

    func test_getBlockTransactionCountByNumberWhenNotFound() {
        URLProtocolStub.testData = Fixtures.blockTransactionCountNotFound()

        let result = try? client.getBlockTransactionCountByNumber(height: 11608)

        XCTAssertEqual("getBlockTransactionCountByNumber", URLProtocolStub.latestRequestMethod!)
        XCTAssertEqual(11608, URLProtocolStub.latestRequestParams![0] as? Int)

        XCTAssertEqual(nil, result)
    }

    func test_getBlockByHash() {
        URLProtocolStub.testData = Fixtures.getBlockFound()

        let result = try? client.getBlockByHash("bc3945d22c9f6441409a6e539728534a4fc97859bda87333071fad9dad942786")

        XCTAssertEqual("getBlockByHash", URLProtocolStub.latestRequestMethod!)
        XCTAssertEqual("bc3945d22c9f6441409a6e539728534a4fc97859bda87333071fad9dad942786", URLProtocolStub.latestRequestParams![0] as? String)
        XCTAssertEqual(false, URLProtocolStub.latestRequestParams![1] as? Bool)

        XCTAssertNotNil(result)
        XCTAssertEqual(11608, result?.number)
        XCTAssertEqual("bc3945d22c9f6441409a6e539728534a4fc97859bda87333071fad9dad942786", result?.hash)
        XCTAssertEqual(739224, result?.confirmations)
        XCTAssertEqual([
            "78957b87ab5546e11e9540ce5a37ebbf93a0ebd73c0ce05f137288f30ee9f430",
            "fd8e46ae55c5b8cd7cb086cf8d6c81f941a516d6148021d55f912fb2ca75cc8e",
        ], result?.transactions as? [String])
    }

    func test_getBlockByHashWithTransactions() {
        URLProtocolStub.testData = Fixtures.getBlockWithTransactions()

        let result = try? client.getBlockByHash("bc3945d22c9f6441409a6e539728534a4fc97859bda87333071fad9dad942786", fullTransactions: true)

        XCTAssertEqual("getBlockByHash", URLProtocolStub.latestRequestMethod!)
        XCTAssertEqual("bc3945d22c9f6441409a6e539728534a4fc97859bda87333071fad9dad942786", URLProtocolStub.latestRequestParams![0] as? String)
        XCTAssertEqual(true, URLProtocolStub.latestRequestParams![1] as? Bool)

        XCTAssertNotNil(result)
        XCTAssertEqual(11608, result?.number)
        XCTAssertEqual("bc3945d22c9f6441409a6e539728534a4fc97859bda87333071fad9dad942786", result?.hash)
        XCTAssertEqual(739501, result?.confirmations)

        XCTAssertEqual(2, result?.transactions.count)
        XCTAssert(result?.transactions[0] is Transaction)
        XCTAssert(result?.transactions[1] is Transaction)
    }

    func test_getBlockByHashNotFound() {
        URLProtocolStub.testData = Fixtures.getBlockNotFound()

        let result = try? client.getBlockByHash("bc3945d22c9f6441409a6e539728534a4fc97859bda87333071fad9dad942786")

        XCTAssertEqual("getBlockByHash", URLProtocolStub.latestRequestMethod!)
        XCTAssertEqual("bc3945d22c9f6441409a6e539728534a4fc97859bda87333071fad9dad942786", URLProtocolStub.latestRequestParams![0] as? String)
        XCTAssertEqual(false, URLProtocolStub.latestRequestParams![1] as? Bool)

        XCTAssertNil(result)
    }

    func test_getBlockByNumber() {
        URLProtocolStub.testData = Fixtures.getBlockFound()

        let result = try? client.getBlockByNumber(height: 11608)

        XCTAssertEqual("getBlockByNumber", URLProtocolStub.latestRequestMethod!)
        XCTAssertEqual(11608, URLProtocolStub.latestRequestParams![0] as? Int)
        XCTAssertEqual(false, URLProtocolStub.latestRequestParams![1] as? Bool)

        XCTAssertNotNil(result)
        XCTAssertEqual(11608, result?.number)
        XCTAssertEqual("bc3945d22c9f6441409a6e539728534a4fc97859bda87333071fad9dad942786", result?.hash)
        XCTAssertEqual(739224, result?.confirmations)
        XCTAssertEqual([
            "78957b87ab5546e11e9540ce5a37ebbf93a0ebd73c0ce05f137288f30ee9f430",
            "fd8e46ae55c5b8cd7cb086cf8d6c81f941a516d6148021d55f912fb2ca75cc8e",
        ], result?.transactions as? [String])
    }

    func test_getBlockByNumberWithTransactions() {
        URLProtocolStub.testData = Fixtures.getBlockWithTransactions()

        let result = try? client.getBlockByNumber(height: 11608, fullTransactions: true)

        XCTAssertEqual("getBlockByNumber", URLProtocolStub.latestRequestMethod!)
        XCTAssertEqual(11608, URLProtocolStub.latestRequestParams![0] as? Int)
        XCTAssertEqual(true, URLProtocolStub.latestRequestParams![1] as? Bool)

        XCTAssertNotNil(result)
        XCTAssertEqual(11608, result?.number)
        XCTAssertEqual("bc3945d22c9f6441409a6e539728534a4fc97859bda87333071fad9dad942786", result?.hash)
        XCTAssertEqual(739501, result?.confirmations)

        XCTAssertEqual(2, result?.transactions.count)
        XCTAssert(result?.transactions[0] is Transaction)
        XCTAssert(result?.transactions[1] is Transaction)
    }

    func test_getBlockByNumberNotFound() {
        URLProtocolStub.testData = Fixtures.getBlockNotFound()

        let result = try? client.getBlockByNumber(height: 11608)

        XCTAssertEqual("getBlockByNumber", URLProtocolStub.latestRequestMethod!)
        XCTAssertEqual(11608, URLProtocolStub.latestRequestParams![0] as? Int)
        XCTAssertEqual(false, URLProtocolStub.latestRequestParams![1] as? Bool)

        XCTAssertNil(result)
    }

    func test_constant() {
        URLProtocolStub.testData = Fixtures.constant()

        let result = try? client.constant("BaseConsensus.MAX_ATTEMPTS_TO_FETCH")

        XCTAssertEqual("constant", URLProtocolStub.latestRequestMethod!)
        XCTAssertEqual("BaseConsensus.MAX_ATTEMPTS_TO_FETCH", URLProtocolStub.latestRequestParams![0] as? String)

        XCTAssertEqual(5, result)
    }

    func test_setConstant() {
        URLProtocolStub.testData = Fixtures.constant()

        let result = try? client.constant("BaseConsensus.MAX_ATTEMPTS_TO_FETCH", value: 10)

        XCTAssertEqual("constant", URLProtocolStub.latestRequestMethod!)
        XCTAssertEqual("BaseConsensus.MAX_ATTEMPTS_TO_FETCH", URLProtocolStub.latestRequestParams![0] as? String)
        XCTAssertEqual(10, URLProtocolStub.latestRequestParams![1] as? Int)

        XCTAssertEqual(5, result)
    }

    func test_resetConstant() {
        URLProtocolStub.testData = Fixtures.constant()

        let result = try? client.resetConstant("BaseConsensus.MAX_ATTEMPTS_TO_FETCH")

        XCTAssertEqual("constant", URLProtocolStub.latestRequestMethod!)
        XCTAssertEqual("BaseConsensus.MAX_ATTEMPTS_TO_FETCH", URLProtocolStub.latestRequestParams![0] as? String)
        XCTAssertEqual("reset", URLProtocolStub.latestRequestParams![1] as? String)

        XCTAssertEqual(5, result)
    }

    func test_log() {
        URLProtocolStub.testData = Fixtures.log()

        let result = try? client.log(tag: "*", level: LogLevel.verbose)

        XCTAssertEqual("log", URLProtocolStub.latestRequestMethod!)
        XCTAssertEqual("*", URLProtocolStub.latestRequestParams![0] as? String)
        XCTAssertEqual("verbose", URLProtocolStub.latestRequestParams![1] as? String)

        XCTAssertEqual(true, result)
    }
}
