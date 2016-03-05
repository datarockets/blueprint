$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'blueprint'
require 'blueprint/generator/rails_app'
require 'simplecov'
require 'pry'

RSpec.configure do |_config|
  SimpleCov.start do
    add_filter '/vendor/'
    add_filter '/spec/'
  end
end
