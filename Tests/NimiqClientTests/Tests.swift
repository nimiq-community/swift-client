import XCTest
@testable import NimiqClient

final class Tests: XCTestCase {

    static var client: NimiqClient!

    override class func setUp() {
        super.setUp()

        // sizzle URLSession.dataTask with the mock
        Mock.doSwizzling()

        // init our JSON RPC client with that
        client = NimiqClient(
            scheme: "http",
            user: "user",
            password: "password",
            host: "127.0.0.1",
            port: 8648
        )
    }

    override class func tearDown() {
        super.tearDown()
    }

    func test_peerCount() {
        Mock.testData = Tests.peerCount()

        let result = try? Tests.client.peerCount()

        XCTAssertEqual("peerCount", Mock.latestRequestMethod!)

        XCTAssertEqual(6, result)
    }

    func test_syncingStateWhenSyncing() {
        Mock.testData = Tests.syncing()

        let result = try? Tests.client.syncing()

        XCTAssertEqual("syncing", Mock.latestRequestMethod!)

        XCTAssert(result is SyncStatus)
        let syncing = result as! SyncStatus
        XCTAssertEqual(578430, syncing.startingBlock)
        XCTAssertEqual(586493, syncing.currentBlock)
        XCTAssertEqual(586493, syncing.highestBlock)
    }

    func test_syncingStateWhenNotSyncing() {
        Mock.testData = Tests.syncingNotSyncing()

        let result = try? Tests.client.syncing()

        XCTAssertEqual("syncing", Mock.latestRequestMethod!)

        XCTAssert(result is Bool)
        let syncing = result as! Bool
        XCTAssertEqual(false, syncing)
    }

    func test_consensusState() {
        Mock.testData = Tests.consensusSyncing()

        let result = try? Tests.client.consensus()

        XCTAssertEqual("consensus", Mock.latestRequestMethod!)

        XCTAssertEqual(ConsensusState.syncing, result)
    }

    func test_peerListWithPeers() {
        Mock.testData = Tests.peerList()

        let result = try? Tests.client.peerList()

        XCTAssertEqual("peerList", Mock.latestRequestMethod!)

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
        Mock.testData = Tests.peerListEmpty()

        let result = try? Tests.client.peerList()

        XCTAssertEqual("peerList", Mock.latestRequestMethod!)

        XCTAssertEqual(result?.count, 0)
    }

    func test_peerNormal() {
        Mock.testData = Tests.peerStateNormal()

        let result = try? Tests.client.peerState(forAddress: "wss://seed1.nimiq-testnet.com:8080/b99034c552e9c0fd34eb95c1cdf17f5e")

        XCTAssertEqual("peerState", Mock.latestRequestMethod!)
        XCTAssertEqual("wss://seed1.nimiq-testnet.com:8080/b99034c552e9c0fd34eb95c1cdf17f5e", Mock.latestRequestParams![0] as? String)

        XCTAssertNotNil(result)
        XCTAssertEqual("b99034c552e9c0fd34eb95c1cdf17f5e", result?.id)
        XCTAssertEqual("wss://seed1.nimiq-testnet.com:8080/b99034c552e9c0fd34eb95c1cdf17f5e", result?.address)
        XCTAssertEqual(PeerAddressState.established, result?.addressState)
        XCTAssertEqual(PeerConnectionState.established, result?.connectionState)
    }

    func test_peerFailed() {
        Mock.testData = Tests.peerStateFailed()

        let result = try? Tests.client.peerState(forAddress: "wss://seed4.nimiq-testnet.com:8080/e37dca72802c972d45b37735e9595cf0")

        XCTAssertEqual("peerState", Mock.latestRequestMethod!)
        XCTAssertEqual("wss://seed4.nimiq-testnet.com:8080/e37dca72802c972d45b37735e9595cf0", Mock.latestRequestParams![0] as? String)

        XCTAssertNotNil(result)
        XCTAssertEqual("e37dca72802c972d45b37735e9595cf0", result?.id)
        XCTAssertEqual("wss://seed4.nimiq-testnet.com:8080/e37dca72802c972d45b37735e9595cf0", result?.address)
        XCTAssertEqual(PeerAddressState.failed, result?.addressState)
        XCTAssertEqual(nil, result?.connectionState)
    }

    func test_peerError() {
        Mock.testData = Tests.peerStateError()

        XCTAssertThrowsError(try Tests.client.peerState(forAddress: "unknown")) { error in
            guard case Error.remoteError( _) = error else {
                return XCTFail()
            }
        }
    }

    func test_setPeerNormal() {
        Mock.testData = Tests.peerStateNormal()

        let result = try? Tests.client.setPeerState(forAddress: "wss://seed1.nimiq-testnet.com:8080/b99034c552e9c0fd34eb95c1cdf17f5e", to: PeerStateCommand.connect)

        XCTAssertEqual("peerState", Mock.latestRequestMethod!)
        XCTAssertEqual("wss://seed1.nimiq-testnet.com:8080/b99034c552e9c0fd34eb95c1cdf17f5e", Mock.latestRequestParams![0] as? String)
        XCTAssertEqual("connect", Mock.latestRequestParams![1] as? String)

        XCTAssertNotNil(result)
        XCTAssertEqual("b99034c552e9c0fd34eb95c1cdf17f5e", result?.id)
        XCTAssertEqual("wss://seed1.nimiq-testnet.com:8080/b99034c552e9c0fd34eb95c1cdf17f5e", result?.address)
        XCTAssertEqual(PeerAddressState.established, result?.addressState)
        XCTAssertEqual(PeerConnectionState.established, result?.connectionState)
    }

