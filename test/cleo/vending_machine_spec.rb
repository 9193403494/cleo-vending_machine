# frozen_string_literal: true

require 'test_helper'

describe Cleo::VendingMachine do
  let(:initial_products) do
    {
      '1013' => { quantity: 10, price: 13 },
      '1525' => { quantity: 15, price: 25 }
    }
  end

  let(:initial_change) do
    {
      1 => 10,
      2 => 20,
      5 => 15,
      10 => 10,
      20 => 10,
      50 => 5,
      100 => 2
    }
  end

  let(:vending_machine) { Cleo::VendingMachine.new(products: initial_products, change: initial_change) }

  describe '#initialize' do
    it 'should get initialized as idle' do
      expect(vending_machine.idle?).must_equal true
    end
  end

  describe '#request_product' do
    describe 'with a valid product code' do
      before do
        @exchange = vending_machine.request_product('1013')
      end

      let(:exchange) { @exchange }

      it 'should set the exchange balance based on the product' do
        expect(exchange.balance).must_equal(-13)
      end

      it 'should initialize the exchange product as nil' do
        expect(exchange.product).must_be_nil
      end

      it 'should initialize the exchange change as nil' do
        expect(exchange.change).must_be_nil
      end

      it 'should update the state to waiting_payment' do
        expect(vending_machine.waiting_payment?).must_equal true
      end
    end

    describe 'with an invalid/out of stock product code' do
      subject { proc { vending_machine.request_product('0000') } }

      it 'should raise and expection' do
        expect(subject).must_raise Cleo::VendingMachine::Exception::UnavailableProductError
      end
    end
  end

  describe '#pay' do
    describe 'when the VendingMachine state is idle' do
      subject { proc { vending_machine.pay(10) } }

      it 'should raise an exception' do
        expect(subject).must_raise Cleo::VendingMachine::Exception::InvalidOperationError
      end
    end

    describe 'when the VendingMachine state is waiting_payment' do
      before do
        @exchange = vending_machine.request_product('1013')
      end

      let(:exchange) { @exchange }

      describe 'when the final balance is negative' do
        before do
          vending_machine.pay(10)
        end

        it 'should update the exchange balance' do
          expect(exchange.balance).must_equal(-3)
        end

        it 'should keep the exchange product as nil' do
          expect(exchange.product).must_be_nil
        end

        it 'should keep the exchange change as nil' do
          expect(exchange.change).must_be_nil
        end

        it 'should keep the state as waiting_payment' do
          expect(vending_machine.waiting_payment?).must_equal true
        end
      end

      describe 'when the final balance is zero' do
        before do
          vending_machine.pay(10)
          vending_machine.pay(2)
          vending_machine.pay(1)
        end

        it 'should update the exchange balance' do
          expect(exchange.balance).must_equal(0)
        end

        it 'should set the exchange product' do
          expect(exchange.product).wont_be_nil
          expect(exchange.product.code).must_equal '1013'
          expect(exchange.product.price).must_equal 13
        end

        it 'should set the exchange change' do
          expect(exchange.change).must_equal({})
        end

        it 'should update the state to idle' do
          expect(vending_machine.idle?).must_equal true
        end
      end

      describe 'when the final balance is positive' do
        before do
          vending_machine.pay(20)
        end

        it 'should update the exchange balance' do
          expect(exchange.balance).must_equal(7)
        end

        it 'should set the exchange product' do
          expect(exchange.product).wont_be_nil
          expect(exchange.product.code).must_equal '1013'
          expect(exchange.product.price).must_equal 13
        end

        it 'should set the exchange change as an empty hash' do
          expect(exchange.change).must_equal({ 2 => 1, 5 => 1 })
        end

        it 'should update the state to idle' do
          expect(vending_machine.idle?).must_equal true
        end
      end

      describe 'when there is no availabel change for the final balance' do
        let(:initial_change) do
          {
            5 => 1
          }
        end

        before do
          vending_machine.pay(20)
        rescue Cleo::VendingMachine::Exception::UnavailableChangeError => e
          @error = e
        end

        it 'should rise an error' do
          expect(@error).must_be_instance_of(Cleo::VendingMachine::Exception::UnavailableChangeError)
        end

        it 'should update the exchange balance' do
          expect(exchange.balance).must_equal(20)
        end

        it 'should not set the exchange product' do
          expect(exchange.product).must_be_nil
        end

        it 'should set the exchange change to the paid value' do
          expect(exchange.change).must_equal({ 20 => 1 })
        end

        it 'should update the state to idle' do
          expect(vending_machine.idle?).must_equal true
        end
      end
    end
  end

  describe '#add_products' do
    before do
      vending_machine.add_products({
                                     '1013' => { quantity: 1, price: 13 },
                                     '1525' => { quantity: 1, price: 24 },
                                     '2020' => { quantity: 20, price: 20 }
                                   })
    end

    it 'should update the quantity of an existing product' do
      expect(vending_machine.send(:products)['1013'][:quantity]).must_equal 11
    end

    it 'should update the quantity and price when a new price is provided' do
      expect(vending_machine.send(:products)['1525'][:price]).must_equal 24
    end

    it 'should create a new entry for new products' do
      expect(vending_machine.send(:products)['2020']).wont_be_nil
      expect(vending_machine.send(:products)['2020'][:quantity]).must_equal 20
      expect(vending_machine.send(:products)['2020'][:price]).must_equal 20
    end
  end

  describe '#add_change' do
    before do
      vending_machine.add_change({
                                   1 => 10,
                                   200 => 1
                                 })
    end

    it 'should update the quantity of an existing denomination' do
      expect(vending_machine.send(:vault).send(:change)[1]).must_equal 20
    end

    it 'should create a new entry for new denomination' do
      expect(vending_machine.send(:vault).send(:change)[200]).must_equal 1
    end
  end
end
