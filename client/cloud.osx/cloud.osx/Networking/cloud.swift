//
//  cloud.swift
//  cloud.osx
//
//  Created by Maxim on 4/4/19.
//  Copyright © 2019 mxCat. All rights reserved.
//

import Foundation
import Alamofire

// MARK: - Init
struct Cloud {
    
    static let baseUrl = "http://localhost:8080"
    static let baseDir = "cloud.Downloads"
    
    static var authenticatedUser: User?
    
    struct errorResponse: Codable {
        let error: Bool
        let reason: String
    }
    
    struct Headers {
        static func basicAuth(username: String, password: String) -> HTTPHeader {
            guard let basicCredential =
                getBasicAuthCredential(
                    username: username,
                    password: password)
                else { return HTTPHeader(name: "Authorization", value: "Basic") }
            return HTTPHeader(name: "Authorization", value: "Basic \(basicCredential)")
        }
        static func basicAuth(for user: User?) -> HTTPHeader {
            guard let basicCredential =
                getBasicAuthCredential(
                    username: user?.shared.username ?? "",
                    password: user?.password ?? "")
                else { return HTTPHeader(name: "Authorization", value: "Basic") }
            return HTTPHeader(name: "Authorization", value: "Basic \(basicCredential)")
        }
        
        static var mulipartFormData: HTTPHeader {
            return HTTPHeader(name: "Content-Type", value: "multipart/form-data; charset=utf-8; boundary=__mx-Cat.cloud.__")
        }
        
        static var jsonFormData: HTTPHeader {
            return HTTPHeader(name: "Content-Type", value: "application/json; charset=utf-8")
        }
    }
    
    static func getBasicAuthCredential(username: String, password: String) -> String? {
        
        let credentialData = "\(username):\(password)".data(using: .utf8)
        return credentialData?.base64EncodedString(options: Data.Base64EncodingOptions.init(rawValue: 0))
        
    }
    
    static func handleAutorizationError(data: Data) -> String? {
        return try? JSONDecoder().decode(errorResponse.self, from: data).reason
    }
    
    static func post(message: String) {
        print("Message: \(message)")
    }
    
}

// MARK: - Authentication
extension Cloud {
    static func register(username: String, password: String, completion: ((User.Shared?, String?) -> Void)?) {
        let body: [String : Any] = [
            "username": username,
            "password": password
        ]
        AF.request("\(baseUrl)/auth/register",
            method: .post,
            parameters: body,
            encoding: JSONEncoding.default,
            headers: [Headers.jsonFormData]
        ).responseJSON { response in
            handleAuthResponse(password, response, completion)
        }
    }
    
    static func login(username: String, password: String, completion: ((User.Shared?, String?) -> Void)?) {
        AF.request("\(baseUrl)/auth/login",
            method: .post,
            headers: [Headers.basicAuth(username: username, password: password), Headers.jsonFormData]
        ).responseJSON { response in
            handleAuthResponse(password, response, completion)
        }
    }
    
    static func logout() {
        authenticatedUser = nil
    }
    
    private static func handleAuthResponse(_ password: String, _ response: DataResponse<Any>, _ completion: ((User.Shared?, String?) -> Void)?) {
        guard let data = response.data else { return }
        if let error = handleAutorizationError(data: data) {
            completion?(nil, error)
            return
        }
        do {
            let decoder = JSONDecoder()
            let userShared = try decoder.decode(User.Shared.self, from: data)
            authenticatedUser = User(shared: userShared, password: password)
            completion?(userShared, nil)
        } catch {
            completion?(nil, error.localizedDescription)
        }
    }
    
    static func login() {
        guard
        let userId = UserDefaults.standard.string(forKey: "userid"),
        let username = UserDefaults.standard.string(forKey: "username"),
        let password = UserDefaults.standard.string(forKey: "password")
        else { return }
        
        authenticatedUser = User(shared: User.Shared(id: UUID(uuidString: userId)!, username: username), password: password)
    }
    
    static func deleteAccount() {
        print("Account deletion")
    }
}

