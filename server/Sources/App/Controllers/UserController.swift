//
//  UserController.swift
//  App
//
//  Created by Maxim on 3/31/19.
//

import Crypto
import FluentSQLite
import Vapor

final class UserController {
    func create(on req: Request) throws -> Future<User.AuthenticatedUser> {
        let futureUser = try req.content.decode(User.self)
        
        return futureUser.flatMap(to: User.AuthenticatedUser.self) { user in
            
            return User.query(on: req).filter(\.username == user.username).first().flatMap { existingUser in
                guard existingUser == nil else {
                    throw Abort(.badRequest, reason: "A user with this email already exists.")
                }
                let hasher = try req.make(BCryptDigest.self)
                let hashedPassword = try hasher.hash(user.password)
                let newUser = User(username: user.username, password: hashedPassword)
                return newUser.save(on: req).map(to: User.AuthenticatedUser.self) { authedUser in
                    return try User.AuthenticatedUser(id: authedUser.requireID(), username: authedUser.username)
                }
            }
        }
    }
    
    func login(on req: Request) throws -> User.AuthenticatedUser {
        let user = try req.requireAuthenticated(User.self)
        return try User.AuthenticatedUser(id: user.requireID(), username: user.username)
    }
}

extension UserController {
    func sendRegistrationHtmlForm(on req: Request) throws -> Future<View> {
        guard let html = try? req.view().render("auth.register") else {
            throw Abort(.badRequest, reason: "Could not render registration page")
        }
        return html
    }
    func sendLoginHtmlForm(on req: Request) throws -> Future<View> {
        guard let html = try? req.view().render("auth.login") else {
            throw Abort(.badRequest, reason: "Could not render login page")
        }
        return html
    }
}
