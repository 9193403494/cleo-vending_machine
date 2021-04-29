# frozen_string_literal: true

module Cleo
  class VendingMachine
    class Product
      attr_reader :code, :price

      def initialize(code:, price:)
        @code = code
        @price = price
      end
    end
  end
end
