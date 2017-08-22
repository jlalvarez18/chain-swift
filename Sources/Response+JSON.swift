//
//  Response+JSON.swift
//  Chain-Swift
//
//  Created by Juan Alvarez on 8/21/17.
//
//

import Foundation
import HTTP
import JSON

extension Response {
    /// Convenience Initializer
    ///
    /// - parameter status: the http status
    /// - parameter json: any value that will be attempted to be serialized as json.  Use 'Json' for more complex objects
    public convenience init(status: Status, json: JSON) throws {
        let headers: [HeaderKey: String] = [
            "Content-Type": "application/json; charset=utf-8"
        ]
        self.init(status: status, headers: headers, body: try Body(json))
    }
}
