import Foundation

public protocol API: Sendable {
    associatedtype Configuration: APIConfiguration
    associatedtype ServiceCatalog

    var configuration: Configuration { get }

    init(configuration: Configuration)
    func makeServices(client: Client<Self>) -> ServiceCatalog
}

public extension API {
    var endpoint: URL { configuration.endpoint }
    var headers: [String: String] { configuration.headers }
}

public protocol Service: Sendable {
    associatedtype ServiceAPI: API

    init(client: Client<ServiceAPI>)
}

public protocol Operation: Sendable {
    associatedtype Variables: Encodable & Sendable
    /// The fields nested immediately inside the GraphQL `data` envelope.
    associatedtype Response: ResponseModel

    var query: Query { get }
    var variables: Variables { get }
}

/// A decodable response shape matching the fields selected by an operation.
public protocol ResponseModel: Decodable, Sendable {}

extension Array: ResponseModel where Element: ResponseModel {}
