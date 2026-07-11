import GraphQL
import Testing

private enum AccountsRoot: ResponseRoot {
    typealias Value = [TestAccount]

    static let fieldName = "accounts"
}

@Fields
private struct TestAccount: Decodable, Sendable {
    let id: String
    let displayName: String
}

private struct GetAccountsOperation: QueryOperation {
    typealias Response = RootResponse<AccountsRoot>

    let variables = EmptyVariables()

    @SelectionBuilder
    var body: [Selection] {
        field(AccountsRoot.self) {
            TestAccount.Fields.id
            TestAccount.Fields.displayName
        }
    }
}

private struct RenameAccountOperation: QueryOperation {
    struct Variables: Encodable, Sendable {
        let id: String
        let name: String
    }

    typealias Response = RootResponse<AccountsRoot>

    let variables = Variables(id: "account-1", name: "Checking")
    let operationKind = OperationKind.mutation
    let variablesDeclaration: String? = "$id: ID!, $name: String!"

    @SelectionBuilder
    var body: [Selection] {
        field(
            AccountsRoot.self,
            alias: "account",
            arguments: [
                .variable("id"),
                .variable("name"),
            ]
        ) {
            TestAccount.Fields.id
            TestAccount.Fields.displayName
        }
    }
}

@Test
func queryOperationRendersExplicitSelections() {
    #expect(GetAccountsOperation().query.operationName == "GetAccounts")
    #expect(
        GetAccountsOperation().query.source == """
        query GetAccounts {
          accounts {
            id
            displayName
          }
        }
        """
    )
}

@Test
func mutationRendersVariablesAliasAndArguments() {
    #expect(
        RenameAccountOperation().query.source == """
        mutation RenameAccount($id: ID!, $name: String!) {
          account: accounts(id: $id, name: $name) {
            id
            displayName
          }
        }
        """
    )
}

@Test(arguments: [true, false])
func selectionBuilderSupportsConditionalsAndLoops(includeDisplayName: Bool) {
    @SelectionBuilder
    func selections() -> [Selection] {
        for name in ["id"] {
            name
        }

        if includeDisplayName {
            "displayName"
        }
    }

    let expected = includeDisplayName
        ? [Selection(name: "id"), Selection(name: "displayName")]
        : [Selection(name: "id")]

    #expect(selections() == expected)
}

@Test
func argumentsRenderVariablesAndLiterals() {
    #expect(Argument.variable("accountId").rendered == "accountId: $accountId")
    #expect(Argument.variable("id", "accountId").rendered == "id: $accountId")
    #expect(Argument.literal("limit", "25").rendered == "limit: 25")
}