// MARK: - FileManaging
extension Cloud {
    static func upload(fileAt path: String, completion: ((DataResponse<Any>) -> Void)?) {
        
        guard let data = FileManager.default.contents(atPath: path) else { return }
        
        let headers = HTTPHeaders([Headers.basicAuth(for: authenticatedUser), Headers.mulipartFormData])
        
        AF.upload(multipartFormData: { (multipartFormData) in
            multipartFormData.append(data, withName: "document", fileName: (path as NSString).lastPathComponent)
        },
                  usingThreshold: UInt64.init(),
                  to: "\(baseUrl)/upload",
            method: .post, headers: headers
            ).responseJSON(completionHandler: { (response) in
                if completion != nil { completion!(response) }
            })
        
    }
    
    static func download(file: FileInfo, to path: String = "", completion: ((DataResponse<Any>) -> Void)?) {
        
        var url = URL(string: path)
        
        if url == nil {
            url = MXFileManager.createFolderInDownloadDirectory(named: baseDir)
            guard url != nil else { return }
        }
        
        let headers = HTTPHeaders([Headers.basicAuth(for: authenticatedUser), Headers.jsonFormData])
        
        let body: [String : Any] = [
            "fileID": file.id.uuidString
        ]
        
        AF.request("\(baseUrl)/download",
            method: .post,
            parameters: body,
            encoding: JSONEncoding.default,
            headers: headers
        ).responseJSON { (response) in
            if let data = response.data {
                // Response validation
                if let statusCode = response.response?.statusCode {
                    if !(200..<300).contains(statusCode) {
                        print("Server responded with an error code: \(statusCode)")
                        print("Response data:\"\(String(data: response.data!, encoding: .utf8) ?? "#no_response_data")\"")
                        return
                    }
                }
                
                do {
                    let data = try JSONDecoder().decode(FileWrapper.self, from: data).document.data
                    guard let url = url?.appendingPathComponent(file.name) else { return }
                    FileManager.default.createFile(atPath: MXFileManager.pickFilename(for: url), contents: data, attributes: nil)
                        
                } catch {
                    print(error)
                }
                    
                completion?(response)
            }
        }
    }
    
    static func delete(file: FileInfo, completion: ((String?) -> Void)?) {
        let headers = HTTPHeaders([Headers.basicAuth(for: authenticatedUser), Headers.jsonFormData])
        let body: [String : Any] = [
            "fileID": file.id.uuidString
        ]
        AF.request("\(baseUrl)/delete",
            method: .delete,
            parameters: body,
            encoding: JSONEncoding.default,
            headers: headers
        ).responseJSON { response in
            if let data = response.data {
                if let error = handleAutorizationError(data: data) {
                    completion?(error)
                    return
                }
            }
            completion?(nil)
        }

    }
    
    static func duplicate() {
        print("Duplication")
    }
    
    static func send(using transfer: FileTransfer, completion: ((String?) -> Void)?) {
        print("Send")
        let headers = HTTPHeaders([Headers.basicAuth(for: authenticatedUser), Headers.jsonFormData])
        let body: [String: Any] = [
            "fileID" : transfer.fileID.uuidString,
            "userID" : transfer.userID.uuidString
        ]
        AF.request("\(baseUrl)/send",
            method: .post,
            parameters: body,
            encoding: JSONEncoding.default,
            headers: headers
        ).responseJSON { response in
            guard let data = response.data else { return }
            if let error = handleAutorizationError(data: data){
                completion?(error)
                return
            }
            completion?(nil)
        }
    }
    
    static func move() {
        print("Moving")
    }
    
    static func list(completion: @escaping (FileList?, String?) -> Void) {
        
        AF.request("\(baseUrl)/list",
            method: .get,
            headers: [Headers.basicAuth(for: authenticatedUser), Headers.jsonFormData]
        ).responseJSON { (response) in
            guard let data = response.data else { return }
            if let error = handleAutorizationError(data: data){
                completion(nil, error)
                return
            }
            do {
                let decoder = JSONDecoder()
                completion(try decoder.decode(FileList.self, from: data), nil)
            } catch {
                completion(nil, error.localizedDescription)
            }
        }
        
    }
    
}
