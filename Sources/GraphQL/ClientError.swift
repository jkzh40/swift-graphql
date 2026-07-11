import Foundation

public enum ClientError: Error, CustomStringConvertible {
    case invalidResponse
    case requestFailed(statusCode: Int, body: String?)
    case responseErrors([ResponseError])
    case emptyResponse

    public var description: String {
        switch self {
        case .invalidResponse:
            "The API returned an invalid response"
        case .requestFailed(let statusCode, let body):
            if let body, !body.isEmpty {
                "Request failed with HTTP \(statusCode): \(body)"
            } else {
                "Request failed with HTTP \(statusCode)"
            }
        case .responseErrors(let errors):
            errors.map(\.message).joined(separator: "; ")
        case .emptyResponse:
            "The response did not include data"
        }
    }
}
