$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'simplecov'
SimpleCov.start

require 'codecov'
SimpleCov.formatter = SimpleCov::Formatter::Codecov
require 'onlyoffice_rspec_result_parser'