    func test_sendRawTransaction() {
        Mock.testData = Tests.sendTransaction()

        let result = try? Tests.client.sendRawTransaction("00c3c0d1af80b84c3b3de4e3d79d5c8cc950e044098c969953d68bf9cee68d7b53305dbaac7514a06dae935e40d599caf1bd8a243c00000000000000010000000000000001000dc2e201b5a1755aec80aa4227d5afc6b0de0fcfede8541f31b3c07b9a85449ea9926c1c958628d85a2b481556034ab3d67ff7de28772520813c84aaaf8108f6297c580c")

        XCTAssertEqual("sendRawTransaction", Mock.latestRequestMethod!)
        XCTAssertEqual("00c3c0d1af80b84c3b3de4e3d79d5c8cc950e044098c969953d68bf9cee68d7b53305dbaac7514a06dae935e40d599caf1bd8a243c00000000000000010000000000000001000dc2e201b5a1755aec80aa4227d5afc6b0de0fcfede8541f31b3c07b9a85449ea9926c1c958628d85a2b481556034ab3d67ff7de28772520813c84aaaf8108f6297c580c", Mock.latestRequestParams![0] as? String)

        XCTAssertEqual("81cf3f07b6b0646bb16833d57cda801ad5957e264b64705edeef6191fea0ad63", result)
    }

    func test_createRawTransaction() {
        Mock.testData = Tests.createRawTransactionBasic()

        let transaction = OutgoingTransaction(
            from: "NQ39 NY67 X0F0 UTQE 0YER 4JEU B67L UPP8 G0FM",
            fromType: AccountType.basic,
            to: "NQ16 61ET MB3M 2JG6 TBLK BR0D B6EA X6XQ L91U",
            toType: AccountType.basic,
            value: 100000,
            fee: 1
        )

        let result = try? Tests.client.createRawTransaction(from: transaction)

        XCTAssertEqual("createRawTransaction", Mock.latestRequestMethod!)

        let param = Mock.latestRequestParams![0] as! [String: Any]
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
        Mock.testData = Tests.sendTransaction()

        let transaction = OutgoingTransaction(
            from: "NQ39 NY67 X0F0 UTQE 0YER 4JEU B67L UPP8 G0FM",
            fromType: AccountType.basic,
            to: "NQ16 61ET MB3M 2JG6 TBLK BR0D B6EA X6XQ L91U",
            toType: AccountType.basic,
            value: 1,
            fee: 1
        )

        let result = try? Tests.client.sendTransaction(transaction)

        XCTAssertEqual("sendTransaction", Mock.latestRequestMethod!)

        let param = Mock.latestRequestParams![0] as! [String: Any]
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
        Mock.testData = Tests.getRawTransactionInfoBasic()

        let result = try? Tests.client.getRawTransactionInfo(from: "00c3c0d1af80b84c3b3de4e3d79d5c8cc950e044098c969953d68bf9cee68d7b53305dbaac7514a06dae935e40d599caf1bd8a243c00000000000186a00000000000000001000af84c01239b16cee089836c2af5c7b1dbb22cdc0b4864349f7f3805909aa8cf24e4c1ff0461832e86f3624778a867d5f2ba318f92918ada7ae28d70d40c4ef1d6413802")

        XCTAssertEqual("getRawTransactionInfo", Mock.latestRequestMethod!)
        XCTAssertEqual("00c3c0d1af80b84c3b3de4e3d79d5c8cc950e044098c969953d68bf9cee68d7b53305dbaac7514a06dae935e40d599caf1bd8a243c00000000000186a00000000000000001000af84c01239b16cee089836c2af5c7b1dbb22cdc0b4864349f7f3805909aa8cf24e4c1ff0461832e86f3624778a867d5f2ba318f92918ada7ae28d70d40c4ef1d6413802", Mock.latestRequestParams![0] as? String)

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
        Mock.testData = Tests.getTransactionFull()

        let result = try? Tests.client.getTransactionInBlock(forHash: "bc3945d22c9f6441409a6e539728534a4fc97859bda87333071fad9dad942786", index: 0)

        XCTAssertEqual("getTransactionByBlockHashAndIndex", Mock.latestRequestMethod!)
        XCTAssertEqual("bc3945d22c9f6441409a6e539728534a4fc97859bda87333071fad9dad942786", Mock.latestRequestParams![0] as? String)
        XCTAssertEqual(0, Mock.latestRequestParams![1] as? Int)

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
        Mock.testData = Tests.getTransactionNotFound()

        let result = try? Tests.client.getTransactionInBlock(forHash: "bc3945d22c9f6441409a6e539728534a4fc97859bda87333071fad9dad942786", index: 5)

        XCTAssertEqual("getTransactionByBlockHashAndIndex", Mock.latestRequestMethod!)
        XCTAssertEqual("bc3945d22c9f6441409a6e539728534a4fc97859bda87333071fad9dad942786", Mock.latestRequestParams![0] as? String)
        XCTAssertEqual(5, Mock.latestRequestParams![1] as? Int)

        XCTAssertNil(result)
    }

