/// Generates a nested `Fields` namespace containing typed selections for the
/// stored properties of the attached structure.
@attached(member, names: named(Fields))
public macro Fields() = #externalMacro(module: "GraphQLMacros", type: "FieldsMacro")
