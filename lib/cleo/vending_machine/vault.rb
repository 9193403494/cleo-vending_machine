# frozen_string_literal: true

module Cleo
  class VendingMachine
    # Keeps track of the currently available change and figures out how to
    # return it in _greedy_ way.
    class Vault
      # @param [Hash<Fixnum,Fixnum>] change arrengement of change
      def initialize(change:)
        @change = change
      end

      # @param [Hash<Fixnum,Fixnum>] incoming_change arrangement of change
      def add_change(incoming_change)
        incoming_change.each do |denomination, quantity|
          change[denomination] ||= 0
          change[denomination] += quantity
        end
      end

      # @param [Fixnum] amount
      # @return [Hash<Fixnum,Fixnum>] arrangement of change
      def change_for(amount)
        change_array = calculate_change_for(amount, change.clone)

        change_array.group_by { _1 }.each_with_object({}) do |(denomination, array), hash|
          hash[denomination] = array.count

          change.delete(denomination) if (change[denomination] -= hash[denomination]).zero?
        end
      end

      private

      attr_reader :change

      def calculate_change_for(amount, available_change)
        return [] if amount.zero?

        available_change.keys.filter { _1 <= amount }.sort_by(&:-@).each do |denomination|
          available_change.delete(denomination) if (available_change[denomination] -= 1).zero?

          return [denomination] + calculate_change_for(amount - denomination, available_change.clone)
        rescue Exception::UnavailableChangeError
          next
        end

        raise Exception::UnavailableChangeError
      end
    end
  end
end
