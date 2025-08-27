import XCTest
@testable import SnippetConverterCore
import Foundation

final class SnippetTests: XCTestCase {
    
    // MARK: - Alfredsnippet Tests
    
    func test_alfredsnippet_decodesValidJson_returnsCorrectValues() throws {
        let json = """
        {
            "snippet": "Hello World!",
            "uid": "test-uid-123",
            "name": "Test Greeting",
            "keyword": "hello"
        }
        """.data(using: .utf8)!
        
        let alfredsnippet = try JSONDecoder().decode(Alfredsnippet.self, from: json)
        
        XCTAssertEqual(alfredsnippet.snippet, "Hello World!")
        XCTAssertEqual(alfredsnippet.uid, "test-uid-123")
        XCTAssertEqual(alfredsnippet.name, "Test Greeting")
        XCTAssertEqual(alfredsnippet.keyword, "hello")
    }
    
    func test_alfredsnippet_encodesToJson_returnsValidJson() throws {
        let alfredsnippet = Alfredsnippet(
            snippet: "Hello World!",
            uid: "test-uid-123", 
            name: "Test Greeting",
            keyword: "hello"
        )
        
        let jsonData = try JSONEncoder().encode(alfredsnippet)
        let decodedSnippet = try JSONDecoder().decode(Alfredsnippet.self, from: jsonData)
        
        XCTAssertEqual(decodedSnippet.snippet, alfredsnippet.snippet)
        XCTAssertEqual(decodedSnippet.uid, alfredsnippet.uid)
        XCTAssertEqual(decodedSnippet.name, alfredsnippet.name)
        XCTAssertEqual(decodedSnippet.keyword, alfredsnippet.keyword)
    }
    
    func test_alfredsnippet_decodesEmptyStrings_handlesGracefully() throws {
        let json = """
        {
            "snippet": "",
            "uid": "",
            "name": "",
            "keyword": ""
        }
        """.data(using: .utf8)!
        
        let alfredsnippet = try JSONDecoder().decode(Alfredsnippet.self, from: json)
        
        XCTAssertEqual(alfredsnippet.snippet, "")
        XCTAssertEqual(alfredsnippet.uid, "")
        XCTAssertEqual(alfredsnippet.name, "")
        XCTAssertEqual(alfredsnippet.keyword, "")
    }
    
    func test_alfredsnippet_decodesSpecialCharacters_preservesCharacters() throws {
        let jsonString = """
        {
            "snippet": "Special chars: <>&\\"'\\n\\t\\r 🚀 émojis & àccénts",
            "uid": "special-uid",
            "name": "Special Test",
            "keyword": "special"
        }
        """
        let json = jsonString.data(using: .utf8)!
        
        let alfredsnippet = try JSONDecoder().decode(Alfredsnippet.self, from: json)
        
        XCTAssertEqual(alfredsnippet.snippet, "Special chars: <>&\"'\n\t\r 🚀 émojis & àccénts")
        XCTAssertEqual(alfredsnippet.uid, "special-uid")
        XCTAssertEqual(alfredsnippet.name, "Special Test")
        XCTAssertEqual(alfredsnippet.keyword, "special")
    }
    
