import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct MacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        FieldsMacro.self,
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

private struct FieldProperty {
    let name: String
    let type: String
}
