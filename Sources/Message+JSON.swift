//
//  Message+JSON.swift
//  Chain-Swift
//
//  Created by Juan Alvarez on 8/21/17.
//
//

import Foundation
import HTTP
import JSON

extension Message {
    public var json: JSON? {
        get {
            if let existing = storage["json"] as? JSON {
                return existing
            } else if let type = headers["Content-Type"], type.contains(any: "application/json", "text/javascript") {
                guard case let .data(body) = body else { return nil }
                guard let json = try? JSON(bytes: body) else { return nil }
                storage["json"] = json
                return json
            } else {
                return nil
            }
        }
        set(json) {
            if let data = json {
                if let body = try? Body(data) {
                    self.body = body
                    headers["Content-Type"] = "application/json; charset=utf-8"
                }
            }
            storage["json"] = json
        }
    }
}

extension String {
    fileprivate func contains(any strings: String...) -> Bool {
        for string in strings where contains(string) {
            return true
        }
        return false
    }
}
