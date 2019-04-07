//
//  AuthViewController.swift
//  cloud.osx
//
//  Created by Maxim on 4/6/19.
//  Copyright © 2019 mxCat. All rights reserved.
//

import Cocoa

class AuthViewController: NSViewController {
    
    enum State: String {
        
        case register = "Register"
        case login = "Login"
        case logout = "Logout"
        case report = "Send"
        
        mutating func toggle() {
            switch self {
                
            case .login: self = .register
            case .register: self = .login
                
            case .logout: self = .report
            case .report: self = .logout
                
            }
        }
        
        var suggestion: String {
            switch self {
                
            case .login: return "Switch to register"
            case .register: return "Switch to login"
                
            case .logout: return "Contact us"
            case .report: return "Back to account"
            
            }
        }
        
    }
    
    var state: State = .register
    
    @IBOutlet weak var viewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var usernameTextField: NSTextField!
    @IBOutlet weak var passwordTextField: NSSecureTextField!
    @IBOutlet weak var passwordConfirmTextField: NSSecureTextField!
    @IBOutlet weak var suggestionButton: NSButton!
    @IBOutlet weak var authButton: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let user = Cloud.authenticatedUser {
            usernameTextField.stringValue = user.shared.username
            passwordTextField.stringValue = user.password
            state = .logout
            setupViewForAuth()
        }
        
    }
    
    @IBAction func authSwitch(_ sender: Any) {
        
        state.toggle()
        setupViewForAuth()
        
    }
    
    func setupViewForAuth() {
        authButton.title = state.rawValue
        suggestionButton.title = state.suggestion
        passwordConfirmTextField.isHidden = state != .register
        viewHeightConstraint.constant = state != .register ? 150 : 180
    }
    
    @IBAction func auth(_ sender: Any) {
        if validateUserInput() { handleAuth() }
    }
    
    @IBAction func handleAuthTextFieldAction(_ sender: NSTextField) {
        switch sender {
            
        case usernameTextField:
            if validateUserInput() { passwordTextField.becomeFirstResponder() }
            
        case passwordTextField:
            if validateUserInput() {
                if state == .login { handleAuth() }
                else { passwordConfirmTextField.becomeFirstResponder() }
            }
            
        case passwordConfirmTextField:
            if validateUserInput() { handleAuth() }
            
        default:
            break
        }
        
    }
    
    func handleAuth() {
        switch state {
            
        case .register:
            
            Cloud.register(username: usernameTextField.stringValue, password: passwordTextField.stringValue) { (user, error) in
                if error == nil {
                    UserDefaults.standard.set(user!.id.uuidString, forKey: "userid")
                    UserDefaults.standard.set(user!.username, forKey: "username")
                    UserDefaults.standard.set(self.passwordTextField.stringValue, forKey: "password")
                    self.state = .logout
                    self.setupViewForAuth()
                    
                    NotificationCenter.default.post(Notification(name: Notification.Name("UserDidAuthenticated")))
                } else {
                    print(error!)
                }
                
            }
        case .login:
            
            Cloud.login(username: usernameTextField.stringValue, password: passwordTextField.stringValue) { (user, error) in
                if error == nil {
                    UserDefaults.standard.set(user!.id.uuidString, forKey: "userid")
                    UserDefaults.standard.set(user!.username, forKey: "username")
                    UserDefaults.standard.set(self.passwordTextField.stringValue, forKey: "password")
                    self.state = .logout
                    self.setupViewForAuth()
                    
                    NotificationCenter.default.post(Notification(name: Notification.Name("UserDidAuthenticated")))
                } else {
                    print(error!)
                }
                
            }
        case .logout:
            
            UserDefaults.standard.removeObject(forKey: "userid")
            UserDefaults.standard.removeObject(forKey: "username")
            UserDefaults.standard.removeObject(forKey: "password")
            Cloud.logout()
            state = .login
            setupViewForAuth()
            
            NotificationCenter.default.post(Notification(name: Notification.Name("UserDidDeauthenticated")))
        case .report:
            print(state.rawValue)
            Cloud.post(message: "Report")
            state = .logout
        }
        
    }
    
    func validateUserInput() -> Bool {
        if usernameTextField.stringValue.count < 3 {
            usernameTextField.becomeFirstResponder()
            return false
        }
        if passwordTextField.stringValue.count < 3 {
            passwordTextField.becomeFirstResponder()
            return false
        }
        if state == .register {
            if passwordConfirmTextField.stringValue.count < 3 || passwordConfirmTextField.stringValue != passwordTextField.stringValue {
                passwordConfirmTextField.becomeFirstResponder()
                return false
            }
        }
        return true
    }
    
}
