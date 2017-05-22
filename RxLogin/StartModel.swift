//
//  StartModel.swift
//  RxLogin
//
//  Created by Ilya Belenkiy on 5/18/17.
//  Copyright © 2017 Ilya Belenkiy. All rights reserved.
//

import Foundation

protocol StartModelDelegate: class {
   func didLogin(model: StartModel)
   func didReset(model: StartModel)
}

class StartModel {
   weak var delegate: StartModelDelegate?
   var loginToken: String?
   var title = "NoRx Login Demo"
   
   func didLogin(with token: String) {
      loginToken = token
      title = "Logged In!"
      delegate?.didLogin(model: self)
   }
   
   func reset() {
      loginToken = nil
      title = "Not Logged In!"
      delegate?.didReset(model: self)
   }
}
