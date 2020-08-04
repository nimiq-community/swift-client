import Foundation
import NimiqClient

// Create Nimiq RPC client
var client = NimiqClient(
    scheme: "http",
    user: "luna",
    password: "moon",
    host: "127.0.0.1",
    port: 8648
)

do {
    // Get consensus
    let consensus = try client.consensus()!
    print("Consensus: \(consensus)");

    if consensus == ConsensusState.established {
        // Get accounts
        print("Getting basic accounts:");
        for account in try client.accounts()! {
            // Show basic account address
            if let basicAccount = account as? Account, basicAccount.type == AccountType.basic {
                print(basicAccount.address);
            }
        }
    }
} catch Error.internalError(let error) {
    print("Got error when trying to connect to the RPC server: \(error)");
}
