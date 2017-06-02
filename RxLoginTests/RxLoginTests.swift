//
//  RxLoginTests.swift
//  RxLoginTests
//
//  Created by Ilya Belenkiy on 5/30/17.
//  Copyright © 2017 Ilya Belenkiy. All rights reserved.
//

import XCTest
import RxSwift
import RxTest
@testable import RxLogin

/*
 make a single timeline with events as enum
 then filter events for each sequence
 add markers for events to be able to extract times for important events
extract the special times when testing instead of relying on magic constants
 */

/*
 maybe reqcord the timeline from running the actual app / UITest ?
 */

class RxLoginTests: XCTestCase {
   enum Event {
      case username(String?)
      case password(String?)
      case loginAction
   }
   
   var scheduler: TestScheduler!
   
   override func setUp() {
      scheduler = TestScheduler(initialClock: 0)
   }
   
   func testLoginFunc(username: String, password: String, completion: @escaping (Result<String>) -> ()) {
      scheduler.scheduleAt(scheduler.clock + 1) {
         guard username == "ilya", password == "abc" else {
            return completion(.error(AuthenticationError.authentication))
         }
         
         completion(.success("ilya's token"))
      }
   }
   
   func sources(from timeline: [Event], width scheduler: TestScheduler) ->
      (username: Observable<String?>, password: Observable<String?>, loginAction: Observable<Void>) {
         func getSource<A>(selector: (Event) -> A?) -> Observable<A> {
            return scheduler
               .createHotObservable(
                  timeline
                     .enumerated()
                     .flatMap { time, event in
                        guard let val = selector(event) else { return nil }
                        return next(time + 1, val)
                  }
               )
               .asObservable()
         }
         
         let usernameSource = getSource { event -> String?? in
            guard case let .username(val) = event else { return nil }
            return val
         }
         
         let passwordSource = getSource { event -> String?? in
            guard case let .password(val) = event else { return nil }
            return val
         }
         
         let loginActionSource = getSource { event -> Void? in
            guard case .loginAction = event else { return nil }
            return ()
         }
         
         return (usernameSource, passwordSource, loginActionSource)
   }
   
   func testSuccessfulLogin() {
      let disposeBag = DisposeBag()
      
      let timeline: [Event] = [
         // typing username, "ilya"
         .username("i"),
         .username("il"),
         .username("ily"),
         .username("ilya"),
         // typing password, "abc"
         .password("a"),
         .password("ab"),
         .password("abc"),
         // try to login
         .loginAction
      ]
      
      let (username, password, loginAction) = sources(from: timeline, width: scheduler)
      let loginModel = LoginModel(
         usernameSource: username,
         passwordSource: password,
         loginActionSource: loginAction,
         loginFunc: testLoginFunc
      )
      
      let isLoginEnabledObserver = scheduler.createObserver(Bool.self)
      let expectedIsLoginEnabledEvents = [
         next(0, false),
         // typing username
         next(1, false),
         next(2, false),
         next(3, false),
         next(4, false),
         // typing password
         next(5, true),
         next(6, true),
         next(7, true),
         // tapping login button
         next(8, false),
         // logged in
         next(9, false)
      ]
      
      let isLoginInProgressObserver = scheduler.createObserver(Bool.self)
      let expectedIsLoginInProgressEvents = [
         next(0, false),
         // tapping login button
         next(8, true),
         // logged in
         next(9, false)
      ]
      
      let didLoginResultObserver = scheduler.createObserver(String.self)
      let expectedDidLoginResultEvents = [
         next(9, "ilya's token")
      ]
      
      let didLoginMessageObserver = scheduler.createObserver(String.self)
      let expectedDidLoginMessageEvents = [
         next(0, " "),
         next(9, "Succeeded!")
      ]
      
      let didFinishLoginObserver = scheduler.createObserver(String.self)
      let expectedDidFinishLoginEvents = [
         next(9, "ilya's token"),
         completed(9)
      ]
      
      let isNotLoginInProgressOrDoneObserver = scheduler.createObserver(Bool.self)
      let expectedIsNotLoginInProgressOrDoneEvents = [
         next(0, true),
         // logging in
         next(8, false),
         // done
         next(9, false)
      ]
      
      scheduler.scheduleAt(0) {
         loginModel.isLoginInProgress.asObservable().subscribe(isLoginInProgressObserver).disposed(by: disposeBag)
         loginModel.isLoginEnabled.asObservable().subscribe(isLoginEnabledObserver).disposed(by: disposeBag)
         loginModel.didLoginResult.asObservable().map { $0.wrapped(or: "") }.subscribe(didLoginResultObserver).disposed(by: disposeBag)
         loginModel.didLoginMessage.asObservable().subscribe(didLoginMessageObserver).disposed(by: disposeBag)
         loginModel.didFinishLogin.asObservable().subscribe(didFinishLoginObserver).disposed(by: disposeBag)
         loginModel.isNotLoginInProgressOrDone.asObservable().subscribe(isNotLoginInProgressOrDoneObserver).disposed(by: disposeBag)
      }
      
      scheduler.start()
      
      XCTAssertEqual(isLoginInProgressObserver.events, expectedIsLoginInProgressEvents)
      XCTAssertEqual(isLoginEnabledObserver.events, expectedIsLoginEnabledEvents)
      XCTAssertEqual(didLoginResultObserver.events, expectedDidLoginResultEvents)
      XCTAssertEqual(didLoginMessageObserver.events, expectedDidLoginMessageEvents)
      XCTAssertEqual(didFinishLoginObserver.events, expectedDidFinishLoginEvents)
      XCTAssertEqual(isNotLoginInProgressOrDoneObserver.events, expectedIsNotLoginInProgressOrDoneEvents)
   }

