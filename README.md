Nimiq Swift Client
==================

> Swift implementation of the Nimiq RPC client specs.

## Usage

Initialize a `NimiqClient` object using predefined configuration.

```swift
let config = Config(
    scheme: "http",
    host: "127.0.0.1",
    port: 8648,
    user: "luna",
    password: "moon"
)

let client = NimiqClient(config: config)
```

Once the client have been set up, we can call the methodes with the appropiate arguments to make requests to the Nimiq node.

When no `config` object is passed in the initialization it will use default values in the Nimiq node.

```swift
let client = NimiqClient()

// make rpc call to get the block number
let blockNumber = try client.blockNumber()!

print(blockNumber) // displays the block number, for example 748883
```

## API

The complete API documentation is available [here](https://rraallvv.github.io/swift-client/).

Check out the [Nimiq RPC specs](https://github.com/nimiq/core-js/wiki/JSON-RPC-API) for behind the scene RPC calls.

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

To use CocoaPods, add the following to your Podfile:

```sh
pod 'NimiqClient'
```

### Carthage

To use Carthage, add the following to your Cartfile:

```sh
github "nimiq-community/swift-client"
```

## Contributions

This implementation was originally contributed by [rraallvv](https://github.com/rraallvv/).

Please send your contributions as pull requests.

Refer to the [issue tracker](https://github.com/nimiq-community/swift-client/issues) for ideas.

### Develop

After cloning the repository, open the project bundle `NimiqClient.xcodeproj` in Xcode.

All done, happy coding!

### Testing

All tests are in the `/Tests` folder and can be run from Xcode.

### Documentation

The documentation is generated automatically with [Jazzy](https://github.com/realm/jazzy).

To generate the documentation first intall Jazzy:

```sh
$ gem install jazzy
```

Then generate the documentation running Jazzy from the repository root directory:

```sh
$ jazzy
```

## License

[Apache 2.0](LICENSE.md)
