require 'rubygems'
require 'commander/import'

program :name, 'blueprint'
program :version, Blueprint::VERSION
program :description, 'Rails application starter used at datarockets'

command :test do |c|
  c.syntax = 'blueprint§ test [options]'
  c.summary = 'Test command'
  c.description = 'Print HEllo world message'
  c.example 'Description test command', 'yaps test'
  c.action do # |args, options|
    puts 'Hello world!!!'
  end
end
