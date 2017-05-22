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

protocol LoginViewControllerDelegate: class {
   func didLogin(controller: LoginViewController, loginToken: String)
   func close(controller: LoginViewController)
}

class LoginViewController: UIViewController, LoginModelDelegate {
   var loginModel = LoginModel()
   weak var delegate: LoginViewControllerDelegate?
   
   @IBOutlet var usernameField: UITextField!
   @IBOutlet var passwordField: UITextField!
   @IBOutlet var loginButton: UIButton!
   @IBOutlet var closeButton: UIButton!
   @IBOutlet var didLoginMessageField: UILabel!
   @IBOutlet var spinner: UIActivityIndicatorView!
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      loginModel.delegate = self

      didChangeLoginEnabled(model: loginModel)
      didChangeLoginMessage(model: loginModel)
      didChangeLoginInProgress(model: loginModel)
      didChangeLoginResult(model: loginModel)
   }
   
   // from model to view
   
   func didChangeLoginEnabled(model: LoginModel) {
      loginButton.isEnabled = model.latestLoginEnabled
   }
   
   func didChangeLoginMessage(model: LoginModel) {
      didLoginMessageField.text = model.latestLoginMessage
   }
   
   func didChangeLoginInProgress(model: LoginModel) {
      usernameField.isEnabled = !model.loginInProgress
      passwordField.isEnabled = !model.loginInProgress
      
      if model.loginInProgress {
         spinner.startAnimating()
      }
      else {
         spinner.stopAnimating()
      }
   }
   
   func didChangeLoginResult(model: LoginModel) {
      if loginModel.loginResult.isSuccess {
         usernameField.isEnabled = false
         passwordField.isEnabled = false
         loginButton.isEnabled = false
         
         delegate?.didLogin(controller: self, loginToken: loginModel.loginToken)
      }
   }
   
   // from view to model
   
   @IBAction func updateUsername(sender: UITextField) {
      loginModel.username = sender.text ?? ""
   }
   
   @IBAction func updatePassword(sender: UITextField) {
      loginModel.password = sender.text ?? ""
   }
   
   @IBAction func startLogin(sender: UIButton) {
      loginModel.startLogin()
   }
   
   @IBAction func close(sender: UIButton) {
      delegate?.close(controller: self)
   }
}
