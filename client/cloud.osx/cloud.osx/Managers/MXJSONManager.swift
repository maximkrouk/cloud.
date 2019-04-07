//
//  JSONManager.swift
//  mxWeather
//
//  Created by Maxim on 3/6/19.
//  Copyright © 2019 id.mxCat. All rights reserved.
//

import Foundation

struct MXJSONManager {
    
    static func loadData<T: Decodable>(ofType type: T.Type, from url: URL, completion: @escaping (T) -> Void) {
        DispatchQueue.global(qos: .background).async {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                completion(try decoder.decode(type, from: data))
            } catch {
                print("error:\(error)")
            }
        }
    }
    
    static func loadData<T: Decodable>(ofType type: T.Type, with req: URLRequest, completion: @escaping (T) -> Void) {
        URLSession.shared.dataTask(with: req) { data, response, error in
            do {
                if let error = error {
                    print(error)
                }
                if let data = data {
                    let decoder = JSONDecoder()
                    completion(try decoder.decode(type, from: data))
                }
            } catch {
                print("error:\(error)")
            }
        }.resume()
    }
    
}

