//
//  FSItem.swift
//  cloud.osx
//
//  Created by Maxim on 4/3/19.
//  Copyright © 2019 mxCat. All rights reserved.
//

import Foundation

struct File: Codable {
    var filename: String
    var data: Data
}

struct FileWrapper: Codable {
    let document: File
}

struct FileTransfer: Codable {
    let fileID: UUID
    let userID: UUID
}

struct FileList: Codable {
    var files: [FileInfo]
}

struct FileInfo: Codable {
    let id: UUID
    let name: String
    let size: Int
}
