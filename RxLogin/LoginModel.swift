//
//  LoginModel.swift
//  RxLogin
//
//  Created by Ilya Belenkiy on 5/16/17.
//  Copyright © 2017 Ilya Belenkiy. All rights reserved.
//

import Foundation

enum Result<T> {
   case success(T)
   case error(Error)
   
   var isSuccess: Bool {
      switch self {
      case .success: return true
      case .error: return false
      }
   }
}

extension Result where T: Equatable {
   static func ==(lhs: Result<T>, rhs: Result<T>) -> Bool {
      switch (lhs, rhs) {
      case let (.success(val1), .success(val2)):
         return val1 == val2
      case let (.error(err1), .error(err2)):
         return err1.localizedDescription == err2.localizedDescription
      default:
         return false
      }
   }
   
   static func !=(lhs: Result<T>, hrs: Result<T>) -> Bool {
      return !(lhs == hrs)
   }
}

enum AuthenticationError: Error {
   case service
   case authentication
   
   var description: String {
      switch self {
      case .service:
         return "Service error. Please try again later."
      case .authentication:
         return "Invalid username / password"
      }
   }
}

/// Simulated login. Returns on a secondary thread to to demonstrate how this still works with UI.
private func loginFunc(username: String, password: String, completion: @escaping (Result<String>) -> ()) {
   DispatchQueue.global().asyncAfter(wallDeadline: .now() + 2.0) {
      guard username == "ilya", password == "abc" else {
         return completion(.error(AuthenticationError.authentication))
      }
      
      completion(.success("ilya's token"))
   }
}

protocol LoginModelDelegate: class {
   func didChangeLoginEnabled(model: LoginModel)
   func didChangeLoginMessage(model: LoginModel)
   func didChangeLoginInProgress(model: LoginModel)
   func didChangeLoginResult(model: LoginModel)
}

class LoginModel {
   init() {
      updateLatestState()
   }
   
   weak var delegate: LoginModelDelegate?

   private(set) var latestLoginEnabled = true {
      didSet {
         guard latestLoginEnabled != oldValue else { return }
         delegate?.didChangeLoginEnabled(model: self)
      }
   }
   
   private(set) var latestLoginMessage = " " {
      didSet {
         guard latestLoginMessage != oldValue else { return }
         delegate?.didChangeLoginMessage(model: self)
      }
   }
   
   private(set) var latestLoginInProgress = false {
      didSet {
         guard latestLoginInProgress != oldValue else { return }
         delegate?.didChangeLoginInProgress(model: self)
      }
   }
   
   private(set) var latestLoginResult: Result<String> = .error(AuthenticationError.authentication) {
      didSet {
         guard latestLoginResult != oldValue else { return }
         delegate?.didChangeLoginResult(model: self)
      }
   }
   
   private func updateLatestState() {
      latestLoginEnabled = loginEnabled
      latestLoginMessage = loginMessage
      latestLoginInProgress = loginInProgress
      latestLoginResult = loginResult
   }
   
   private var didChangeUsernameOrPassword = false
   
   var username = "" {
      didSet {
         guard username != oldValue else { return }
         didChangeUsernameOrPassword = true
         updateLatestState()
      }
   }
   
   var password = "" {
      didSet {
         guard password != oldValue else { return }
         didChangeUsernameOrPassword = true
         updateLatestState()
      }
   }
   
   private(set) var loginInProgress = false {
      didSet {
         guard loginInProgress != oldValue else { return }
         updateLatestState()
      }
   }
   
   private(set) var loginResult: Result<String> = .error(AuthenticationError.authentication) {
      didSet {
         // always a new value from the service, no guard needed
         // resets the start point for form user input because the user could try a different
         // username and password after this point
         didChangeUsernameOrPassword = false
         updateLatestState()
      }
   }
   
   var loginToken: String {
      switch loginResult {
      case .success(let token):
         return token
      case .error:
         return ""
      }
   }
   
   func startLogin() {
      loginInProgress = true
      loginFunc(username: username, password: password) { result in
         DispatchQueue.main.async { [weak self] in
            guard let me = self else { return }
            me.loginInProgress = false
            me.loginResult = result
         }
      }
   }
   
   private var loginEnabled: Bool {
      return !username.isEmpty && !password.isEmpty && !loginInProgress && !loginResult.isSuccess
   }
   
   private var loginMessage: String {
      if username.isEmpty || password.isEmpty || loginInProgress || didChangeUsernameOrPassword {
         return " "
      }
      
      switch loginResult {
      case .success:
         return "Succeeded!"
      case .error:
         return "Invalid username / password"
      }
   }
}