    func test_getTransactionByBlockNumberAndIndex() {
        Mock.testData = Tests.getTransactionFull()

        let result = try? Tests.client.getTransactionInBlock(atHeight: 11608, index: 0)

        XCTAssertEqual("getTransactionByBlockNumberAndIndex", Mock.latestRequestMethod!)
        XCTAssertEqual(11608, Mock.latestRequestParams![0] as? Int)
        XCTAssertEqual(0, Mock.latestRequestParams![1] as? Int)

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
        Mock.testData = Tests.getTransactionNotFound()

        let result = try? Tests.client.getTransactionInBlock(atHeight: 11608, index: 0)

        XCTAssertEqual("getTransactionByBlockNumberAndIndex", Mock.latestRequestMethod!)
        XCTAssertEqual(11608, Mock.latestRequestParams![0] as? Int)
        XCTAssertEqual(0, Mock.latestRequestParams![1] as? Int)

        XCTAssertNil(result)
    }

    func test_getTransactionByHash() {
        Mock.testData = Tests.getTransactionFull()

        let result = try? Tests.client.getTransaction(forHash: "78957b87ab5546e11e9540ce5a37ebbf93a0ebd73c0ce05f137288f30ee9f430")

        XCTAssertEqual("getTransactionByHash", Mock.latestRequestMethod!)
        XCTAssertEqual("78957b87ab5546e11e9540ce5a37ebbf93a0ebd73c0ce05f137288f30ee9f430", Mock.latestRequestParams![0] as? String)

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
        Mock.testData = Tests.getTransactionNotFound()

        let result = try? Tests.client.getTransaction(forHash: "78957b87ab5546e11e9540ce5a37ebbf93a0ebd73c0ce05f137288f30ee9f430")

        XCTAssertEqual("getTransactionByHash", Mock.latestRequestMethod!)
        XCTAssertEqual("78957b87ab5546e11e9540ce5a37ebbf93a0ebd73c0ce05f137288f30ee9f430", Mock.latestRequestParams![0] as? String)

        XCTAssertNil(result)
    }

    func test_getTransactionByHashForContractCreation() {
        Mock.testData = Tests.getTransactionContractCreation()

        let result = try? Tests.client.getTransaction(forHash: "539f6172b19f63be376ab7e962c368bb5f611deff6b159152c4cdf509f7daad2")

        XCTAssertEqual("getTransactionByHash", Mock.latestRequestMethod!)
        XCTAssertEqual("539f6172b19f63be376ab7e962c368bb5f611deff6b159152c4cdf509f7daad2", Mock.latestRequestParams![0] as? String)

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
        Mock.testData = Tests.getTransactionReceiptFound()

        let result = try? Tests.client.getTransactionReceipt(forHash: "fd8e46ae55c5b8cd7cb086cf8d6c81f941a516d6148021d55f912fb2ca75cc8e")

        XCTAssertEqual("getTransactionReceipt", Mock.latestRequestMethod!)
        XCTAssertEqual("fd8e46ae55c5b8cd7cb086cf8d6c81f941a516d6148021d55f912fb2ca75cc8e", Mock.latestRequestParams![0] as? String)

        XCTAssertNotNil(result)
        XCTAssertEqual("fd8e46ae55c5b8cd7cb086cf8d6c81f941a516d6148021d55f912fb2ca75cc8e", result?.transactionHash)
        XCTAssertEqual(-1, result?.transactionIndex)
        XCTAssertEqual(11608, result?.blockNumber)
        XCTAssertEqual("bc3945d22c9f6441409a6e539728534a4fc97859bda87333071fad9dad942786", result?.blockHash)
        XCTAssertEqual(1523412456, result?.timestamp)
        XCTAssertEqual(718846, result?.confirmations)
    }

    func test_getTransactionReceiptWhenNotFound() {
        Mock.testData = Tests.getTransactionReceiptNotFound()

        let result = try? Tests.client.getTransactionReceipt(forHash: "unknown")

        XCTAssertEqual("getTransactionReceipt", Mock.latestRequestMethod!)
        XCTAssertEqual("unknown", Mock.latestRequestParams![0] as? String)

        XCTAssertNil(result)
    }

