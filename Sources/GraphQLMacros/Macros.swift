import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct MacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        FieldsMacro.self,
        RootMacro.self,
        RootOperationMacro.self,
    ]
}

public struct FieldsMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let structDeclaration = declaration.as(StructDeclSyntax.self) else {
            return []
        }

        let typeName = structDeclaration.name.text
        let properties = structDeclaration.memberBlock.members.compactMap { member -> FieldProperty? in
            guard let variable = member.decl.as(VariableDeclSyntax.self),
                  !variable.modifiers.contains(where: { $0.name.text == "static" || $0.name.text == "class" }),
                  variable.bindingSpecifier.text == "let" || variable.bindingSpecifier.text == "var",
                  let binding = variable.bindings.first,
                  binding.accessorBlock == nil,
                  let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
                  let type = binding.typeAnnotation?.type else {
                return nil
            }

            let propertyName = pattern.identifier.text
            guard propertyName.first?.isLetter == true || propertyName.first == "_" else {
                return nil
            }

            return FieldProperty(name: propertyName, type: type.trimmed.description)
        }

        guard !properties.isEmpty else {
            return []
        }

        let fields = properties.map { property in
            "static let \(property.name) = ModelField<\(typeName), \(property.type)>(\"\(property.name)\", \\.\(property.name))"
        }

        let declaration = """
        enum Fields {
        \(fields.map { "    \($0)" }.joined(separator: "\n"))
        }
        """

        return [DeclSyntax(stringLiteral: declaration)]
    }
}

public struct RootMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let typeName = declaration.typeName,
              let fieldName = node.arguments?.firstStringLiteralArgument else {
            return []
        }

        let explicitValueType = node.arguments?.argument(named: "valueType")?.expression.stringLiteralValue
        let valueType = switch explicitValueType {
        case "Self": typeName
        case let valueType?: valueType
        case nil: "[\(typeName)]"
        }

        return [
            DeclSyntax(stringLiteral: """
            enum Root: ResponseRoot {
                typealias Value = \(valueType)
                static let fieldName = "\(fieldName)"
            }
            """)
        ]
    }
}

public struct RootOperationMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let rootType = node.arguments?.argument(named: "rootType")?.expression.stringLiteralValue else {
            return []
        }

        let hasVariables = declaration.memberBlock.members.contains { member in
            guard let variable = member.decl.as(VariableDeclSyntax.self) else {
                return false
            }

            return variable.bindings.contains { binding in
                binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text == "variables"
            }
        }

        var members = [
            "typealias Response = RootResponse<\(rootType)>"
        ]

        if !hasVariables {
            members.append("let variables = EmptyVariables()")
        }

        return members.map { DeclSyntax(stringLiteral: $0) }
    }
}

private extension DeclGroupSyntax {
    var typeName: String? {
        if let declaration = self.as(StructDeclSyntax.self) {
            return declaration.name.text
        }

        if let declaration = self.as(ClassDeclSyntax.self) {
            return declaration.name.text
        }

        if let declaration = self.as(EnumDeclSyntax.self) {
            return declaration.name.text
        }

        return nil
    }
}

private struct FieldProperty {
    let name: String
    let type: String
}

private extension AttributeSyntax.Arguments {
    var firstStringLiteralArgument: String? {
        guard case .argumentList(let arguments) = self,
              let expression = arguments.first?.expression.as(StringLiteralExprSyntax.self),
              expression.segments.count == 1,
              case .stringSegment(let segment) = expression.segments.first else {
            return nil
        }

        return segment.content.text
    }

    func argument(named name: String) -> LabeledExprSyntax? {
        guard case .argumentList(let arguments) = self else {
            return nil
        }

        return arguments.first { $0.label?.text == name }
    }
}

private extension ExprSyntax {
    var stringLiteralValue: String? {
        guard let expression = self.as(StringLiteralExprSyntax.self),
              expression.segments.count == 1,
              case .stringSegment(let segment) = expression.segments.first else {
            return nil
        }

        return segment.content.text
    }
}
