//
//  User.swift
//  App
//
//  Created by Maxim on 3/31/19.
//

import Authentication
import Fluent
import FluentSQLite
import Foundation
import Vapor

final class User: Content, SQLiteUUIDModel, Migration {
    var id: UUID?
    var username: String
    var password: String
    
    init(username: String, password: String) {
        self.username = username
        self.password = password
    }
}

extension User: BasicAuthenticatable {
    static var usernameKey: UsernameKey { return \User.username }
    static var passwordKey: PasswordKey { return \User.password }
}

extension User {
    struct AuthenticatedUser: Content {
        var id: UUID
        var username: String
    }
    
    struct LoginRequest: Content {
        var username: String
        var password: String
    }
}

extension User {
    var files: Children<User, FSItem>  {
        return children(\.userID)
    }
}