    func test_getTransactionsByAddress() {
        Mock.testData = Tests.getTransactionsFound()

        let result = try? Tests.client.getTransactions(forAddress: "NQ05 9VGU 0TYE NXBH MVLR E4JY UG6N 5701 MX9F")

        XCTAssertEqual("getTransactionsByAddress", Mock.latestRequestMethod!)
        XCTAssertEqual("NQ05 9VGU 0TYE NXBH MVLR E4JY UG6N 5701 MX9F", Mock.latestRequestParams![0] as? String)

        XCTAssertEqual(3, result?.count)
        XCTAssertNotNil(result?[0])
        XCTAssertEqual("a514abb3ee4d3fbedf8a91156fb9ec4fdaf32f0d3d3da3c1dbc5fd1ee48db43e", result?[0].hash)
        XCTAssertNotNil(result?[1])
        XCTAssertEqual("c8c0f586b11c7f39873c3de08610d63e8bec1ceaeba5e8a3bb13c709b2935f73", result?[1].hash)
        XCTAssertNotNil(result?[2])
        XCTAssertEqual("fd8e46ae55c5b8cd7cb086cf8d6c81f941a516d6148021d55f912fb2ca75cc8e", result?[2].hash)
    }

    func test_getTransactionsByAddressWhenNoFound() {
        Mock.testData = Tests.getTransactionsNotFound()

        let result = try? Tests.client.getTransactions(forAddress: "NQ10 9VGU 0TYE NXBH MVLR E4JY UG6N 5701 MX9F")

        XCTAssertEqual("getTransactionsByAddress", Mock.latestRequestMethod!)
        XCTAssertEqual("NQ10 9VGU 0TYE NXBH MVLR E4JY UG6N 5701 MX9F", Mock.latestRequestParams![0] as? String)

        XCTAssertEqual(0, result?.count)
    }

    func test_mempoolContentHashesOnly() {
        Mock.testData = Tests.mempoolContentHashesOnly()

        let result = try? Tests.client.mempoolContent()

        XCTAssertEqual("mempoolContent", Mock.latestRequestMethod!)
        XCTAssertEqual(0, Mock.latestRequestParams!.count)

        XCTAssertEqual(3, result?.count)
        XCTAssertNotNil(result?[0])
        XCTAssertEqual("5bb722c2afe25c18ba33d453b3ac2c90ac278c595cc92f6188c8b699e8fb006a", result?[0] as? String)
        XCTAssertNotNil(result?[1])
        XCTAssertEqual("f59a30e0a7e3348ef569225db1f4c29026aeac4350f8c6e751f669eddce0c718", result?[1] as? String)
        XCTAssertNotNil(result?[2])
        XCTAssertEqual("9cd9c1d0ffcaebfcfe86bc2ae73b4e82a488de99c8e3faef92b05432bb94519c", result?[2] as? String)
    }

    func test_mempoolContentFullTransactions() {
        Mock.testData = Tests.mempoolContentFullTransactions()

        let result = try? Tests.client.mempoolContent(withTransactions: true)

        XCTAssertEqual("mempoolContent", Mock.latestRequestMethod!)
        XCTAssertEqual(true, Mock.latestRequestParams![0] as? Bool)

        XCTAssertEqual(3, result?.count)
        XCTAssertNotNil(result?[0])
        XCTAssertEqual("5bb722c2afe25c18ba33d453b3ac2c90ac278c595cc92f6188c8b699e8fb006a", (result?[0] as? Transaction)?.hash)
        XCTAssertNotNil(result?[1])
        XCTAssertEqual("f59a30e0a7e3348ef569225db1f4c29026aeac4350f8c6e751f669eddce0c718", (result?[1] as? Transaction)?.hash)
        XCTAssertNotNil(result?[2])
        XCTAssertEqual("9cd9c1d0ffcaebfcfe86bc2ae73b4e82a488de99c8e3faef92b05432bb94519c", (result?[2] as? Transaction)?.hash)
    }

    func test_mempoolWhenFull() {
        Mock.testData = Tests.mempool()

        let result = try? Tests.client.mempool()

        XCTAssertEqual("mempool", Mock.latestRequestMethod!)

        XCTAssertNotNil(result)
        XCTAssertEqual(3, result?.total)
        XCTAssertEqual([1], result?.buckets)
        XCTAssertEqual(3, result?.transactionsPerBucket[1])
    }

    func test_mempoolWhenEmpty() {
        Mock.testData = Tests.mempoolEmpty()

        let result = try? Tests.client.mempool()

        XCTAssertEqual("mempool", Mock.latestRequestMethod!)

        XCTAssertNotNil(result)
        XCTAssertEqual(0, result?.total)
        XCTAssertEqual([], result?.buckets)
        XCTAssertEqual(0, result?.transactionsPerBucket.count)
    }

    func test_minFeePerByte() {
        Mock.testData = Tests.minFeePerByte()

        let result = try? Tests.client.minFeePerByte()

        XCTAssertEqual("minFeePerByte", Mock.latestRequestMethod!)

        XCTAssertEqual(0, result)
    }

    func test_setMinFeePerByte() {
        Mock.testData = Tests.minFeePerByte()

        let result = try? Tests.client.setMinFeePerByte(to: 0)

        XCTAssertEqual("minFeePerByte", Mock.latestRequestMethod!)
        XCTAssertEqual(0, Mock.latestRequestParams![0] as? Int)

        XCTAssertEqual(0, result)
    }

