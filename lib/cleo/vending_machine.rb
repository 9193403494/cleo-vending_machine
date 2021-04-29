# frozen_string_literal: true

require 'aasm'

require 'cleo/vending_machine/exception'
require 'cleo/vending_machine/exchange'
require 'cleo/vending_machine/product'
require 'cleo/vending_machine/vault'

module Cleo
  class VendingMachine
    module State
      IDLE = :idle
      WAITING_PAYMENT = :waiting_payment
    end

    attr_reader :exchange, :state

    # @example The initial load of products and change can be done by passing along a hash representation of them.
    #   VendingMachine.new(
    #     products: {
    #       '1111' => {
    #         quantity: 1,
    #         price: 1
    #       }
    #     },
    #     change: {
    #       1 => 1
    #     }
    #   )
    #
    # @param [Hash<String,Hash<Symbol,Fixnum>>] products A hash representation of the initial load of Products.
    # @param [Hash<Fixnum,Fixnum>] change A hash representation of the initial load of change.
    def initialize(products: {}, change: {})
      @products = products
      @vault = Vault.new(change: change)

      idle!
    end

    # @param [Hash<String,Hash<Symbol,Fixnum>>] incoming_products A hash representation of an assortment of Products.
    def add_products(incoming_products)
      incoming_products.each do |code, attributes|
        products[code] ||= { quantity: 0 }
        products[code][:quantity] += attributes[:quantity]
        products[code][:price] = attributes[:price]
      end
    end

    # @param [Hash<Fixnum,Fixnum>] incoming_change A hash representation of the an assortment of change.
    def add_change(incoming_change)
      vault.add_change(incoming_change)
    end

    # @param [Fixnum] amount
    # @return [Cleo::VendingMachine::Exchange]
    # @raise [Cleo::VendingMachine::Exception::InvalidOperationError]
    def pay(amount)
      raise Exception::InvalidOperationError unless waiting_payment?

      register_payment(amount)

      return close_transaction! if balance >= 0

      exchange
    end

    def idle?
      state == State::IDLE
    end

    # @param [String] code
    # @return [Cleo::VendingMachine::Exchange]
    # @raise [Cleo::VendingMachine::Exception::UnavailableProductError]
    def request_product(code)
      raise Exception::UnavailableProductError if products[code].nil?

      select_product!(code)

      @exchange = Exchange.new(balance: -selected_product.price)
    end

    def waiting_payment?
      state == State::WAITING_PAYMENT
    end

    private

    attr_reader :payments, :products, :selected_product, :vault

    # @return [Fixnum] current balance
    def balance
      payments.sum - selected_product.price
    end

    def cancel_transaction!
      exchange.balance = payments.sum
      exchange.change = vault.change_for(payments.sum)
      return_product!
      idle!
    end

    # Updates the exchange with the final change and the selected product.
    # If it fails to get the proper amount change it cancels the transaction
    # and raises an error.
    #
    # @return [Cleo::VendingMachine::Exchange] exchange
    # @raise [Cleo::VendingMachine::Exception::UnavailableChangeError]
    def close_exchange!
      exchange.change = vault.change_for(balance)
      exchange.product = selected_product

      exchange
    rescue Exception::UnavailableChangeError => e
      cancel_transaction!

      raise e
    end

    # @return [Cleo::VendingMachine::Exchange] detached exchange
    def close_transaction!
      detached_exchange = close_exchange!

      idle!

      detached_exchange
    end

    # Resets the inner state and sets the VendingMachine to idle
    def idle!
      @exchange = nil
      @payments = []
      @selected_product = nil
      @state = State::IDLE
    end

    def register_payment(amount)
      payments << amount

      exchange.balance = balance

      vault.add_change({ amount => 1 })
    end

    # Returns the selected product to the overall stock
    def return_product!
      products[selected_product.code] ||= {
        quantity: 0,
        price: selected_product.price
      }

      products[selected_product.code][:quantity] += 1
    end

    # @param [String] code Product code
    def select_product!(code)
      @selected_product = Product.new(code: code, price: products[code][:price])

      products.delete(code) if (products[code][:quantity] -= 1).zero?

      waiting_payment!
    end

    def waiting_payment!
      @state = State::WAITING_PAYMENT
    end
  end
end
