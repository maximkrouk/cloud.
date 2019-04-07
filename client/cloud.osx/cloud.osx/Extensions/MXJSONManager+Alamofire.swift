//
//  MXJSONManager+Alamofire.swift
//  cloud.osx
//
//  Created by Maxim on 4/4/19.
//  Copyright © 2019 mxCat. All rights reserved.
//

import Foundation
import Alamofire


// Alamofire
extension MXJSONManager {
    struct Alamofire {
        static func loadData<T: Decodable>(ofType type: T.Type, from url: URL, using headers: HTTPHeaders?, completion: @escaping (T) -> Void) {
                AF.request(url, method: .get, headers: headers).responseJSON { (response) in
                    guard let data = response.data else { return }
                    do {
                        let decoder = JSONDecoder()
                        completion(try decoder.decode(T.self, from: data))
                    } catch {
                        print(error)
                    }
                }
        }
    }
}
