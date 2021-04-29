# frozen_string_literal: true

Gem::Specification.new do |s|
  s.authors = ['R9193403494']
  s.email = '919340349@91934034944'
  s.homepage = 'http://github.com/9193403494/cleo-vending_machine'
  s.name = 'cleo-vending_machine'
  s.summary = 'Cleo::VendingMachine - A Backend Engineer Take Home Test'
  s.version = '1.0'

  s.files = [
    'lib/cleo.rb',
    'lib/cleo/vending_machine.rb',
    'lib/cleo/vending_machine/exception.rb',
    'lib/cleo/vending_machine/exception/invalid_operation_error.rb',
    'lib/cleo/vending_machine/exception/unavailable_change_error.rb',
    'lib/cleo/vending_machine/exception/unavailable_product_error.rb',
    'lib/cleo/vending_machine/exchange.rb',
    'lib/cleo/vending_machine/product.rb',
    'lib/cleo/vending_machine/vault.rb'
  ]

  s.extra_rdoc_files = [
    'README.md'
  ]

  s.required_ruby_version = '>= 2.7.0'

  s.add_runtime_dependency 'aasm', '~>5.1.1'

  s.add_development_dependency 'minitest', '~>5.14.4'
  s.add_development_dependency 'rake', '~>13.0.3'
  s.add_development_dependency 'rubocop', '~>1.13.0'
  s.add_development_dependency 'simplecov', '~>0.21.2'
  s.add_development_dependency 'yard', '~>0.9.26'
end
