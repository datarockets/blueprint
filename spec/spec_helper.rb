$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'blueprint'
require 'simplecov'
require 'pry'
require 'rspec/shell/expectations'

RSpec.configure do |config|
  config.include Rspec::Shell::Expectations

  SimpleCov.start do
    add_filter '/vendor/'
    add_filter '/spec/'
  end
end
