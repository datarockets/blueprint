# Blueprint

Blueprint is the Rails application starter used at [datarockets](datarockets.com).

## Installation

TODO: fix it

Add this line to your application's Gemfile:

```ruby
gem 'blueprint'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install blueprint

## Usage

For creating rails application run:

    $ blueprint new APP_NAME

### Create custom generator

Guide for creating and editing generators.

#### Step 1: create command for calling generator

Add command for generator in `lib/blueprint/generator/cli.rb`.

Example:

```ruby
command :new do |c|
  c.syntax = 'blueprint new APP_PATH'
  c.summary = 'Generate rails application'
  c.description = 'Generate rails application with default settings and dependecies'
  c.action do |args, _options|
    Blueprint::Generator::RailsApp.new(name: args[0]).run!
  end
end
```

#### Step 2: Create generator class

Extending class of `Blueprint::Generator::Base`:

```ruby
require 'blueprint/generator/base'

module Blueprint
  module Generator
    class RailsApp < Base
    end
  end
end
```

#### Step 3: Create folder with files

Create folder for files and templates for your application on folder `lib/blueprint/generator/templates/` and override folder name on generator class

```ruby
def self.template_path
  'rails_app'
end
```

#### Step 4: Create ask question step for generator

Override `ask_questions` method for creating `config` hash. [Question list.](https://github.com/commander-rb/commander#highline)

```ruby
def ask_questions
  config[:bootstrap] = agree("Would you like initialize bootstrap on your application?")
end
```

#### Step 5: Create generator script

Override `execute` method for creating generator script.

```ruby
def execute
  shell "rails new #{name} --skip-bundle --database=postgresql --no-rc --skip-test-unit"
end
```

List with commands for creating execute script:

Command | Description | Example
--- | --- | ---
`cmd_title(string)` | Puts string on console | `cmd_title('Start script')`
`shell(cmd)` | Run shell command | `shell('mkdir examples')`
`cd_path(path)` | Change current path | `cd_path(name)`
`copy_file(from, to)` | Copy file from templates path to project. If second argument exist, copy file to tepmlates path | `copy_file('.editorconfig')`
`copy_file_from_template(from, to)` | Copy `erb` file from templates path to project with parsing. If second argument exist, copy file to tepmlates path | `copy_file_from_template('Gemfile')`

Variable lists in generator class and erb templates

Variable | Description
--- | ---
name | First argument on running script
config | Generated on `ask_question` step

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/blueprint. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

