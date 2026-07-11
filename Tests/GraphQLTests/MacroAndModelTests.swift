import Foundation
import GraphQL
import Testing

@Fields
private struct Account: Decodable, Equatable, Sendable {
    let id: String
    let displayName: String
}

@Fields
private struct Viewer: Decodable, Equatable, Sendable {
    let id: String
}

private struct AccountsResponse: ResponseModel, Equatable {
    let accounts: [Account]
}

private struct ViewerResponse: ResponseModel, Equatable {
    let viewer: Viewer
}

private struct AccountsOperation: QueryOperation {
    typealias Response = AccountsResponse

    let variables = EmptyVariables()

    @SelectionBuilder
    var body: [Selection] {
        field("accounts") {
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
func explicitResponseModelDecodesAnArrayField() throws {
    let data = Data(#"{"accounts":[{"id":"account-1","display_name":"Primary"}]}"#.utf8)
    let response = try Client<ModelTestAPI>.makeDecoder().decode(AccountsResponse.self, from: data)

    #expect(response.accounts == [Account(id: "account-1", displayName: "Primary")])
}

@Test
func explicitResponseModelDecodesASingleValueField() throws {
    let data = Data(#"{"viewer":{"id":"user-1"}}"#.utf8)
    let response = try Client<ModelTestAPI>.makeDecoder().decode(ViewerResponse.self, from: data)

    #expect(response.viewer == Viewer(id: "user-1"))
}

@Test
func operationDeclaresItsResponseAndEmptyVariables() throws {
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
