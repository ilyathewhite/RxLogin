//
//  Utilities.swift
//  GooglePlaces
//
//  Created by Ilya Belenkiy on 5/16/17.
//  Copyright © 2017 Ilya Belenkiy. All rights reserved.
//

import Foundation
import RxSwift

enum GeneralError: Error {
   case noData(url: URL)
   case invalidData
}

enum Result<T> {
   case success(T)
   case error(Error)
}

extension Result {
   func wrapped(or defaultValue: T) -> T {
      switch self {
      case .success(let value):
         return value
      case .error:
         return defaultValue
      }
   }
   
   var isSuccess: Bool {
      switch self {
      case .success:
         return true
      case .error:
         return false
      }
   }
}

extension ObservableType {
   /// Take the first value satisfying `predicate` and then complete.
   public func takeFirst(where predicate: @escaping (E) -> Bool) -> Observable<E> {
      return filter(predicate).take(1)
   }
}

