# frozen_string_literal: true

require 'test_helper'

class TestVault < Minitest::Test
  def setup
    @change = {
      1 => 1,
      2 => 1,
      5 => 1,
      10 => 1,
      20 => 1,
      50 => 1,
      100 => 1
    }

    @vault = Cleo::VendingMachine::Vault.new(change: @change)
  end

  def test_initialize
    assert_equal @vault.send(:change), @change
  end

  def test_add_change
    @vault.add_change({ 1 => 1 })
    assert_equal 2, @vault.send(:change)[1]

    @vault.add_change({ 200 => 1 })
    assert_equal 1, @vault.send(:change)[200]
  end

  def test_valid_change_for
    assert_equal({ 50 => 1, 5 => 1, 2 => 1 }, @vault.change_for(57))
  end

  def test_invalid_change_for
    @vault.change_for(4)
  rescue Cleo::VendingMachine::Exception::UnavailableChangeError
    assert true
  else
    raise 'Expected to rise Exception::UnavailableChangeError, none was rised.'
  end
end
