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

public protocol ResponseRoot: Sendable {
    associatedtype Value: Decodable & Sendable

    static var fieldName: String { get }
}

public struct RootResponse<Root: ResponseRoot>: ResponseModel {
    public let value: Root.Value

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        let key = DynamicCodingKey(stringValue: Root.fieldName)
        self.value = try container.decode(Root.Value.self, forKey: key)
    }
}

private struct DynamicCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int?

    init(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}

public struct ResponseError: Decodable, Error, LocalizedError, CustomStringConvertible, Equatable, Sendable {
    public let message: String

    public init(message: String) {
        self.message = message
    }

    public var description: String { message }
    public var errorDescription: String? { message }
}
