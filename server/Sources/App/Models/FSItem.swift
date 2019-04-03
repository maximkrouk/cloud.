//
//  Storage.swift
//  App
//
//  Created by Maxim on 3/31/19.
//

import Foundation

import FluentSQLite
import Foundation
import Vapor

final class FSItem: Content, SQLiteUUIDModel, Migration {
    var id: UUID?
    var file: File
    var userID: User.ID
    
    init(file: File, userID: User.ID) {
        self.file = file
        self.userID = userID
    }
    
    init(name: String, data: Data, userID: User.ID) {
        self.file = File(data: data, filename: name)
        self.userID = userID
    }
}

extension FSItem {
    var owner: Parent<FSItem, User> {
        return parent(\.userID)
    }
}

extension FSItem {
    
    struct FileWrapper: Content {
        let document: File
    }
    
    struct FileTransfer: Content {
        let fileID: UUID
        let userID: UUID?
    }
    
    struct FileInfo: Content {
        let id: UUID
        let name: String
        let size: Int
    }
    
    struct FileList: Content {
        let files: [FileInfo]
    }
    
}
