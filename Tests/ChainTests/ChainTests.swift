import XCTest
import JSON
@testable import Chain_Swift

class ChainTests: XCTestCase {
    
    struct Person: NodeInitializable {
        let name: String
        let address: Address
        let object: JSON
        let multiAddresses: [Address]
        
        init(node: Node) throws {
            self.name = try node.get("name")
            self.address = try node.get("address")
            self.object = try node.get("object")
            self.multiAddresses = try node.get("multiAddresses")
        }
    }
    
    struct Address: NodeInitializable {
        let street: String
        
        init(node: Node) throws {
            self.street = try node.get("street")
        }
    }
    
    func testExample() {
        do {
            var json = JSON()
            try json.set("name", "Juan Alvarez")
            try json.set("address", ["street": "2014 Plantation Dr"])
            try json.set("object", JSON())
            try json.set("multiAddresses", [["street": "2014 Plantation Dr"], ["street": "2016 Plantation Dr"]])
            
            let person = try Person(node: json)
            
            XCTAssertEqual(person.name, "Juan Alvarez")
            XCTAssertEqual(person.address.street, "2014 Plantation Dr")
            XCTAssertNotNil(person.object)
            XCTAssertNotNil(person.multiAddresses)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