    func test_mining() {
        Mock.testData = Tests.miningState()

        let result = try? Tests.client.isMining()

        XCTAssertEqual("mining", Mock.latestRequestMethod!)

        XCTAssertEqual(false, result)
    }

    func test_setMining() {
        Mock.testData = Tests.miningState()

        let result = try? Tests.client.setMining(to: false)

        XCTAssertEqual("mining", Mock.latestRequestMethod!)
        XCTAssertEqual(false, Mock.latestRequestParams![0] as? Bool)

        XCTAssertEqual(false, result)
    }

    func test_hashrate() {
        Mock.testData = Tests.hashrate()

        let result = try? Tests.client.hashrate()

        XCTAssertEqual("hashrate", Mock.latestRequestMethod!)

        XCTAssertEqual(52982.2731, result)
    }

    func test_minerThreads() {
        Mock.testData = Tests.minerThreads()

        let result = try? Tests.client.minerThreads()

        XCTAssertEqual("minerThreads", Mock.latestRequestMethod!)

        XCTAssertEqual(2, result)
    }

    func test_setMinerThreads() {
        Mock.testData = Tests.minerThreads()

        let result = try? Tests.client.setMinerThreads(to: 2)

        XCTAssertEqual("minerThreads", Mock.latestRequestMethod!)
        XCTAssertEqual(2, Mock.latestRequestParams![0] as? Int)

        XCTAssertEqual(2, result)
    }

    func test_minerAddress() {
        Mock.testData = Tests.minerAddress()

        let result = try? Tests.client.minerAddress()

        XCTAssertEqual("minerAddress", Mock.latestRequestMethod!)

        XCTAssertEqual("NQ39 NY67 X0F0 UTQE 0YER 4JEU B67L UPP8 G0FM", result)
    }

    func test_pool() {
        Mock.testData = Tests.poolSushipool()

        let result = try? Tests.client.pool()

        XCTAssertEqual("pool", Mock.latestRequestMethod!)

        XCTAssertEqual("us.sushipool.com:443", result)
    }

    func test_setPool() {
        Mock.testData = Tests.poolSushipool()

        let result = try? Tests.client.setPool(toAddress: "us.sushipool.com:443")

        XCTAssertEqual("pool", Mock.latestRequestMethod!)
        XCTAssertEqual("us.sushipool.com:443", Mock.latestRequestParams![0] as? String)

        XCTAssertEqual("us.sushipool.com:443", result)
    }

    func test_getPoolWhenNoPool() {
        Mock.testData = Tests.poolNoPool()

        let result = try? Tests.client.pool()

        XCTAssertEqual("pool", Mock.latestRequestMethod!)

        XCTAssertEqual(nil, result)
    }

    func test_poolConnectionState() {
        Mock.testData = Tests.poolConnectionState()

        let result = try? Tests.client.poolConnectionState()

        XCTAssertEqual("poolConnectionState", Mock.latestRequestMethod!)

        XCTAssertEqual(PoolConnectionState.closed, result)
    }

    func test_poolConfirmedBalance() {
        Mock.testData = Tests.poolConfirmedBalance()

        let result = try? Tests.client.poolConfirmedBalance()

        XCTAssertEqual("poolConfirmedBalance", Mock.latestRequestMethod!)

        XCTAssertEqual(12000, result)
    }

    func test_getWork() {
        Mock.testData = Tests.getWork()

        let result = try? Tests.client.getWork()

        XCTAssertEqual("getWork", Mock.latestRequestMethod!)

        XCTAssertEqual("00015a7d47ddf5152a7d06a14ea291831c3fc7af20b88240c5ae839683021bcee3e279877b3de0da8ce8878bf225f6782a2663eff9a03478c15ba839fde9f1dc3dd9e5f0cd4dbc96a30130de130eb52d8160e9197e2ccf435d8d24a09b518a5e05da87a8658ed8c02531f66a7d31757b08c88d283654ed477e5e2fec21a7ca8449241e00d620000dc2fa5e763bda00000000", result?.data)
        XCTAssertEqual("11fad9806b8b4167517c162fa113c09606b44d24f8020804a0f756db085546ff585adfdedad9085d36527a8485b497728446c35b9b6c3db263c07dd0a1f487b1639aa37ff60ba3cf6ed8ab5146fee50a23ebd84ea37dca8c49b31e57d05c9e6c57f09a3b282b71ec2be66c1bc8268b5326bb222b11a0d0a4acd2a93c9e8a8713fe4383e9d5df3b1bf008c535281086b2bcc20e494393aea1475a5c3f13673de2cf7314d201b7cc7f01e0e6f0e07dd9249dc598f4e5ee8801f50000000000", result?.suffix)
        XCTAssertEqual(503371296, result?.target)
        XCTAssertEqual("nimiq-argon2", result?.algorithm)
    }

