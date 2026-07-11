import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct Client<Target: API>: Sendable {
    public let api: Target
    public var configuration: Target.Configuration {
        api.configuration
    }

    public var services: Target.ServiceCatalog {
        api.makeServices(client: self)
    }

    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(
        api: Target,
        session: URLSession = .shared,
        encoder: JSONEncoder = Self.makeEncoder(),
        decoder: JSONDecoder = Self.makeDecoder()
    ) {
        self.api = api
        self.session = session
        self.encoder = encoder
        self.decoder = decoder
    }

    public init(
        configuration: Target.Configuration,
        session: URLSession = .shared,
        encoder: JSONEncoder = Self.makeEncoder(),
        decoder: JSONDecoder = Self.makeDecoder()
    ) {
        self.init(api: Target(configuration: configuration), session: session, encoder: encoder, decoder: decoder)
    }

    public func execute<RequestOperation: Operation>(_ operation: RequestOperation) async throws -> RequestOperation.Response {
        let request = try makeRequest(operation: operation)
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClientError.invalidResponse
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            throw ClientError.requestFailed(
                statusCode: httpResponse.statusCode,
                body: String(data: data, encoding: .utf8)
            )
        }

        let envelope = try decoder.decode(ResponseEnvelope<RequestOperation.Response>.self, from: data)

        if let errors = envelope.errors, !errors.isEmpty {
            throw ClientError.responseErrors(errors)
        }

        guard let response = envelope.data else {
            throw ClientError.emptyResponse
        }

        return response
    }

    private func makeRequest<RequestOperation: Operation>(operation: RequestOperation) throws -> URLRequest {
        var request = URLRequest(url: configuration.endpoint)
        request.httpMethod = "POST"
        request.httpBody = try encoder.encode(Request(operation: operation))

        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        for (key, value) in configuration.headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        return request
    }

    public static func makeEncoder() -> JSONEncoder {
        JSONEncoder()
    }

    public static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}
