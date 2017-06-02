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

typealias LoginFuncType = (_ username: String, _ password: String, _ completion: @escaping (Result<String>) -> ()) -> ()

/// Simulated login. Returns on a secondary thread to to demonstrate how this still works with UI.
private func simulatedLoginFunc(username: String, password: String, completion: @escaping (Result<String>) -> ()) {
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
   
   /// Whether the user can try to login with the information entered on the screen,
   /// also emits false if the user is logged in
   public var isLoginEnabled: Driver<Bool>
   
   /// The signal that emits a result after every login attempt. If the login is successful,
   /// the result contains the login token. If not, it contains the login error.
   public var didLoginResult: Driver<Result<String>>
   
   /// The signal that emits a new login message after every login attempt.
   public var didLoginMessage: Driver<String>
   
   /// After the user logs in, emits the login token and then completes. If the user
   /// never logs in, this signal does not emit eny values.
   public var didFinishLogin: Observable<String>
   
   /// The signal that emits a new value every time login starts and ends.
   public var isLoginInProgress: Driver<Bool>
   
   /// Whether to enable the UI to allow the user to try to login.
   public var isNotLoginInProgressOrDone: Driver<Bool>
   
   /// A login function that takes the username and password, tries to login, and runs the completion with the result.
   /// This could be a function that created an observable, but the API is aimed at show what happens when
   /// the callback is run on a secondary thread.
   public var loginFunc: LoginFuncType
   
   /// Creates the login model from the username, password, and login action sources
   /// The sources are likely 2 text fields and a button, but they can be any observables (for testing)
   init(usernameSource: Observable<String?>,
        passwordSource: Observable<String?>,
        loginActionSource: Observable<Void>,
        loginFunc: @escaping LoginFuncType = simulatedLoginFunc
      ) {
      
      self.loginFunc = loginFunc
      
      let username = usernameSource
         .map { $0 ?? "" }
         .distinctUntilChanged()
         .startWith("")
         .asDriver(onErrorJustReturn: "")
      
      let password = passwordSource
         .map { $0 ?? "" }
         .distinctUntilChanged()
         .startWith("")
         .asDriver(onErrorJustReturn: "")
      
      let loginAction = loginActionSource
         .asDriver(onErrorJustReturn: ())
      
      // isValidUsername and isValidPassword simply check the the user provided input
      // If this was a model to create an account, these derived signals would contain
      // the actual rules for username and password validateion.
      
      func isValidUsernameFunc(_ username: String) -> Bool { return !username.isEmpty }
      func isValidPasswordFunc(_ password: String) -> Bool { return !password.isEmpty }
      
      let isValidUsername = username
         .map(isValidUsernameFunc)
      
      let isValidPassword = password
         .map(isValidPasswordFunc)
      
      // emits a new username / password tupple whenever one of the sources has a new value
      let validatedUsernameAndPassword = Driver
         .combineLatest(
            username.filter(isValidUsernameFunc),
            password.filter(isValidPasswordFunc)
         ) { ($0, $1) }
      
      // emits the result of every attempt to log in. If successful, the result contains the
      // login token. If not, it contains the login error. Since the login response comes back
      // on a secondary thread, this signal cannot be used for model output directly. Since
      // the stream of new username / password values is infinite, this stream does not complete
      // after a sucsseful login.
      didLoginResult = loginActionSource
         .withLatestFrom(validatedUsernameAndPassword)
         .flatMap { (username, password) in
            Observable.create { subscriber in
               loginFunc(username, password) { result in
                  subscriber.on(.next(result))
               }
               return Disposables.create()
            }
         }
         .asDriver(onErrorJustReturn: .error(AuthenticationError.service))
            
      didFinishLogin = didLoginResult.asObservable()
         .takeFirst { $0.isSuccess }
         .map { $0.wrapped(or: "") }
      
      isLoginInProgress = Driver
         .merge(
            loginAction.map { _ in true },
            didLoginResult.map { _ in false }
         )
         .startWith(false)
      
      let isLoginInProgressOrDone = Driver
         .merge(
            loginAction.map { _ in true },
            didLoginResult.map { $0.isSuccess }
         )
         .startWith(false)
      
      isNotLoginInProgressOrDone = isLoginInProgressOrDone.map(!)
      
      isLoginEnabled = Driver
         .combineLatest(isValidUsername, isValidPassword, isLoginInProgressOrDone) {
            isValidUsername, isValidPassword, isLogingInOrDone -> Bool in
            if isLogingInOrDone { return false }
            return isValidUsername && isValidPassword
      }
      
      // transforms the didLogin signal into the message for each login
      let didLoginResultMessage = didLoginResult
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
            loginAction.map { _ in emptyLabelValue },
            username.map { _ in emptyLabelValue },
            password.map { _ in emptyLabelValue }
         )
         .distinctUntilChanged()
   }
}
