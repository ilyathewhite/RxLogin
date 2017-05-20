//
//  LoginModel.swift
//  RxLogin
//
//  Created by Ilya Belenkiy on 5/16/17.
//  Copyright © 2017 Ilya Belenkiy. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

enum Result<T> {
   case success(T)
   case error(Error)
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

// The model for the login screen
class LoginModel {
   /// The dispose bag for the login screen
   public var disposeBag = DisposeBag()

   /// Whether the user can try to login with the information entered on the screen.
   public var isLoginEnabled: Driver<Bool>
   
   /// The signal that emits a result after every login attempt. If the login is successful,
   /// the result contains the login token. If not, it contains the login error.
   public var didLogin: Driver<Result<String>>
   
   /// The signal that emits a new login message after every login attempt.
   public var didLoginMessage: Driver<String>
   
   /// After the user logs in, emits the login token and then completes. If the user
   /// never logs in, this signal does not emit eny values.
   public var didFinishLogin: Driver<String>
   
   /// The signal that emits a new value every time login starts and ends.
   public var isLoginInProgress: Driver<Bool>
   
   /// The opposite of isLoginInProgress
   public var isLoginNotInProgress: Driver<Bool>
   
   /// Creates the login model from the username, password, and login action sources
   /// The sources are likely 2 text fields and a button, but they can be any observables (for testing)
   init(usernameSource: Observable<String?>,
        passwordSource: Observable<String?>,
        loginActionSource: Observable<Void>) {
      
      let username = usernameSource.map { $0 ?? "" }.distinctUntilChanged()
      let password = passwordSource.map { $0 ?? "" }.distinctUntilChanged()
      
      // isValidUsername and isValidPassword simply check the the user provided input
      // If this was a model to create an account, these derived signals would contain
      // the actual rules for username and password validateion.

      let isValidUsername = username
         .map { !$0.isEmpty }
         .asDriver(onErrorJustReturn: false)

      let isValidPassword = password
         .map { !$0.isEmpty }
         .asDriver(onErrorJustReturn: false)
      
      // emits a new username / password tupple whenever one of the sources has a new value
      let usernameAndPassword = Observable
         .combineLatest(username, password) { ($0, $1) }
      
      // emits the result of every attempt to log in. If successful, the result contains the
      // login token. If not, it contains the login error. Since the login response comes back
      // on a secondary thread, this signal cannot be used for model output directly. Since
      // the stream of new username / password values is infinite, this stream does not complete
      // after a sucsseful login.
      let rawDidLogin: Observable<Result<String>> = loginActionSource
         .withLatestFrom(usernameAndPassword)
         .flatMap { (username, password) in
            Observable.create { subscriber in
               loginFunc(username: username, password: password) { result in
                  subscriber.on(.next(result))
               }
               return Disposables.create()
            }
         }
         .startWith(.error(AuthenticationError.authentication))
      
      didLogin = rawDidLogin
         .asDriver(onErrorJustReturn: .error(AuthenticationError.service))
      
      didFinishLogin = rawDidLogin
         .single { result in // collapses didFinishLogin to a single value (the successful login result)
            if case .success = result {
               return true
            }
            else {
               return false
            }
         }
         .map { result in // transforms the successful result to the login token
            switch result {
            case .success(let token):
               return token
            default:
               return ""
            }
         }
         .take(1) // important to emit the .completed event
         .asDriver(onErrorJustReturn: "")
      
      isLoginInProgress = Driver
         .merge(
            loginActionSource.asDriver(onErrorJustReturn: ()).map { _ in true },
            didLogin.map { _ in false }
         )
         .startWith(false)
      
      isLoginNotInProgress = isLoginInProgress.map { !$0 }
      
      isLoginEnabled = Driver
         .combineLatest(isValidUsername, isValidPassword, isLoginInProgress, didLogin) {
            isValidUsername, isValidPassword, loggingIn, didLogin in
            if case .success = didLogin { return false }
            if loggingIn { return false }
            return isValidUsername && isValidPassword
      }
      
      // transforms the diLogin signal into the message for each login
      let didLoginResultMessage = didLogin
         .map({ (result) -> String in
            switch result {
            case .success:
               return "Succeeded!"
            case .error(let error):
               return (error as! AuthenticationError).description
            }
         })

      // emits a new login message whenever
      // - there is result from login
      // - the user starts log in
      // - the user changes the username or password
      let emptyLabelValue = " " // use " " instead of "" to avoid unwanted layout changes
      didLoginMessage = Driver
         .merge(
            didLoginResultMessage,
            loginActionSource.asDriver(onErrorJustReturn: ()).map { _ in emptyLabelValue },
            usernameAndPassword.asDriver(onErrorJustReturn: ("", "")).map { _ in emptyLabelValue }
         )
         .startWith(" ")
   }
}
