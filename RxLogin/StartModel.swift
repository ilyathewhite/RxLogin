//
//  StartModel.swift
//  RxLogin
//
//  Created by Ilya Belenkiy on 5/18/17.
//  Copyright © 2017 Ilya Belenkiy. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

/// The model for the start screen
class StartModel {
   /// The dispose bag for the model screen.
   let disposeBag = DisposeBag()

   /// The login token. `nil` if the login attempt was unsuccessful.
   var loginToken = Variable<String?>(nil)
   
   /// The screen title. At first, displays the title of the app.
   /// After the first login attempt, displays the login status.
   var title = Variable<String>("RxLogin Demo")

   /// Starts the login process by reseting the screen and subscribing
   /// to events from the login model to update the title and the login token.
   ///
   /// - Parameter loginModel: the login model.
   func startLogin(with loginModel: LoginModel) {
      title.value = (loginToken.value != nil) ? "Logged Out" : "Not Logged In"
      loginToken.value = nil
      
      loginModel.didFinishLogin
         .bind(
            onNext: { [weak self] token in
               guard let me = self else { return }
               me.loginToken.value = token
               me.title.value = "Logged in!"
         })
         // use the loginModel dispose bag to ensure that the subscription
         // goes away when the login screen is closed.
         .disposed(by: loginModel.disposeBag)
   }
}
