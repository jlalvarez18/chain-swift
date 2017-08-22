//
//  ChainError.swift
//  Chain-Swift
//
//  Created by Juan Alvarez on 8/21/17.
//
//

import Foundation
import HTTP
import JSON

public struct ChainError: Error {
    /// The HTTP status code to return.
    let status: Status
    
    // The reason this error was thrown.
    /// - Warning: This string will be
    /// displayed in production mode.
    let reason: String?
    
    /// `Optional` metadata.
    /// This will not be shown in production mode.
    let metadata: JSON?
    
    init(_ status: Status, reason: String? = nil, metadata: JSON? = nil) {
        self.status = status
        self.reason = reason
        self.metadata = metadata
    }
    
    public static let badRequest = ChainError(.badRequest)
    public static let notFound = ChainError(.notFound)
    public static let serverError = ChainError(.internalServerError)
    public static let unauthorized = ChainError(.unauthorized)
}
