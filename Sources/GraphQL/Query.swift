public struct Query: Sendable {
    public let operationName: String
    public let source: String

    public init(operationName: String, source: String) {
        self.operationName = operationName
        self.source = source
    }

    public init<OperationQuery: QueryType>(_ query: OperationQuery) {
        self.operationName = query.operationName
        self.source = query.render()
    }
}

public protocol QueryType: Sendable {
    var operationKind: OperationKind { get }
    var operationName: String { get }
    var variablesDeclaration: String? { get }
    var body: [Selection] { get }
}

public extension QueryType {
    var operationKind: OperationKind { .query }
    var operationName: String {
        String(describing: Self.self)
            .removingOperationSuffix("Operation")
            .removingOperationSuffix("Query")
    }

    var variablesDeclaration: String? { nil }

    func render() -> String {
        let variables = variablesDeclaration.map { "(\($0))" } ?? ""
        let selections = body.map { $0.render(indentation: 1) }.joined(separator: "\n")
        return """
        \(operationKind.rawValue) \(operationName)\(variables) {
        \(selections)
        }
        """
    }
}

public enum OperationKind: String, Sendable {
    case query
    case mutation
}

public protocol QueryOperation: Operation, QueryType {}

public extension QueryOperation {
    var query: Query { Query(self) }
}

private extension String {
    func removingOperationSuffix(_ suffix: String) -> String {
        hasSuffix(suffix) ? String(dropLast(suffix.count)) : self
    }
}
