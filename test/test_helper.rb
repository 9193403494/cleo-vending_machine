# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  add_filter %r{^/test/.+}
end

require 'cleo'

require 'minitest/autorun'
