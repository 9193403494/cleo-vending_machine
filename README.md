# Cleo::VendingMachine
A Backend Engineer Take Home Test

Note: Open /docs/index.html on your favourite browser for maximum enjoyment (?)

Anonymized online version also available at:

* Full Documentation: https://9193403494.github.io/cleo-vending_machine/
* Repository: https://github.com/9193403494/cleo-vending_machine

## Objective

For this we’d like you to write code for a vending machine that behaves as follows:

* Once an item is selected and the appropriate amount of money is inserted, the vending machine should return the correct product
* The machine should return change if too much money is provided
* The machine should ask for more money if insufficient funds have been inserted
* The machine should take an initial load of products and change
* The change will be of denominations: 1p, 2p, 5p, 10p, 20p, 50p, £1, £2
* There should be a way of reloading products at a later point
* There should be a way of reloading change at a later point
* The machine should keep track of the products and change that it contains

Your solution should be provided as library code that implements the business logic defined above.  We don’t want you to write a UI to drive it as well.  We don’t want you to spend too long on this so we’d expect you to spend between two and three hours.  As part of your submission please tell us how much time you do spend on it.

## Initial Considerations

* I will focus on creating a Ruby library following the previouly described behaviour. This seems to be pretty good scenario for some sort of state machine, although it might be a little overkilling given the simplicity of the API.
* The lack of UI suppose a lack of interaction with a real device so all the inputs and outputs will be relaying on Ruby standard classes. Even though I can create some models to represent both the change and the products, forcing the consumer to instanciate those before loading/realoading seems to be also a little too much, so we will resort once again to Ruby standard classes, probably identifying products by code and change by its value in pence.
* The lifecycle of the VendingMachine will be bound to its instance, it will keep track of its current state, but persistence outside the process will be delagated to the library consumer.
* The change will be able to count with the money that was just handed by the buyer.
* The machine will request more money until the product value is covered
* After covering the product's cost the VendingMachine will raise an exception and abort the transaction if it is not able to return the proper amount of change. Real machines usually default to Exact Pay mode preentevly if they are missing any of the possible change scenarios. Creating a communication interface to keep the library consumer updated on the current status, without overexposing arguibly sensitive information, is way out of scope and, even if it is doable, does not make much sence without a deeper discussion of the expected behaviour around that.
* As exposing the stock has not being mentioned the consumer will be able to ask for any product by code and an exception will be rised if the product is not available (it won't really differenciate between _unknown_ and out if stock product codes).

## Usage Design (before implementation)

```ruby
  require 'cleo/vending_machine'

  initial_products = {
    11111: {
      quantity: 3,
      price: 13
    }
  }

  initial_change = {
    1: 20,
    2, 10,
    50: 5
  }

  vm = Cleo::VendingMachine.new(    #=> #<Cleo::VendingMachine
    products: initial_products,     #    @state="ready",
    change: initial_change          #    @balance=0
  )                                 #    @selected_product=nil
                                    #   >

  vm.request_product(11111)         #=> #<Cleo::VendingMachine::Exchange
                                    #     @balance=-12
                                    #     @change=nil
                                    #     @product=nil
                                    #   >
12
  vm                                #=> #<Cleo::VendingMachine
                                    #     @state="waiting_payment",
                                    #     @balance=-12,
                                    #     @selected_product=#<Cleo::VendingMachine::Product @code=11111, @price=12>
                                    #   >

  vm.pay(10)                        #=> #<Cleo::VendingMachine::Exchange
                                    #     @balance=-2
                                    #     @change=nil
                                    #     @product=nil
                                    #   >

  vm                                #=> #<Cleo::VendingMachine
                                    #     @state="waiting_payment",
                                    #     @balance=-2,
                                    #     @selected_product=#<Cleo::VendingMachine::Product @code=11111, @price=12>
                                    #   >

  vm.pay(5)                         #=> #<Cleo::VendingMachine::Exchange
                                    #     @balance=3
                                    #     @change={1: 1, 2: 1}
                                    #     @product=#<Cleo::VendingMachine::Product @code=11111, @price=12>
                                    #   >

  vm                                #=> #<Cleo::VendingMachine
                                    #     @state="ready",
                                    #     @balance=0,
                                    #     @selected_product=nil
                                    #   >

  vm.add_products(initial_products)
  vm.add_change(initial_change)
```

## Coding time!

![Three hours later](https://media.giphy.com/media/XBir51JYWZYSb8IxvV/giphy.gif)

## Reviewing initial considerations / Implementation notes

* Loading products/change as hashes feels a little bit off but I still think it represents a realistic scenario on how the library would actually interact with the consumer. If the `Product` becomes something shared between domains it should probably be extracted from inside that module and it would make more sense at that point to have `Product` instances as inputs.
* For the change calculations I went with a _greedy_ implementation, abusing the exceptions a little bit as flow control between recursions cycles. To account for the limited pool of change/denominations I just proceeded to check and eliminate invalid branches, starting from the _greediest_ all the way to the most generous one.
* Pretty hapy with the overall encapsulation.
* It could use some more time investment around documentation here and there.
* It definitely need some more time investment around how the tests are organized. It's covering everything but the separation fo cencerns is not looking good.
* Same goes for the implementation itself, mostly around the VendingMachine class itself, there are too many variables getting affected by the main methods.
* This implementation is not thread safe. Does not need much more effort to make it thread safe as some locks around the main transactional operations would be enough. Did skip that to prevent an extra leyer of complexity, the extra tests needed and the unexpected bugs I might need to get back to within such a short tiemeframe.
* I really wanted to create `Products` as some sort of `Enumerable` class, run out of time so I left it as an internal Hash,  representing the available product codes and the available stock of each of them.
* Same for the `Vault`, would like to create a colletion-like model to sotre the denominations with their current count as internal attributes rather than a plain Hash.
* Was planning on extending those exceptions a little bit more, with a custom error message and some variables. #OutOfTime
* The implemntation expect both Product and Change loads to hold positive quantities. Adding validations over 0 (ignoring tthe entry) and negative numbres (raising an error) would be pretty simple to do.

## Actual Usage

```ruby
  require 'cleo/vending_machine'

  initial_products = {
    11111: {
      quantity: 3,
      price: 13
    }
  }

  initial_change = {
    1: 20,
    2, 10,
    50: 5
  }

  vm = Cleo::VendingMachine.new(    #=> #<Cleo::VendingMachine
    products: initial_products,     #     @state="idle",
    change: initial_change          #     @exchange=nil
  )                                 #   >

  vm.request_product(11111)         #=> #<Cleo::VendingMachine::Exchange
                                    #     @balance=-12
                                    #     @change=nil
                                    #     @product=nil
                                    #   >
12
  vm                                #=> #<Cleo::VendingMachine
                                    #     @state="waiting_payment",
                                    #     @exchange=#<Cleo::VendingMachine::Exchange ...>
                                    #   >

  vm.pay(10)                        #=> #<Cleo::VendingMachine::Exchange
                                    #     @balance=-2
                                    #     @change=nil
                                    #     @product=nil
                                    #   >

  vm                                #=> #<Cleo::VendingMachine
                                    #     @state="waiting_payment",
                                    #     @exchange=#<Cleo::VendingMachine::Exchange ...>
                                    #   >

  vm.pay(5)                         #=> #<Cleo::VendingMachine::Exchange
                                    #     @balance=3
                                    #     @change={1: 1, 2: 1}
                                    #     @product=#<Cleo::VendingMachine::Product @code=11111, @price=12>
                                    #   >

  vm                                #=> #<Cleo::VendingMachine
                                    #     @state="idle",
                                    #     @exchange=nil
                                    #   >

  vm.add_products(initial_products)
  vm.add_change(initial_change)
```

## Running tests

```
  rake test
```

## Current tests/coverage status

```
# Running:

.................................

Finished in 0.009553s, 3454.4657 runs/s, 4187.2312 assertions/s.

33 runs, 40 assertions, 0 failures, 0 errors, 0 skips
Coverage report generated for Unit Tests to /cleo-vending_machine/coverage. 130 / 130 LOC (100.0%) covered.
```

## Trivia

* `cleo-vending_machine` looks funny but it is just following the gem naming conventions 🤷
* Documented using YARD. It is still rdoc compatible
* The github pages were almost for free, building the yard docs and publishing those under the gb-pages branch
* The whole project has been Rubocopped, small exceptions has been set under the .rubucop.yaml
* Tested with Minitest specs
* The ruby version has been set to 2.7.2, was tempted to use 3.0 but I would probably get distracted trying things out 😆
* Have Simplecov in place to make sure everything was covered and that the main use cases were actually making use of all the defined classes/methods.
* The library implementation + the `VendingMachine` specs + wirting all this down took my all the alloted time. I've spent a couple of minutes on top adding some unit tests aroud the `Vault`. Coverage was still 100% form the get go, as the `VendingMachine` was actually relaying on everything else. For the rest of the classes they are mostly initializers with a couple of getters, the current _integration_ tests (the `VendingMachine` specs) are good enough to keep them safe.

## That's a wrap!

![That's a wrap!](https://media.giphy.com/media/l0IycQmt79g9XzOWQ/giphy.gif)
