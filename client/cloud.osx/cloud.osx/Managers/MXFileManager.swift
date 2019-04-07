//
//  MXFileManager.swift
//  cloud.osx
//
//  Created by Maxim on 4/5/19.
//  Copyright © 2019 mxCat. All rights reserved.
//

import Foundation

struct MXFileManager {
    
    static let downloadsDirectory = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
    
    static func createFolderInDownloadDirectory(named name: String) -> URL? {
        do {
            let url = downloadsDirectory.appendingPathComponent(name)
            try FileManager.default.createDirectory(at: url,
                                                        withIntermediateDirectories: true,
                                                        attributes: nil)
            return url
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
    static func pickFilename(for url: URL) -> String {
        var path = url.path
        var i = 1
        while FileManager.default.fileExists(atPath: path) {
            let name = url
                .deletingPathExtension()
                .lastPathComponent + String(i)
            path = url
                .deletingLastPathComponent()
                .appendingPathComponent(name)
                .appendingPathExtension(url.pathExtension).path
            i += 1
        }
        return path
    }
    
}