    func test_getWorkWithOverride() {
        Mock.testData = Tests.getWork()

        let result = try? Tests.client.getWork(forAddress: "NQ46 NTNU QX94 MVD0 BBT0 GXAR QUHK VGNF 39ET", withExtraData: "")

        XCTAssertEqual("getWork", Mock.latestRequestMethod!)
        XCTAssertEqual("NQ46 NTNU QX94 MVD0 BBT0 GXAR QUHK VGNF 39ET", Mock.latestRequestParams![0] as? String)
        XCTAssertEqual("", Mock.latestRequestParams![1] as? String)

        XCTAssertEqual("00015a7d47ddf5152a7d06a14ea291831c3fc7af20b88240c5ae839683021bcee3e279877b3de0da8ce8878bf225f6782a2663eff9a03478c15ba839fde9f1dc3dd9e5f0cd4dbc96a30130de130eb52d8160e9197e2ccf435d8d24a09b518a5e05da87a8658ed8c02531f66a7d31757b08c88d283654ed477e5e2fec21a7ca8449241e00d620000dc2fa5e763bda00000000", result?.data)
        XCTAssertEqual("11fad9806b8b4167517c162fa113c09606b44d24f8020804a0f756db085546ff585adfdedad9085d36527a8485b497728446c35b9b6c3db263c07dd0a1f487b1639aa37ff60ba3cf6ed8ab5146fee50a23ebd84ea37dca8c49b31e57d05c9e6c57f09a3b282b71ec2be66c1bc8268b5326bb222b11a0d0a4acd2a93c9e8a8713fe4383e9d5df3b1bf008c535281086b2bcc20e494393aea1475a5c3f13673de2cf7314d201b7cc7f01e0e6f0e07dd9249dc598f4e5ee8801f50000000000", result?.suffix)
        XCTAssertEqual(503371296, result?.target)
        XCTAssertEqual("nimiq-argon2", result?.algorithm)
    }

    func test_getBlockTemplate() {
        Mock.testData = Tests.getWorkBlockTemplate()

        let result = try? Tests.client.getBlockTemplate()

        XCTAssertEqual("getBlockTemplate", Mock.latestRequestMethod!)

        XCTAssertEqual(901883, result?.header.height)
        XCTAssertEqual(503371226, result?.target)
        XCTAssertEqual("17e250f1977ae85bdbe09468efef83587885419ee1074ddae54d3fb5a96e1f54", result?.body.hash)
    }

    func test_getBlockTemplateWithOverride() {
        Mock.testData = Tests.getWorkBlockTemplate()

        let result = try? Tests.client.getBlockTemplate(forAddress: "NQ46 NTNU QX94 MVD0 BBT0 GXAR QUHK VGNF 39ET", withExtraData: "")

        XCTAssertEqual("getBlockTemplate", Mock.latestRequestMethod!)
        XCTAssertEqual("NQ46 NTNU QX94 MVD0 BBT0 GXAR QUHK VGNF 39ET", Mock.latestRequestParams![0] as? String)
        XCTAssertEqual("", Mock.latestRequestParams![1] as? String)

        XCTAssertEqual(901883, result?.header.height)
        XCTAssertEqual(503371226, result?.target)
        XCTAssertEqual("17e250f1977ae85bdbe09468efef83587885419ee1074ddae54d3fb5a96e1f54", result?.body.hash)
    }

    func test_submitBlock() {
        Mock.testData = Tests.submitBlock()

        let blockHex = "000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f6ba2bbf7e1478a209057000471d73fbdc28df0b717747d929cfde829c4120f62e02da3d162e20fa982029dbde9cc20f6b431ab05df1764f34af4c62a4f2b33f1f010000000000015ac3185f000134990001000000000000000000000000000000000000000007546573744e657400000000"

        try! Tests.client.submitBlock(blockHex)

        XCTAssertEqual("submitBlock", Mock.latestRequestMethod!)
        XCTAssertEqual(blockHex, Mock.latestRequestParams![0] as? String)
    }

    func test_accounts() {
        Mock.testData = Tests.accounts()

        let result = try? Tests.client.accounts()

        XCTAssertEqual(Mock.latestRequestMethod!, "accounts")

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
        Mock.testData = Tests.createAccount()

        let result = try? Tests.client.createAccount()

        XCTAssertEqual("createAccount", Mock.latestRequestMethod!)

        XCTAssertNotNil(result)
        XCTAssertEqual("b6edcc7924af5a05af6087959c7233ec2cf1a5db", result?.id)
        XCTAssertEqual("NQ46 NTNU QX94 MVD0 BBT0 GXAR QUHK VGNF 39ET", result?.address)
        XCTAssertEqual("4f6d35cc47b77bf696b6cce72217e52edff972855bd17396b004a8453b020747", result?.publicKey)
    }

    func test_getBalance() {
        Mock.testData = Tests.getBalance()

        let result = try? Tests.client.getBalance(forAddress: "NQ46 NTNU QX94 MVD0 BBT0 GXAR QUHK VGNF 39ET")

        XCTAssertEqual("getBalance", Mock.latestRequestMethod!)
        XCTAssertEqual("NQ46 NTNU QX94 MVD0 BBT0 GXAR QUHK VGNF 39ET", Mock.latestRequestParams![0] as? String)

        XCTAssertEqual(1200000, result)
    }

