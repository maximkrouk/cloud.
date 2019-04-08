//
//  FSController.swift
//  App
//
//  Created by Maxim on 3/31/19.
//

import Foundation
import Vapor

final class FSController {
    
    func sendUploadHtmlForm(on req: Request) throws -> Future<View> {
        guard let html = try? req.view().render("upload") else {
            throw Abort(.badRequest, reason: "Could not render upload page" , identifier: nil)
        }
        return html
    }
    
    func upload(on req: Request, _ upload: FSItem.FileWrapper) throws -> Future<FSItem.FileInfo> {
        let user = try req.requireAuthenticated(User.self)
        
        let item = FSItem(file: upload.document, userID: user.id!)
        
        
        return item.save(on: req).map(to: FSItem.FileInfo.self, { item in
            print("File \"\(item.file.filename)\" of size: (\(item.file.data.count) bytes), received from user with id: \(item.userID)")
            return FSItem.FileInfo(id: item.id!, name: item.file.filename, size: item.file.data.count)
        })
    }
    
    func download(on req: Request) throws -> Future<FSItem.FileWrapper> {
        let user = try req.requireAuthenticated(User.self)
        
        return try req.content.decode(FSItem.FileTransfer.self).flatMap(to: FSItem.FileWrapper.self, { transfer in
            return try user.files.query(on: req).all().map(to: FSItem.FileWrapper.self, { items in
                guard let item = items.filter({ $0.id == transfer.fileID }).first else { throw Abort(.notFound, reason: "Requested file does not exist") }
                print("File \"\(item.file.filename)\" of size: (\(item.file.data.count) bytes), sent to user with id: \(item.userID)")
                return FSItem.FileWrapper(document: item.file)
            })
        })
    }
    
    func delete(on req: Request) throws -> Future<HTTPResponseStatus> {
        let user = try req.requireAuthenticated(User.self)
        return try req.content.decode(FSItem.FileTransfer.self).flatMap(to: HTTPResponseStatus.self, { transfer in
            return try user.files.query(on: req).all().flatMap(to: HTTPResponseStatus.self, { items in
                guard let item = items.filter({ $0.id == transfer.fileID }).first else { throw Abort(.notFound, reason: "Requested file does not exist") }
                print("File \"\(item.file.filename)\" of size: (\(item.file.data.count) bytes) and user with id: \(item.userID) deleted")
                return item.delete(on: req).transform(to: HTTPResponseStatus.ok)
            })
        })
    }
    
    func duplicate(on req: Request) throws -> Future<HTTPResponseStatus> {
        let user = try req.requireAuthenticated(User.self)
        
        return try req.content.decode(FSItem.FileTransfer.self).flatMap(to: HTTPResponseStatus.self, { transfer in
            return try user.files.query(on: req).all().flatMap(to: HTTPResponseStatus.self, { items in
                guard let item = items.filter({ $0.id == transfer.fileID }).first else { throw Abort(.notFound, reason: "Requested file does not exist") }
                
                
                print("File \"\(item.file.filename)\" of size: (\(item.file.data.count) bytes) and user with id: \(item.userID) copied")
                return FSItem(file: item.file, userID: item.userID).save(on: req).transform(to: HTTPResponseStatus.ok)
            })
        })
    }
    
    func send(on req: Request) throws -> Future<HTTPResponseStatus> {
        let user = try req.requireAuthenticated(User.self)
        
        return try req.content.decode(FSItem.FileTransfer.self).flatMap(to: HTTPResponseStatus.self, { transfer in
            guard transfer.userID != nil else { throw Abort(.badRequest, reason: "Destination user not specified") }
            return try user.files.query(on: req).all().flatMap(to: HTTPResponseStatus.self, { items in
                guard let item = items .filter({ $0.id == transfer.fileID}).first else { throw Abort(.notFound, reason: "Requested file does not exist") }
                return User.find(transfer.userID!, on: req).unwrap(or: Abort(.notFound, reason: "Destination user does not exist")).flatMap(to: HTTPResponseStatus.self, { destinationUser in
                    let file = FSItem(file: item.file, userID: destinationUser.id!)
                    
                    print("File \"\(item.file.filename)\" of size: (\(item.file.data.count) bytes) and user with id: \(item.userID) sended to user with id: \(destinationUser.id!)")
                    return file.save(on: req).transform(to: HTTPResponseStatus.ok)
                })
            })
        })
    }
    
    func list(on req: Request) throws -> Future<FSItem.FileList> {
        let user = try req.requireAuthenticated(User.self)
        
        return try user.files.query(on: req).all().map { files in
            print("Sending filelist to user with id: \(user.id!)")
            return FSItem.FileList(files: files.map { FSItem.FileInfo(id: $0.id!, name: $0.file.filename, size: $0.file.data.count) })
        }
    }
    
}
