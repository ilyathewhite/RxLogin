//
//  LoginViewController.swift
//  RxLogin
//
//  Created by Ilya Belenkiy on 5/16/17.
//  Copyright © 2017 Ilya Belenkiy. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class LoginViewController: UIViewController {
   var loginModel: LoginModel!
   
   @IBOutlet var usernameField: UITextField!
   @IBOutlet var passwordField: UITextField!
   @IBOutlet var loginButton: UIButton!
   @IBOutlet var closeButton: UIButton!
   @IBOutlet var didLoginMessageField: UILabel!
   @IBOutlet var spinner: UIActivityIndicatorView!
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      loginModel = LoginModel(
         usernameSource: usernameField.rx.text.asObservable(),
         passwordSource: passwordField.rx.text.asObservable(),
         loginActionSource: loginButton.rx.tap.asObservable()
      )
      
      let disposeBag = loginModel.disposeBag
      
      // loginButton.isEnabled
      loginModel.isLoginEnabled
         .drive(loginButton.rx.isEnabled)
         .disposed(by: disposeBag)

      // didLoginMessageField.text
      loginModel.didLoginMessage
         .drive(didLoginMessageField.rx.text)
         .disposed(by: disposeBag)

      // spinner.isAnimating
      loginModel.isLoginInProgress
         .drive(spinner.rx.isAnimating)
         .disposed(by: disposeBag)
      
      // usernameField.isEnabled
      loginModel.isLoginNotInProgress
         .drive(usernameField.rx.isEnabled)
         .disposed(by: disposeBag)

      // passwordField.isEnabled
      loginModel.isLoginNotInProgress
         .drive(passwordField.rx.isEnabled)
         .disposed(by: disposeBag)

      // tap action, bind is enough because tap is a ControlEvent
      closeButton.rx.tap
         .bind(
            onNext: { [unowned self] in
               self.dismiss(animated: true, completion: nil)
         })
         .disposed(by: disposeBag)
   }
}
