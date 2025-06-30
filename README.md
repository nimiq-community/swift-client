# Nimiq Swift Client

> Swift implementation of the Nimiq RPC client specs.

This repository is archived: Nimiq PoS has been launched and this RPC client only supports the
old PoW RPC specification. As of now, there is no Swift RPC client implementation. Please
[contact us](mailto:community@nimiq.com) if you are interested in implementing and supporting the
Nimiq ecosystem for Swift.

## Usage

Initialize a `NimiqClient` object using predefined configuration and get the current block number.

```swift
let config = Config(
    scheme: "http",
    host: "127.0.0.1",
    port: 8648,
    user: "luna",
    password: "moon"
)

let client = NimiqClient(config: config)

// make rpc call to get current block number
let blockNumber = try client.blockNumber()!
print(blockNumber)
```

Note: When no `config` object is passed in the initialization it will use default values in the Nimiq node.

## API

The complete API documentation is available [here](https://nimiq-community.github.io/swift-client/).

Check out the original [Nimiq RPC specs](https://github.com/nimiq/core-js/wiki/JSON-RPC-API) for the behind-the-scenes RPC calls.

## Installation

### Swift Package Manager

To integrate NimiqClient in your app with SPM. Just add the package as a dependency:

```swift
import PackageDescription

let package = Package(
    name: "MyApp",
    dependencies: [
        .package(url: "https://github.com/nimiq-community/swift-client", from: "0.0.1"),
    ]
)
```

### CocoaPods

To use CocoaPods, add the following to your `Podfile`:

```sh
pod 'NimiqClient'
```

### Carthage

To use Carthage, add the following to your `Cartfile`:

```sh
github "nimiq-community/swift-client"
```

## Build

After cloning the repository, open the project bundle `NimiqClient.xcodeproj` in Xcode.

All done, happy coding!

## Test

You need a start a Testnet Nimiq node:

```sh
nodejs index.js --protocol=dumb --type=full --network=test --rpc
```

All tests are in the `/Tests` folder and can be run from Xcode.

## Documentation

The documentation is generated automatically with [Jazzy](https://github.com/realm/jazzy).

To generate the documentation first install Jazzy:

```sh
gem install jazzy
```

Then generate the documentation running Jazzy from the repository root directory:

```sh
jazzy
```

Add a blank file in the `/docs` folder with the name `.nojekyll` for the documentation hosted on GitHub Pages:

```sh
touch docs/.nojekyll
```

## Contributions

This implementation was originally contributed by [rraallvv](https://github.com/rraallvv/).

Bug reports and pull requests are welcome! Please refer to the [issue tracker](https://github.com/nimiq-community/swift-client/issues) for ideas.

## License

[Apache 2.0](LICENSE)
