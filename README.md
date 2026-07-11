# swift-graphql

[![CI](https://github.com/jkzh40/swift-graphql/actions/workflows/ci.yml/badge.svg)](https://github.com/jkzh40/swift-graphql/actions/workflows/ci.yml)

A lightweight GraphQL client and query DSL for Swift. It provides typed query
construction, response-root decoding, a result-builder selection DSL, and macros
that derive selections from Swift models.

The package intentionally focuses on request construction and execution. It does
not perform schema introspection or code generation, and it does not provide a
normalized cache or subscription transport.

## Requirements

- Swift 6.3 or newer
- macOS 11 or newer, or Linux

## Installation

Add the package in `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/jkzh40/swift-graphql.git", branch: "main"),
]
```

Then add the `GraphQL` product to your target:

```swift
.target(
    name: "MyApp",
    dependencies: [
        .product(name: "GraphQL", package: "swift-graphql"),
    ]
)
```

Use a version requirement instead of the `main` branch after tagged releases are
available.

## Usage

Define a response model and use the macros to derive its selectable fields and
root response type:

```swift
import GraphQL

@Fields
@Root("accounts")
struct Account: Decodable, Sendable {
    let id: String
    let displayName: String
}
```

Build an operation with explicit selections:

```swift
@RootOperation(rootType: "Account.Root")
struct GetAccountsOperation: QueryOperation {
    @SelectionBuilder
    var body: [Selection] {
        field(Account.Root.self) {
            Account.Fields.id
            Account.Fields.displayName
        }
    }
}
```

Configure an API and execute the operation:

```swift
import Foundation

struct ExampleAPI: API {
    let configuration: DefaultAPIConfiguration

    init(configuration: DefaultAPIConfiguration) {
        self.configuration = configuration
    }

    func makeServices(client: Client<ExampleAPI>) {}
}

let configuration = DefaultAPIConfiguration(
    baseURL: URL(string: "https://api.example.com")!,
    headers: ["Authorization": "Bearer token"]
)
let client = Client<ExampleAPI>(configuration: configuration)
let accounts = try await client.execute(GetAccountsOperation()).value
```

For operations with variables, provide the GraphQL declaration and use variable
arguments in the selection:

```swift
struct AccountVariables: Encodable, Sendable {
    let id: String
}

@RootOperation(rootType: "Account.Root")
struct GetAccountOperation: QueryOperation {
    let variables: AccountVariables
    let variablesDeclaration: String? = "$id: ID!"

    @SelectionBuilder
    var body: [Selection] {
        field(Account.Root.self, arguments: [.variable("id")]) {
            Account.Fields.id
            Account.Fields.displayName
        }
    }
}
```

`@Root` assumes the field returns an array. For a single value, use
`@Root("viewer", valueType: "Self")`.

## Testing

Run the package test suite with:

```sh
swift test
```
