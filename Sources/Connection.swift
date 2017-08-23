//
//  Connection.swift
//  Chain-Swift
//
//  Created by Juan Alvarez on 8/19/17.
//
//

import Foundation
import HTTP
import JSON

let blacklistAttributes = Set([
    "after",
    "asset_tags",
    "asset_definition",
    "account_tags",
    "next",
    "reference_data",
    "tags",
])

extension HeaderKey {
    static public var chainRequestID: HeaderKey {
        return HeaderKey("Chain-Request-Id")
    }
}

class Connection {
    
    // Chain Core URL
    let baseUrl: URL
    
    // Chain Core client token for API access.
    let token: String?
    
    // https.Agent used to provide TLS config.
    let agent: String?
    
    let client: FoundationClient
    
    convenience init(baseUrlString: String, token: String?, agent: String?) throws {
        guard let url = URL(string: baseUrlString) else {
            throw ClientError.invalidRequestHost
        }
        
        try self.init(baseURL: url, token: token, agent: agent)
    }
    
    init(baseURL: URL, token: String?, agent: String?) throws {
        self.token = token
        self.agent = agent
        
        guard let host = baseURL.host else {
            throw ClientError.invalidRequestHost
        }
        
        guard let scheme = baseURL.scheme else {
            throw ClientError.invalidRequestScheme
        }
        
        guard let port = baseURL.port else {
            throw ClientError.invalidRequestPort
        }
        
        self.baseUrl = baseURL
        self.client = FoundationClient(scheme: scheme, hostname: host, port: port.port)
    }
    
    func request(path: String, body: JSON = JSON()) throws -> Response {
        var headers: [HeaderKey: String] = [
            HeaderKey.accept: "application/json",
            HeaderKey.contentType: "application/json",
        ]
        
        if let token = self.token, let tokenData = token.data(using: .utf8) {
            let tokenDataEncoded = tokenData.base64EncodedString()
            
            headers[.authorization] = "Basic \(tokenDataEncoded)"
        }
        
        if let agent = self.agent {
            headers[.userAgent] = agent
        }
        
        let bodyJSON = try snakeize(json: body)
        
        let url = self.baseUrl.appendingPathComponent(path)
        
        let req = Request(method: HTTP.Method.post,
                          uri: url.makeURI(),
                          headers: headers,
                          body: bodyJSON.makeBody())
        
        let res: Response
        
        do {
            res = try client.respond(to: req)
        } catch {
            var props = Node(nil)
            try! props.set("sourceError", error)
            
            let msg = "Fetch error: \(error.localizedDescription)"
            
            let _error = try! APIError.create(type: .fetch, message: msg, props: props)
            
            throw _error
        }
        
        guard let requestId = res.headers[.chainRequestID] else {
            var props = Node(nil)
            try props.set("response", res)
            try props.set("status", res.status.statusCode)
            
            let msg = "Chain-Request-Id header is missing. There may be an issue with your proxy or network configuration."
            let _error = try! APIError.create(type: .noRequestId, message: msg, props: props)
            
            throw _error
        }
        
        if res.status == .noContent {
            return res
        }
        
        guard let json = res.json else {
            throw try APIError.createJSONError(response: res)
        }
        
        guard (res.status.statusCode/100) == 2 else {
            let type = APIError.ErrorType.getType(response: res)
            let msg = try! APIError.formatErrorMessage(body: json.makeNode(in: nil), requestId: requestId)
            
            var props = Node(nil)
            try! props.set("response", res)
            try! props.set("status", res.status.statusCode)
            try! props.set("body", json)
            try! props.set("requestId", requestId)
            
            let _error = try! APIError.create(type: type, message: msg, props: props)
            
            throw _error
        }
        
        return try Response(status: .ok, json: json)
    }
}

fileprivate extension Connection {
    
    func camelize(json: JSON) throws -> JSON {
        return try camelize(data: json.wrapped)
    }
    
    func camelize(data: StructuredData) throws -> JSON {
        switch data {
        case .object(let dict):
            return try camelize(dict: dict)
        
        case .array(let a):
            let f = try a.map { (data) -> StructuredData in
                return try camelize(data: data).wrapped
            }
            
            return JSON(f)
            
        default:
            return JSON(data)
        }
    }
    
    func camelize(dict: [String: StructuredData]) throws -> JSON {
        var json = JSON()
        
        for (key, value) in dict {
            let newKey = key.camelize()
            var newValue = value
            
            if !blacklistAttributes.contains(key) {
                if let valueDict = value.object {
                    newValue = try camelize(dict: valueDict).wrapped
                }
            }
            
            try json.set(newKey, newValue)
        }
        
        return json
    }
}

fileprivate extension Connection {
    
    func snakeize(json: JSON) throws -> JSON {
        return try snakeize(data: json.wrapped)
    }
    
    func snakeize(data: StructuredData) throws -> JSON {
        switch data {
        case .object(let dict):
            return try snakeize(dict: dict)
            
        case .array(let a):
            let f = try a.map { (data) -> StructuredData in
                return try snakeize(data: data).wrapped
            }
            
            return JSON(f)
            
        default:
            return JSON(data)
        }
    }
    
    func snakeize(dict: [String: StructuredData]) throws -> JSON {
        var json = JSON()
        
        for (key, value) in dict {
            let newKey = key.snakeCased()
            var newValue = value
            
            // Skip all-caps keys
            if key.isAllCaps() {
                try json.set(newKey, newValue)
            } else {
                if !blacklistAttributes.contains(key) {
                    if let valueDict = value.object {
                        newValue = try snakeize(dict: valueDict).wrapped
                    }
                }
                
                try json.set(newKey, newValue)
            }
        }
        
        return json
    }
}
