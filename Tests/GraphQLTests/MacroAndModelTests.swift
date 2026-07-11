import Foundation
import GraphQL
import Testing

@Fields
@Root("accounts")
private struct Account: Decodable, Equatable, Sendable {
    let id: String
    let displayName: String
}

@Fields
@Root("viewer", valueType: "Self")
private struct Viewer: Decodable, Equatable, Sendable {
    let id: String
}

@RootOperation(rootType: "Account.Root")
private struct AccountsOperation: QueryOperation {
    @SelectionBuilder
    var body: [Selection] {
        field(Account.Root.self) {
            Account.Fields.id
            Account.Fields.displayName
        }
    }
}

@Test
func fieldsMacroGeneratesTypedSelections() {
    #expect(Account.Fields.id.selection == Selection(name: "id"))
    #expect(Account.Fields.displayName.selection == Selection(name: "displayName"))
}

@Test
func rootMacroDefaultsToAnArrayResponse() throws {
    let data = Data(#"{"accounts":[{"id":"account-1","display_name":"Primary"}]}"#.utf8)
    let response = try Client<ModelTestAPI>.makeDecoder().decode(RootResponse<Account.Root>.self, from: data)

    #expect(response.value == [Account(id: "account-1", displayName: "Primary")])
}

@Test
func rootMacroSupportsSingleValueResponses() throws {
    let data = Data(#"{"viewer":{"id":"user-1"}}"#.utf8)
    let response = try Client<ModelTestAPI>.makeDecoder().decode(RootResponse<Viewer.Root>.self, from: data)

    #expect(response.value == Viewer(id: "user-1"))
}

@Test
func rootOperationMacroSynthesizesResponseAndEmptyVariables() throws {
    let operation = AccountsOperation()
    let variables = try Client<ModelTestAPI>.makeEncoder().encode(operation.variables)

    #expect(operation.query.operationName == "Accounts")
    #expect(String(decoding: variables, as: UTF8.self) == "{}")
}

@Test
func requestEncoderPreservesGraphQLKeyCasing() throws {
    struct Variables: Encodable {
        let categoryIds: [String]
        let hiddenFromReports: Bool
    }

    let data = try Client<ModelTestAPI>.makeEncoder().encode(
        Variables(categoryIds: ["category-1"], hiddenFromReports: true)
    )
    let json = String(decoding: data, as: UTF8.self)

    #expect(json.contains("\"categoryIds\""))
    #expect(json.contains("\"hiddenFromReports\""))
    #expect(!json.contains("category_ids"))
    #expect(!json.contains("hidden_from_reports"))
}

private struct ModelTestAPI: API {
    let configuration: DefaultAPIConfiguration

    init(configuration: DefaultAPIConfiguration) {
        self.configuration = configuration
    }

    func makeServices(client: Client<ModelTestAPI>) {}
}
