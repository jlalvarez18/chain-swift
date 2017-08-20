//
//  RFC3339.swift
//  Chain-Swift
//
//  Created by Juan Alvarez on 8/20/17.
//
//

import Foundation

public struct RFC3339 {
    public static let shared = RFC3339()
    public let formatter: DateFormatter
    
    public init() {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        
        self.formatter = formatter
    }
}

extension Date {
    public var rfc3339: String {
        return RFC3339.shared.formatter.string(from: self)
    }
    
    public init?(rfc3339: String) {
        guard let date = RFC3339.shared.formatter.date(from: rfc3339) else {
            return nil
        }
        
        self = date
    }
}
