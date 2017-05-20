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

class StartViewController: UIViewController {
   private var startModel: StartModel!

   @IBOutlet var titleLabel: UILabel!
   @IBOutlet var startButton: UIButton!
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      startModel = StartModel()
      
      // titleLabel.text
      startModel.title.asDriver()
         .drive(titleLabel.rx.text)
         .disposed(by: startModel.disposeBag)

      // tap action
      startButton.rx.tap.asDriver()
         .drive(
            onNext: { [unowned self] _ in
               let loginVC = LoginViewController()
               loginVC.loadViewIfNeeded() // to load the login model
               let loginModel = loginVC.loginModel!
               
               self.startModel.startLogin(with: loginModel)
               self.present(loginVC, animated: true, completion: nil)
               
               // dismiss the login screen shortly after the user logs in
               loginModel.didFinishLogin.asObservable()
                  .delay(1.0, scheduler: MainScheduler.instance)
                  .subscribe(
                     onCompleted: { [unowned self] _ in
                        self.dismiss(animated: true, completion: nil)
                  })
                  .disposed(by: loginModel.disposeBag)
            }
         )
         .disposed(by: startModel.disposeBag)
   }
}
