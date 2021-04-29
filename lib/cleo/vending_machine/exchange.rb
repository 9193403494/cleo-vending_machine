# frozen_string_literal: true

module Cleo
  class VendingMachine
    # It holds the status of a given operation.
    #
    # Its @balance represents the amount of money on favor of the client.
    #
    # It will keep a negativa balance until the target product has been paid in full.
    #
    # Once the balance reaches a value of 0+ the consumer should be able to get
    # the product and the change from the Exchange instance.
    class Exchange
      attr_accessor :balance, :change, :product

      # param [Fixnum] balance Initial balance, that shold be equal to the full price of the target product * -1.
      def initialize(balance:)
        @balance = balance
        @change = nil
        @product = nil
      end
    end
  end
end
