/// Generates a nested `Fields` namespace containing typed selections for the
/// stored properties of the attached structure.
@attached(member, names: named(Fields))
public macro Fields() = #externalMacro(module: "GraphQLMacros", type: "FieldsMacro")

/// Generates a nested `Root` response descriptor for a GraphQL field.
///
/// The root value defaults to an array of the attached type. Pass `"Self"` as
/// `valueType` when the field returns a single value.
@attached(member, names: named(Root))
public macro Root(_ fieldName: String, valueType: String? = nil) = #externalMacro(module: "GraphQLMacros", type: "RootMacro")

/// Generates the response type and empty variables required by a root query.
///
/// A declaration that provides its own `variables` property retains it.
@attached(member, names: named(Response), named(variables))
public macro RootOperation(rootType: String) = #externalMacro(module: "GraphQLMacros", type: "RootOperationMacro")
