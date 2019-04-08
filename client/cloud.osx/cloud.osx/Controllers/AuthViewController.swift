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
    
    @IBOutlet weak var passwordConfirmWrapperLeadingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var additionalViewsWrapperHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var usernameTextField: NSTextField!
    @IBOutlet weak var passwordTextField: NSSecureTextField!
    @IBOutlet weak var passwordConfirmTextField: NSSecureTextField!
    @IBOutlet weak var identifierTextField: NSTextField!
    @IBOutlet weak var messageTextField: NSTextField!
    @IBOutlet weak var suggestionButton: NSButton!
    @IBOutlet weak var authButton: NSButton!
    @IBOutlet weak var passwordConfirmWrapper: NSView!
    @IBOutlet weak var identifierTextFieldWrapper: NSView!
    @IBOutlet weak var identifierLabel: NSTextField!
    
    
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
        
        usernameTextField.isEditable = true
        passwordTextField.isEditable = true
    
        passwordConfirmWrapperLeadingConstraint.constant = 0
        additionalViewsWrapperHeightConstraint.constant = 30
        identifierTextFieldWrapper.alphaValue = 1
        if self.state != .login {
            self.viewHeightConstraint.constant = 180
        }
        
        switch state {
        case .login:
            identifierTextFieldWrapper.alphaValue = 0
            additionalViewsWrapperHeightConstraint.constant = 0
            passwordConfirmWrapperLeadingConstraint.constant = 360
        case .logout:
            usernameTextField.isEditable = false
            passwordTextField.isEditable = false
            identifierTextField.stringValue = Cloud.authenticatedUser?.shared.id.uuidString ?? ""
            passwordConfirmWrapperLeadingConstraint.constant = -360
        case .report:
            usernameTextField.isEditable = false
            passwordTextField.isEditable = false
            messageTextField.isEditable = true
            messageTextField.placeholderString = "Enter your message"
            passwordConfirmWrapperLeadingConstraint.constant = -720
        default:
            break
        }
        
        NSAnimationContext.runAnimationGroup({context in
            context.duration = 0.4
            context.allowsImplicitAnimation = true

            self.view.layoutSubtreeIfNeeded()
            
        }, completionHandler: {
            if self.state == .login {
                self.viewHeightConstraint.constant = 150
            }
        })
        
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
            
            setupViewForAuth()
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
