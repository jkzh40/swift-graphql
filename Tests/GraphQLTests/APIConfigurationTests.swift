import Foundation
import GraphQL
import Testing

@Test
func configurationBuildsDefaultEndpoint() throws {
    let baseURL = try #require(URL(string: "https://example.com/api"))
    let configuration = DefaultAPIConfiguration(baseURL: baseURL)

    #expect(configuration.endpoint == URL(string: "https://example.com/api/graphql"))
    #expect(configuration.headers.isEmpty)
}

@Test
func configurationSupportsCustomAndEmptyEndpointPaths() throws {
    let baseURL = try #require(URL(string: "https://example.com/api"))
    let custom = DefaultAPIConfiguration(
        baseURL: baseURL,
        endpointPath: "v2/query",
        headers: ["Authorization": "Bearer token"]
    )
    let empty = DefaultAPIConfiguration(baseURL: baseURL, endpointPath: "")

    #expect(custom.endpoint == URL(string: "https://example.com/api/v2/query"))
    #expect(custom.headers["Authorization"] == "Bearer token")
    #expect(empty.endpoint == baseURL)
}
