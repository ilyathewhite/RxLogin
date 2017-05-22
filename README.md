# NoRxLogin, a simulation of a login form without RxSwift

Implements the same functionality as RxLogin, but without RxSwift. Some highlights:

- the model code is much more imperative. There are some calculated properties, but they need to be called manually to update the model. 
- didSet clauses simulate some of the reactive version logic, but they require much more boilerplate code and increase a chance for bugs
- some of the app logic is moved into controller
- the controller code is more verbose and less clear about how controls interact with the model
- delegates require a lot of boilerplate code, make the code harder to follow and increase a chance for bugs
- the common patterns are easy to read (didSet, delegates), but their expression requires much more custom code than the reactive version which heavily uses standard building blocks to express patterns.
