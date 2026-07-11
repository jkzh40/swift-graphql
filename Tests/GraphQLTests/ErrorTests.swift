import GraphQL
import Testing

@Test
func clientErrorsProvideReadableLocalizedDescriptions() {
    let cases: [(ClientError, String)] = [
        (.invalidResponse, "The API returned an invalid response"),
        (.requestFailed(statusCode: 404, body: nil), "Request failed with HTTP 404"),
        (.requestFailed(statusCode: 500, body: "Unavailable"), "Request failed with HTTP 500: Unavailable"),
        (.responseErrors([ResponseError(message: "First"), ResponseError(message: "Second")]), "First; Second"),
        (.emptyResponse, "The response did not include data"),
    ]

    for (error, expectedDescription) in cases {
        #expect(error.description == expectedDescription)
        #expect(error.errorDescription == expectedDescription)
    }
}

@Test
func responseErrorUsesItsMessageAsDescription() {
    let error = ResponseError(message: "Validation failed")

    #expect(error.description == "Validation failed")
    #expect(error.errorDescription == "Validation failed")
}
