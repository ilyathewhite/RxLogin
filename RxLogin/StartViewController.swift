//
//  StartViewController.swift
//  RxLogin
//
//  Created by Ilya Belenkiy on 5/17/17.
//  Copyright © 2017 Ilya Belenkiy. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class StartViewController: UIViewController, StartModelDelegate, LoginViewControllerDelegate {
   private var startModel = StartModel()

   @IBOutlet var titleLabel: UILabel!
   @IBOutlet var startButton: UIButton!
   
   override func viewDidLoad() {
      super.viewDidLoad()
      startModel.delegate = self
   }
   
   // from model to view

   func didLogin(model: StartModel) {
      titleLabel.text = model.title
   }
   
   func didReset(model: StartModel) {
      titleLabel.text = model.title
   }
   
   // from view to model
   
   @IBAction func startLogin(sender: UIButton) {
      startModel.reset()
      let loginVC = LoginViewController()
      loginVC.delegate = self
      present(loginVC, animated: true, completion: nil)
   }
   
   // LoginViewControllerDelegate
   
   func didLogin(controller: LoginViewController, loginToken: String) {
      startModel.didLogin(with: loginToken)
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
         self.close(controller: controller)
      }
   }
   
   func close(controller: LoginViewController) {
      controller.dismiss(animated: true, completion: nil)
   }
}
