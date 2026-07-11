import Foundation

public struct EmptyVariables: Encodable, Sendable {
    public init() {}
}

struct Request<Variables: Encodable>: Encodable {
    let operationName: String
    let query: String
    let variables: Variables

    init<RequestOperation: Operation>(operation: RequestOperation) where RequestOperation.Variables == Variables {
        self.operationName = operation.query.operationName
        self.query = operation.query.source
        self.variables = operation.variables
    }
}

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
