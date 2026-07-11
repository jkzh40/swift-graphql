# swift-graphql

[![CI](https://github.com/jkzh40/swift-graphql/actions/workflows/ci.yml/badge.svg)](https://github.com/jkzh40/swift-graphql/actions/workflows/ci.yml)

A lightweight GraphQL client and query DSL for Swift. It provides typed query
construction, explicit response-model decoding, a result-builder selection DSL,
and a macro that derives selections from Swift models.

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

Define a domain model and use `@Fields` to derive its selectable fields:

```swift
import GraphQL

@Fields
struct Account: Decodable, Sendable {
    let id: String?
    let displayName: String
}
```

Describe the operation's response shape separately from the reusable model, then
build the operation with explicit selections:

```swift
struct GetAccountsResponse: ResponseModel {
    let accounts: [Account]
}

struct GetAccountsOperation: QueryOperation {
    typealias Response = GetAccountsResponse

    let variables = EmptyVariables()

    @SelectionBuilder
    var body: [Selection] {
        field("accounts") {
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
let accounts = try await client.execute(GetAccountsOperation()).accounts
```

For operations with variables, provide the GraphQL declaration and use variable
arguments in the selection:

```swift
struct AccountVariables: Encodable, Sendable {
    let id: String
}

struct GetAccountResponse: ResponseModel {
    let account: Account?
}

struct GetAccountOperation: QueryOperation {
    typealias Response = GetAccountResponse

    let variables: AccountVariables
    let variablesDeclaration: String? = "$id: ID!"

    @SelectionBuilder
    var body: [Selection] {
        field("account", arguments: [.variable("id")]) {
            Account.Fields.id
            Account.Fields.displayName
        }
    }
}
```

Response models mirror the fields immediately inside GraphQL's `data` envelope.
They can represent lists, single values, aliases, multiple top-level fields, or
connection objects without coupling those shapes to domain models.

## Testing

Run the package test suite with:

```sh
swift test
```
