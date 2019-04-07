//
//  User.swift
//  cloud.osx
//
//  Created by Maxim on 4/7/19.
//  Copyright © 2019 mxCat. All rights reserved.
//

import Foundation

struct User: Codable {
    
    struct Shared: Codable {
        var id: UUID
        var username: String
    }
    
    var shared: Shared
    var password: String
    
}