    func test_getAccount() {
        Mock.testData = Tests.getAccountBasic()

        let result = try? Tests.client.getAccount(forAddress: "NQ46 NTNU QX94 MVD0 BBT0 GXAR QUHK VGNF 39ET")

        XCTAssertEqual("getAccount", Mock.latestRequestMethod!)
        XCTAssertEqual("NQ46 NTNU QX94 MVD0 BBT0 GXAR QUHK VGNF 39ET", Mock.latestRequestParams![0] as? String)

        XCTAssert(result is Account)
        let account = result as! Account
        XCTAssertEqual("b6edcc7924af5a05af6087959c7233ec2cf1a5db", account.id)
        XCTAssertEqual("NQ46 NTNU QX94 MVD0 BBT0 GXAR QUHK VGNF 39ET", account.address)
        XCTAssertEqual(1200000, account.balance)
        XCTAssertEqual(AccountType.basic, account.type)
    }

    func test_getAccountForVestingContract() {
        Mock.testData = Tests.getAccountVesting()

        let result = try? Tests.client.getAccount(forAddress: "NQ09 VF5Y 1PKV MRM4 5LE1 55KV P6R2 GXYJ XYQF")

        XCTAssertEqual("getAccount", Mock.latestRequestMethod!)
        XCTAssertEqual("NQ09 VF5Y 1PKV MRM4 5LE1 55KV P6R2 GXYJ XYQF", Mock.latestRequestParams![0] as? String)

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
        Mock.testData = Tests.getAccountVestingHtlc()

        let result = try? Tests.client.getAccount(forAddress: "NQ46 NTNU QX94 MVD0 BBT0 GXAR QUHK VGNF 39ET")

        XCTAssertEqual("getAccount", Mock.latestRequestMethod!)
        XCTAssertEqual("NQ46 NTNU QX94 MVD0 BBT0 GXAR QUHK VGNF 39ET", Mock.latestRequestParams![0] as? String)

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
        Mock.testData = Tests.blockNumber()

        let result = try? Tests.client.blockNumber()

        XCTAssertEqual("blockNumber", Mock.latestRequestMethod!)

        XCTAssertEqual(748883, result)
    }

    func test_getBlockTransactionCountByHash() {
        Mock.testData = Tests.blockTransactionCountFound()

        let result = try? Tests.client.getBlockTransactionCount(forHash: "bc3945d22c9f6441409a6e539728534a4fc97859bda87333071fad9dad942786")

        XCTAssertEqual("getBlockTransactionCountByHash", Mock.latestRequestMethod!)
        XCTAssertEqual("bc3945d22c9f6441409a6e539728534a4fc97859bda87333071fad9dad942786", Mock.latestRequestParams![0] as? String)

        XCTAssertEqual(2, result)
    }

    func test_getBlockTransactionCountByHashWhenNotFound() {
        Mock.testData = Tests.blockTransactionCountNotFound()

        let result = try? Tests.client.getBlockTransactionCount(forHash: "bc3945d22c9f6441409a6e539728534a4fc97859bda87333071fad9dad942786")

        XCTAssertEqual("getBlockTransactionCountByHash", Mock.latestRequestMethod!)
        XCTAssertEqual("bc3945d22c9f6441409a6e539728534a4fc97859bda87333071fad9dad942786", Mock.latestRequestParams![0] as? String)

        XCTAssertEqual(nil, result)
    }

    func test_getBlockTransactionCountByNumber() {
        Mock.testData = Tests.blockTransactionCountFound()

        let result = try? Tests.client.getBlockTransactionCount(atHeight: 11608)

        XCTAssertEqual("getBlockTransactionCountByNumber", Mock.latestRequestMethod!)
        XCTAssertEqual(11608, Mock.latestRequestParams![0] as? Int)

        XCTAssertEqual(2, result)
    }

    func test_getBlockTransactionCountByNumberWhenNotFound() {
        Mock.testData = Tests.blockTransactionCountNotFound()

        let result = try? Tests.client.getBlockTransactionCount(atHeight: 11608)

        XCTAssertEqual("getBlockTransactionCountByNumber", Mock.latestRequestMethod!)
        XCTAssertEqual(11608, Mock.latestRequestParams![0] as? Int)

        XCTAssertEqual(nil, result)
    }

    func test_getBlockByHash() {
        Mock.testData = Tests.getBlockFound()

        let result = try? Tests.client.getBlock(forHash: "bc3945d22c9f6441409a6e539728534a4fc97859bda87333071fad9dad942786")

        XCTAssertEqual("getBlockByHash", Mock.latestRequestMethod!)
        XCTAssertEqual("bc3945d22c9f6441409a6e539728534a4fc97859bda87333071fad9dad942786", Mock.latestRequestParams![0] as? String)
        XCTAssertEqual(1, Mock.latestRequestParams!.count)

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
        Mock.testData = Tests.getBlockWithTransactions()

        let result = try? Tests.client.getBlock(forHash: "bc3945d22c9f6441409a6e539728534a4fc97859bda87333071fad9dad942786", withTransactions: true)

        XCTAssertEqual("getBlockByHash", Mock.latestRequestMethod!)
        XCTAssertEqual("bc3945d22c9f6441409a6e539728534a4fc97859bda87333071fad9dad942786", Mock.latestRequestParams![0] as? String)
        XCTAssertEqual(true, Mock.latestRequestParams![1] as? Bool)

        XCTAssertNotNil(result)
        XCTAssertEqual(11608, result?.number)
        XCTAssertEqual("bc3945d22c9f6441409a6e539728534a4fc97859bda87333071fad9dad942786", result?.hash)
        XCTAssertEqual(739501, result?.confirmations)

        XCTAssertEqual(2, result?.transactions.count)
        XCTAssert(result?.transactions[0] is Transaction)
        XCTAssert(result?.transactions[1] is Transaction)
    }

