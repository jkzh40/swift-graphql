import Foundation

public protocol APIConfiguration: Sendable {
    var baseURL: URL { get }
    var endpointPath: String { get }
    var headers: [String: String] { get }
}

public extension APIConfiguration {
    var endpointPath: String { "graphql" }
    var headers: [String: String] { [:] }

    var endpoint: URL {
        guard !endpointPath.isEmpty else {
            return baseURL
        }

        return baseURL.appendingPathComponent(endpointPath)
    }
}

public struct DefaultAPIConfiguration: APIConfiguration {
    public let baseURL: URL
    public let endpointPath: String
    public let headers: [String: String]

    public init(baseURL: URL, endpointPath: String = "graphql", headers: [String: String] = [:]) {
        self.baseURL = baseURL
        self.endpointPath = endpointPath
        self.headers = headers
    }
}