    func test_alfredsnippet_decodesMissingField_throwsError() {
        let jsonMissingSnippet = """
        {
            "uid": "test-uid",
            "name": "Test",
            "keyword": "test"
        }
        """.data(using: .utf8)!
        
        XCTAssertThrowsError(try JSONDecoder().decode(Alfredsnippet.self, from: jsonMissingSnippet)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }
    
    func test_alfredsnippet_decodesInvalidJson_throwsError() {
        let invalidJson = "{ invalid json }".data(using: .utf8)!
        
        XCTAssertThrowsError(try JSONDecoder().decode(Alfredsnippet.self, from: invalidJson)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }
    
    func test_alfredsnippet_decodesLargeContent_handlesCorrectly() throws {
        let largeSnippet = String(repeating: "Lorem ipsum dolor sit amet. ", count: 1000)
        let json = """
        {
            "snippet": "\(largeSnippet)",
            "uid": "large-uid",
            "name": "Large Content Test",
            "keyword": "large"
        }
        """.data(using: .utf8)!
        
        let alfredsnippet = try JSONDecoder().decode(Alfredsnippet.self, from: json)
        
        XCTAssertEqual(alfredsnippet.snippet, largeSnippet)
        XCTAssertEqual(alfredsnippet.uid, "large-uid")
        XCTAssertEqual(alfredsnippet.name, "Large Content Test")
        XCTAssertEqual(alfredsnippet.keyword, "large")
    }
    
    // MARK: - Snippet Wrapper Tests
    
    func test_snippet_decodesValidJson_returnsCorrectAlfredsnippet() throws {
        let json = """
        {
            "alfredsnippet": {
                "snippet": "Hello World!",
                "uid": "test-uid-123",
                "name": "Test Greeting",
                "keyword": "hello"
            }
        }
        """.data(using: .utf8)!
        
        let snippet = try JSONDecoder().decode(Snippet.self, from: json)
        
        XCTAssertEqual(snippet.alfredsnippet.snippet, "Hello World!")
        XCTAssertEqual(snippet.alfredsnippet.uid, "test-uid-123")
        XCTAssertEqual(snippet.alfredsnippet.name, "Test Greeting")
        XCTAssertEqual(snippet.alfredsnippet.keyword, "hello")
    }
    
    func test_snippet_encodesToJson_returnsValidJson() throws {
        let alfredsnippet = Alfredsnippet(
            snippet: "Hello World!",
            uid: "test-uid-123",
            name: "Test Greeting", 
            keyword: "hello"
        )
        let snippet = Snippet(alfredsnippet: alfredsnippet)
        
        let jsonData = try JSONEncoder().encode(snippet)
        let decodedSnippet = try JSONDecoder().decode(Snippet.self, from: jsonData)
        
        XCTAssertEqual(decodedSnippet.alfredsnippet.snippet, snippet.alfredsnippet.snippet)
        XCTAssertEqual(decodedSnippet.alfredsnippet.uid, snippet.alfredsnippet.uid)
        XCTAssertEqual(decodedSnippet.alfredsnippet.name, snippet.alfredsnippet.name)
        XCTAssertEqual(decodedSnippet.alfredsnippet.keyword, snippet.alfredsnippet.keyword)
    }
    
    func test_snippet_decodesMissingAlfredsnippetField_throwsError() {
        let json = """
        {
            "some_other_field": "value"
        }
        """.data(using: .utf8)!
        
        XCTAssertThrowsError(try JSONDecoder().decode(Snippet.self, from: json)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }
    
    func test_snippet_decodesInvalidNestedJson_throwsError() {
        let json = """
        {
            "alfredsnippet": {
                "snippet": "Hello",
                "uid": "test-uid"
            }
        }
        """.data(using: .utf8)!
        
        XCTAssertThrowsError(try JSONDecoder().decode(Snippet.self, from: json)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }
    
    // MARK: - JSON Roundtrip Tests
    
    func test_snippetRoundtrip_preservesAllData() throws {
        let originalAlfredsnippet = Alfredsnippet(
            snippet: "Multi-line\nsnippet with\ttabs and special chars: <>&\"'",
            uid: "roundtrip-uid-123",
            name: "Roundtrip Test Snippet",
            keyword: "roundtrip"
        )
        let originalSnippet = Snippet(alfredsnippet: originalAlfredsnippet)
        
        // Encode to JSON
        let jsonData = try JSONEncoder().encode(originalSnippet)
        
        // Decode from JSON
        let decodedSnippet = try JSONDecoder().decode(Snippet.self, from: jsonData)
        
        // Verify all fields are preserved
        XCTAssertEqual(decodedSnippet.alfredsnippet.snippet, originalAlfredsnippet.snippet)
        XCTAssertEqual(decodedSnippet.alfredsnippet.uid, originalAlfredsnippet.uid)
        XCTAssertEqual(decodedSnippet.alfredsnippet.name, originalAlfredsnippet.name)
        XCTAssertEqual(decodedSnippet.alfredsnippet.keyword, originalAlfredsnippet.keyword)
    }
    
    func test_alfredsnippetRoundtrip_preservesAllData() throws {
        let original = Alfredsnippet(
            snippet: "Code snippet:\n```swift\nprint(\"Hello\")\n```",
            uid: "code-uid-456",
            name: "Code Block Example",
            keyword: "swiftcode"
        )
        
        // Encode to JSON
        let jsonData = try JSONEncoder().encode(original)
        
        // Decode from JSON
        let decoded = try JSONDecoder().decode(Alfredsnippet.self, from: jsonData)
        
        // Verify all fields are preserved
        XCTAssertEqual(decoded.snippet, original.snippet)
        XCTAssertEqual(decoded.uid, original.uid)
        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.keyword, original.keyword)
    }
    
    // MARK: - Real-world Alfred JSON Format Tests
    
    func test_realWorldAlfredFormat_parsesCorrectly() throws {
        // This mimics the actual JSON structure from Alfred export
        let realWorldJson = """
        {
            "alfredsnippet": {
                "snippet": "Thank you for your email. I'll get back to you shortly.",
                "uid": "E8B8C5D1-2F3A-4B5C-8D6E-9F1A2B3C4D5E",
                "name": "Email Response - Thank You",
                "keyword": "thanks"
            }
        }
        """.data(using: .utf8)!
        
        let snippet = try JSONDecoder().decode(Snippet.self, from: realWorldJson)
        
        XCTAssertEqual(snippet.alfredsnippet.snippet, "Thank you for your email. I'll get back to you shortly.")
        XCTAssertEqual(snippet.alfredsnippet.uid, "E8B8C5D1-2F3A-4B5C-8D6E-9F1A2B3C4D5E")
        XCTAssertEqual(snippet.alfredsnippet.name, "Email Response - Thank You")
        XCTAssertEqual(snippet.alfredsnippet.keyword, "thanks")
    }
    
    func test_realWorldComplexSnippet_parsesCorrectly() throws {
        let complexJson = """
        {
            "alfredsnippet": {
                "snippet": "Dear {cursor},\\n\\nI hope this email finds you well. I'm writing to follow up on our conversation about {clipboard}.\\n\\nLooking forward to hearing from you.\\n\\nBest regards,\\n{name}",
                "uid": "COMPLEX-UID-789",
                "name": "Email Template with Placeholders",
                "keyword": "emailtemplate"
            }
        }
        """.data(using: .utf8)!
        
        let snippet = try JSONDecoder().decode(Snippet.self, from: complexJson)
        
        XCTAssertTrue(snippet.alfredsnippet.snippet.contains("{cursor}"))
        XCTAssertTrue(snippet.alfredsnippet.snippet.contains("{clipboard}"))
        XCTAssertTrue(snippet.alfredsnippet.snippet.contains("{name}"))
        XCTAssertTrue(snippet.alfredsnippet.snippet.contains("\n"))
        XCTAssertEqual(snippet.alfredsnippet.keyword, "emailtemplate")
    }
}