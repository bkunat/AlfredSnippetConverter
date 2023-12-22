struct Snippet: Codable {
    let alfredsnippet: Alfredsnippet

    enum CodingKeys: String, CodingKey {
        case alfredsnippet
    }
}

struct Alfredsnippet: Codable {
    let snippet: String
    let uid: String
    let name: String
    let keyword: String

    enum CodingKeys: String, CodingKey {
        case snippet
        case uid
        case name
        case keyword
    }
}
