import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import GraphQL
import Testing

@Suite(.serialized)
private struct ClientTests {
    @Test
    func executeBuildsPOSTRequestAndDecodesData() async throws {
        URLProtocolStub.handler = { request in
            #expect(request.url == URL(string: "https://example.com/graphql"))
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
            #expect(request.value(forHTTPHeaderField: "X-Test") == "value")

            let body = try requestBody(from: request)
            let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
            let variables = try #require(json["variables"] as? [String: Any])

            #expect(json["operationName"] as? String == "Greeting")
            #expect(json["query"] as? String == "query Greeting { greeting }")
            #expect(variables["userId"] as? String == "user-1")

            return (
                try makeHTTPResponse(statusCode: 200),
                Data(#"{"data":{"greeting":"Hello"}}"#.utf8)
            )
        }
        defer { URLProtocolStub.handler = nil }

        let response = try await makeClient().execute(GreetingOperation())

        #expect(response.greeting == "Hello")
    }

    @Test
    func executeSurfacesGraphQLErrors() async throws {
        URLProtocolStub.handler = { _ in
            (
                try makeHTTPResponse(statusCode: 200),
                Data(#"{"errors":[{"message":"Access denied"}]}"#.utf8)
            )
        }
        defer { URLProtocolStub.handler = nil }

        do {
            _ = try await makeClient().execute(GreetingOperation())
            Issue.record("Expected a GraphQL response error")
        } catch let error as ClientError {
            guard case .responseErrors(let errors) = error else {
                Issue.record("Expected responseErrors, received \(error)")
                return
            }

            #expect(errors == [ResponseError(message: "Access denied")])
            #expect(error.errorDescription == "Access denied")
        }
    }

    @Test
    func executeIncludesHTTPErrorBody() async throws {
        URLProtocolStub.handler = { _ in
            (
                try makeHTTPResponse(statusCode: 429),
                Data("Too many requests".utf8)
            )
        }
        defer { URLProtocolStub.handler = nil }

        do {
            _ = try await makeClient().execute(GreetingOperation())
            Issue.record("Expected an HTTP request error")
        } catch let error as ClientError {
            guard case .requestFailed(let statusCode, let body) = error else {
                Issue.record("Expected requestFailed, received \(error)")
                return
            }

            #expect(statusCode == 429)
            #expect(body == "Too many requests")
        }
    }

    @Test
    func executeRejectsResponsesWithoutData() async throws {
        URLProtocolStub.handler = { _ in
            (
                try makeHTTPResponse(statusCode: 200),
                Data(#"{"data":null}"#.utf8)
            )
        }
        defer { URLProtocolStub.handler = nil }

        do {
            _ = try await makeClient().execute(GreetingOperation())
            Issue.record("Expected an empty response error")
        } catch let error as ClientError {
            guard case .emptyResponse = error else {
                Issue.record("Expected emptyResponse, received \(error)")
                return
            }
        }
    }
}

private struct GreetingOperation: GraphQL.Operation {
    struct Variables: Encodable, Sendable {
        let userId: String
    }

    typealias Response = GreetingResponse

    let query = Query(operationName: "Greeting", source: "query Greeting { greeting }")
    let variables = Variables(userId: "user-1")
}

private struct GreetingResponse: ResponseModel {
    let greeting: String
}

private struct ClientTestAPI: API {
    let configuration: DefaultAPIConfiguration

    init(configuration: DefaultAPIConfiguration) {
        self.configuration = configuration
    }

    func makeServices(client: Client<ClientTestAPI>) {}
}

private func makeClient() throws -> Client<ClientTestAPI> {
    let sessionConfiguration = URLSessionConfiguration.ephemeral
    sessionConfiguration.protocolClasses = [URLProtocolStub.self]
    let session = URLSession(configuration: sessionConfiguration)
    let baseURL = try #require(URL(string: "https://example.com"))
    let configuration = DefaultAPIConfiguration(baseURL: baseURL, headers: ["X-Test": "value"])
    return Client(configuration: configuration, session: session)
}

private func makeHTTPResponse(statusCode: Int) throws -> HTTPURLResponse {
    let url = try #require(URL(string: "https://example.com/graphql"))
    return try #require(
        HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)
    )
}

private func requestBody(from request: URLRequest) throws -> Data {
    if let body = request.httpBody {
        return body
    }

    let stream = try #require(request.httpBodyStream)
    stream.open()
    defer { stream.close() }

    var data = Data()
    var buffer = [UInt8](repeating: 0, count: 1_024)
    while stream.hasBytesAvailable {
        let count = stream.read(&buffer, maxLength: buffer.count)
        guard count >= 0 else {
            throw stream.streamError ?? URLError(.cannotDecodeRawData)
        }
        guard count > 0 else { break }
        data.append(buffer, count: count)
    }
    return data
}

private final class URLProtocolStub: URLProtocol, @unchecked Sendable {
    typealias Handler = @Sendable (URLRequest) throws -> (URLResponse, Data)

    nonisolated(unsafe) static var handler: Handler?

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
