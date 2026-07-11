import Foundation

struct ResponseEnvelope<Payload: ResponseModel>: Decodable, Sendable {
    let data: Payload?
    let errors: [ResponseError]?
}

public struct ResponseError: Decodable, Error, LocalizedError, CustomStringConvertible, Equatable, Sendable {
    public let message: String

    public init(message: String) {
        self.message = message
    }

    public var description: String { message }
    public var errorDescription: String? { message }
}
