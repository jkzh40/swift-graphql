@resultBuilder
public enum SelectionBuilder {
    public static func buildBlock(_ components: [Selection]...) -> [Selection] {
        components.flatMap { $0 }
    }

    public static func buildExpression(_ expression: Selection) -> [Selection] {
        [expression]
    }

    public static func buildExpression<Expression: SelectionConvertible>(_ expression: Expression) -> [Selection] {
        [expression.selection]
    }

    public static func buildExpression(_ expression: String) -> [Selection] {
        [Selection(name: expression)]
    }

    public static func buildExpression(_ expression: [Selection]) -> [Selection] {
        expression
    }

    public static func buildOptional(_ component: [Selection]?) -> [Selection] {
        component ?? []
    }

    public static func buildEither(first component: [Selection]) -> [Selection] {
        component
    }

    public static func buildEither(second component: [Selection]) -> [Selection] {
        component
    }

    public static func buildArray(_ components: [[Selection]]) -> [Selection] {
        components.flatMap { $0 }
    }
}

public protocol SelectionConvertible: Sendable {
    var selection: Selection { get }
}

public struct Selection: Equatable, Sendable {
    public let name: String
    public let alias: String?
    public let arguments: [Argument]
    public let selections: [Selection]

    public init(name: String, alias: String? = nil, arguments: [Argument] = [], selections: [Selection] = []) {
        self.name = name
        self.alias = alias
        self.arguments = arguments
        self.selections = selections
    }

    public func render(indentation: Int) -> String {
        let prefix = String(repeating: "  ", count: indentation)
        let aliasPrefix = alias.map { "\($0): " } ?? ""
        let renderedArguments = arguments.isEmpty ? "" : "(\(arguments.map(\.rendered).joined(separator: ", ")))"

        guard !selections.isEmpty else {
            return "\(prefix)\(aliasPrefix)\(name)\(renderedArguments)"
        }

        let renderedSelections = selections.map { $0.render(indentation: indentation + 1) }.joined(separator: "\n")
        return """
        \(prefix)\(aliasPrefix)\(name)\(renderedArguments) {
        \(renderedSelections)
        \(prefix)}
        """
    }
}

extension Selection: SelectionConvertible {
    public var selection: Selection { self }
}

public struct ModelField<Root: Sendable, Value: Sendable>: SelectionConvertible, @unchecked Sendable {
    public let name: String
    public let keyPath: KeyPath<Root, Value>
    public let selections: [Selection]

    public init(_ name: String, _ keyPath: KeyPath<Root, Value>) {
        self.name = name
        self.keyPath = keyPath
        self.selections = []
    }

    public init(
        _ name: String,
        _ keyPath: KeyPath<Root, Value>,
        @SelectionBuilder selections: () -> [Selection]
    ) {
        self.name = name
        self.keyPath = keyPath
        self.selections = selections()
    }

    public var selection: Selection {
        Selection(name: name, selections: selections)
    }

    public func selecting(
        alias: String? = nil,
        arguments: [Argument] = [],
        @SelectionBuilder selections: () -> [Selection]
    ) -> Selection {
        Selection(name: name, alias: alias, arguments: arguments, selections: selections())
    }
}

public struct Argument: Equatable, Sendable {
    public let name: String
    public let value: String

    public var rendered: String {
        "\(name): \(value)"
    }

    public static func variable(_ name: String, _ variableName: String? = nil) -> Argument {
        Argument(name: name, value: "$\(variableName ?? name)")
    }

    public static func literal(_ name: String, _ value: String) -> Argument {
        Argument(name: name, value: value)
    }
}

public func field(
    _ name: String,
    alias: String? = nil,
    arguments: [Argument] = [],
    @SelectionBuilder selections: () -> [Selection] = { [] }
) -> Selection {
    Selection(name: name, alias: alias, arguments: arguments, selections: selections())
}