    func test_getBlockByHashNotFound() {
        Mock.testData = Tests.getBlockNotFound()

        let result = try? Tests.client.getBlock(forHash: "bc3945d22c9f6441409a6e539728534a4fc97859bda87333071fad9dad942786")

        XCTAssertEqual("getBlockByHash", Mock.latestRequestMethod!)
        XCTAssertEqual("bc3945d22c9f6441409a6e539728534a4fc97859bda87333071fad9dad942786", Mock.latestRequestParams![0] as? String)
        XCTAssertEqual(1, Mock.latestRequestParams!.count)

        XCTAssertNil(result)
    }

    func test_getBlockByNumber() {
        Mock.testData = Tests.getBlockFound()

        let result = try? Tests.client.getBlock(atHeight: 11608)

        XCTAssertEqual("getBlockByNumber", Mock.latestRequestMethod!)
        XCTAssertEqual(11608, Mock.latestRequestParams![0] as? Int)
        XCTAssertEqual(1, Mock.latestRequestParams!.count)

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
        Mock.testData = Tests.getBlockWithTransactions()

        let result = try? Tests.client.getBlock(atHeight: 11608, withTransactions: true)

        XCTAssertEqual("getBlockByNumber", Mock.latestRequestMethod!)
        XCTAssertEqual(11608, Mock.latestRequestParams![0] as? Int)
        XCTAssertEqual(true, Mock.latestRequestParams![1] as? Bool)

        XCTAssertNotNil(result)
        XCTAssertEqual(11608, result?.number)
        XCTAssertEqual("bc3945d22c9f6441409a6e539728534a4fc97859bda87333071fad9dad942786", result?.hash)
        XCTAssertEqual(739501, result?.confirmations)

        XCTAssertEqual(2, result?.transactions.count)
        XCTAssert(result?.transactions[0] is Transaction)
        XCTAssert(result?.transactions[1] is Transaction)
    }

    func test_getBlockByNumberNotFound() {
        Mock.testData = Tests.getBlockNotFound()

        let result = try? Tests.client.getBlock(atHeight: 11608)

        XCTAssertEqual("getBlockByNumber", Mock.latestRequestMethod!)
        XCTAssertEqual(11608, Mock.latestRequestParams![0] as? Int)
        XCTAssertEqual(1, Mock.latestRequestParams!.count)

        XCTAssertNil(result)
    }

    func test_constant() {
        Mock.testData = Tests.constant()

        let result = try? Tests.client.constant("BaseConsensus.MAX_ATTEMPTS_TO_FETCH")

        XCTAssertEqual("constant", Mock.latestRequestMethod!)
        XCTAssertEqual("BaseConsensus.MAX_ATTEMPTS_TO_FETCH", Mock.latestRequestParams![0] as? String)

        XCTAssertEqual(5, result)
    }

    func test_setConstant() {
        Mock.testData = Tests.constant()

        let result = try? Tests.client.setConstant("BaseConsensus.MAX_ATTEMPTS_TO_FETCH", to: 10)

        XCTAssertEqual("constant", Mock.latestRequestMethod!)
        XCTAssertEqual("BaseConsensus.MAX_ATTEMPTS_TO_FETCH", Mock.latestRequestParams![0] as? String)
        XCTAssertEqual(10, Mock.latestRequestParams![1] as? Int)

        XCTAssertEqual(5, result)
    }

    func test_resetConstant() {
        Mock.testData = Tests.constant()

        let result = try? Tests.client.resetConstant("BaseConsensus.MAX_ATTEMPTS_TO_FETCH")

        XCTAssertEqual("constant", Mock.latestRequestMethod!)
        XCTAssertEqual("BaseConsensus.MAX_ATTEMPTS_TO_FETCH", Mock.latestRequestParams![0] as? String)
        XCTAssertEqual("reset", Mock.latestRequestParams![1] as? String)

        XCTAssertEqual(5, result)
    }

    func test_log() {
        Mock.testData = Tests.log()

        let result = try? Tests.client.setLog(tag: "*", to: LogLevel.verbose)

        XCTAssertEqual("log", Mock.latestRequestMethod!)
        XCTAssertEqual("*", Mock.latestRequestParams![0] as? String)
        XCTAssertEqual("verbose", Mock.latestRequestParams![1] as? String)

        XCTAssertEqual(true, result)
    }
}
