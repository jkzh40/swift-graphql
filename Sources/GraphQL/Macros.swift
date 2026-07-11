@attached(member, names: named(Fields))
public macro Fields() = #externalMacro(module: "GraphQLMacros", type: "FieldsMacro")

@attached(member, names: named(Root))
public macro Root(_ fieldName: String, valueType: String? = nil) = #externalMacro(module: "GraphQLMacros", type: "RootMacro")

@attached(member, names: named(Response), named(variables))
public macro RootOperation(rootType: String) = #externalMacro(module: "GraphQLMacros", type: "RootOperationMacro")
