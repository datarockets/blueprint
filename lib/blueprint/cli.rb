require 'rubygems'
require 'commander/import'

require 'blueprint/generator/rails_app'

program :name, 'blueprint'
program :version, Blueprint::VERSION
program :description, 'Rails application starter used at datarockets'

command :new do |c|
  c.syntax = 'blueprint new APP_PATH'
  c.summary = 'Generate rails application'
  c.description = 'Generate rails application with default settings and dependecies'
  c.action do |args, _options|
    Blueprint::Generator::RailsApp.new(name: args[0]).run!
  end
end
