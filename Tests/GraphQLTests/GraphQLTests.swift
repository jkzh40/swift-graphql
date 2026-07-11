import Foundation
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

private struct GetAccounts: QueryOperation {
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

@Test
func queryOperationRendersExplicitSelections() {
    #expect(
        GetAccounts().query.source == """
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
func requestEncoderPreservesGraphQLKeyCasing() throws {
    struct Variables: Encodable {
        let categoryIds: [String]
        let hiddenFromReports: Bool
    }

    let data = try Client<TestAPI>.makeEncoder().encode(
        Variables(categoryIds: ["category-1"], hiddenFromReports: true)
    )
    let json = String(decoding: data, as: UTF8.self)

    #expect(json.contains("\"categoryIds\""))
    #expect(json.contains("\"hiddenFromReports\""))
    #expect(!json.contains("category_ids"))
    #expect(!json.contains("hidden_from_reports"))
}

private struct TestAPI: API {
    struct Configuration: APIConfiguration {
        let baseURL = URL(string: "https://example.com")!
    }

    let configuration: Configuration

    init(configuration: Configuration) {
        self.configuration = configuration
    }

    func makeServices(client: Client<TestAPI>) {}
}