   func testFailedLogin() {
      let disposeBag = DisposeBag()
      
      let timeline: [Event] = [
         // typing username, "ilya"
         .username("i"),
         .username("il"),
         .username("ily"),
         .username("ilya"),
         // typing password, "abc"
         .password("a"),
         .password("ab"),
         // try to login
         .loginAction
      ]
      
      let (username, password, loginAction) = sources(from: timeline, width: scheduler)
      let loginModel = LoginModel(
         usernameSource: username,
         passwordSource: password,
         loginActionSource: loginAction,
         loginFunc: testLoginFunc
      )
      
      let isLoginEnabledObserver = scheduler.createObserver(Bool.self)
      let expectedIsLoginEnabledEvents = [
         next(0, false),
         // typing username
         next(1, false),
         next(2, false),
         next(3, false),
         next(4, false),
         // typing password
         next(5, true),
         next(6, true),
         // tapping login button
         next(7, false),
         // not logged in
         next(8, true)
      ]
      
      let isLoginInProgressObserver = scheduler.createObserver(Bool.self)
      let expectedIsLoginInProgressEvents = [
         next(0, false),
         // tapping login button
         next(7, true),
         // not logged in
         next(8, false)
      ]
      
      let didLoginResultObserver = scheduler.createObserver(String.self)
      let expectedDidLoginResultEvents = [
         next(8, "")
      ]
      
      let didLoginMessageObserver = scheduler.createObserver(String.self)
      let expectedDidLoginMessageEvents = [
         next(0, " "),
         next(8, "Invalid username / password")
      ]
      
      let didFinishLoginObserver = scheduler.createObserver(String.self)
      
      let isNotLoginInProgressOrDoneObserver = scheduler.createObserver(Bool.self)
      let expectedIsNotLoginInProgressOrDoneEvents = [
         next(0, true),
         // logging in
         next(7, false),
         // done
         next(8, true)
      ]
      
      scheduler.scheduleAt(0) {
         loginModel.isLoginInProgress.asObservable().subscribe(isLoginInProgressObserver).disposed(by: disposeBag)
         loginModel.isLoginEnabled.asObservable().subscribe(isLoginEnabledObserver).disposed(by: disposeBag)
         loginModel.didLoginResult.asObservable().map { $0.wrapped(or: "") }.subscribe(didLoginResultObserver).disposed(by: disposeBag)
         loginModel.didLoginMessage.asObservable().subscribe(didLoginMessageObserver).disposed(by: disposeBag)
         loginModel.didFinishLogin.asObservable().subscribe(didFinishLoginObserver).disposed(by: disposeBag)
         loginModel.isNotLoginInProgressOrDone.asObservable().subscribe(isNotLoginInProgressOrDoneObserver).disposed(by: disposeBag)
      }
      
      scheduler.start()
      
      XCTAssertEqual(isLoginInProgressObserver.events, expectedIsLoginInProgressEvents)
      XCTAssertEqual(isLoginEnabledObserver.events, expectedIsLoginEnabledEvents)
      XCTAssertEqual(didLoginResultObserver.events, expectedDidLoginResultEvents)
      XCTAssertEqual(didLoginMessageObserver.events, expectedDidLoginMessageEvents)
      XCTAssertEqual(didFinishLoginObserver.events.count, 0)
      XCTAssertEqual(isNotLoginInProgressOrDoneObserver.events, expectedIsNotLoginInProgressOrDoneEvents)
   }
}



