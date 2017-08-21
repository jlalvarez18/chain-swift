import XCTest
import JSON
@testable import Chain_Swift

extension StructuredDataWrapper {
    
    public func getObject<T: JSONInitializable>(_ indexers: PathIndexer...) throws -> T {
        return try getObject(path: indexers)
    }
    
    public func getObject<T: JSONInitializable>(path indexers: [PathIndexer]) throws -> T {
        let value = self[indexers] ?? .null
        return try T(json: JSON(value))
    }
}

class ChainTests: XCTestCase {
    
    struct Person: JSONInitializable {
        let name: String
        let address: Address
        
        init(json: JSON) throws {
            self.name = try json.get("name")
            self.address = try json.get("address", transform: { try Address(json: $0) })
        }
    }
    
    struct Address: JSONInitializable {
        let street: String
        
        init(json: JSON) throws {
            self.street = try json.get("street")
        }
    }
    
    func testExample() {
        do {
            var json = JSON()
            try json.set("name", "Juan Alvarez")
            try json.set("address", ["street": "2014 Plantation Dr"])
            
            let person = try Person(json: json)
            
            XCTAssertEqual(person.name, "Juan Alvarez")
            XCTAssertEqual(person.address.street, "2014 Plantation Dr")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
