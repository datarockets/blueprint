
# >----------------------------[ Initial Setup ]------------------------------<

module Gemfile
  class GemInfo
    def initialize(name) @name=name; @group=[]; @opts={}; end
    attr_accessor :name, :version
    attr_reader :group, :opts

    def opts=(new_opts={})
      new_group = new_opts.delete(:group)
      if (new_group && self.group != new_group)
        @group = ([self.group].flatten + [new_group].flatten).compact.uniq.sort
      end
      @opts = (self.opts || {}).merge(new_opts)
    end

    def group_key() @group end

    def gem_args_string
      args = ["'#{@name}'"]
      args << "'#{@version}'" if @version
      @opts.each do |name,value|
        args << ":#{name}=>#{value.inspect}"
      end
      args.join(', ')
    end
  end

  @geminfo = {}

  class << self
    # add(name, version, opts={})
    def add(name, *args)
      name = name.to_s
      version = args.first && !args.first.is_a?(Hash) ? args.shift : nil
      opts = args.first && args.first.is_a?(Hash) ? args.shift : {}
      @geminfo[name] = (@geminfo[name] || GemInfo.new(name)).tap do |info|
        info.version = version if version
        info.opts = opts
      end
    end

    def write
      File.open('Gemfile', 'a') do |file|
        file.puts
        grouped_gem_names.sort.each do |group, gem_names|
          indent = ""
          unless group.empty?
            file.puts "group :#{group.join(', :')} do" unless group.empty?
            indent="  "
          end
          gem_names.sort.each do |gem_name|
            file.puts "#{indent}gem #{@geminfo[gem_name].gem_args_string}"
          end
          file.puts "end" unless group.empty?
          file.puts
        end
      end
    end

    private
    #returns {group=>[...gem names...]}, ie {[:development, :test]=>['rspec-rails', 'mocha'], :assets=>[], ...}
    def grouped_gem_names
      {}.tap do |_groups|
        @geminfo.each do |gem_name, geminfo|
          (_groups[geminfo.group_key] ||= []).push(gem_name)
        end
      end
    end
  end
end
def add_gem(*all) Gemfile.add(*all); end

@recipes = ["core"]
@prefs = {:apps4=>"none", :continuous_testing=>"none", :announcements=>"none", :authentication=>"devise", :authorization=>"none", :dashboard=>"none", :deployment=>"capistrano3", :ban_spiders=>false, :github=>true, :frontend=>"none", :database=>"postgresql", :better_errors=>true, :form_builder=>"symple_form", :pry=>true, :tests=>"rspec", :git=>true, :email=>"smtp", :templates=>"erb", :disable_turbolinks=>true, :rubocop=>true, :analytics=>"none", :locale=>"none", :pages=>"none", :rvmrc=>true}
@gems = []
@diagnostics_recipes = [["example"], ["setup"], ["railsapps"], ["gems", "setup"], ["gems", "readme", "setup"], ["extras", "gems", "readme", "setup"], ["example", "git"], ["git", "setup"], ["git", "railsapps"], ["gems", "git", "setup"], ["gems", "git", "readme", "setup"], ["extras", "gems", "git", "readme", "setup"], ["email", "extras", "frontend", "gems", "git", "init", "railsapps", "readme", "setup", "testing"], ["core", "email", "extras", "frontend", "gems", "git", "init", "railsapps", "readme", "setup", "testing"], ["core", "email", "extras", "frontend", "gems", "git", "init", "railsapps", "readme", "setup", "testing"], ["core", "email", "extras", "frontend", "gems", "git", "init", "railsapps", "readme", "setup", "testing"], ["email", "example", "extras", "frontend", "gems", "git", "init", "railsapps", "readme", "setup", "testing"], ["email", "example", "extras", "frontend", "gems", "git", "init", "railsapps", "readme", "setup", "testing"], ["email", "example", "extras", "frontend", "gems", "git", "init", "railsapps", "readme", "setup", "testing"], ["apps4", "core", "email", "extras", "frontend", "gems", "git", "init", "railsapps", "readme", "setup", "testing"], ["apps4", "core", "email", "extras", "frontend", "gems", "git", "init", "railsapps", "readme", "setup", "tests"], ["apps4", "core", "deployment", "email", "extras", "frontend", "gems", "git", "init", "railsapps", "readme", "setup", "testing"], ["apps4", "core", "deployment", "email", "extras", "frontend", "gems", "git", "init", "railsapps", "readme", "setup", "tests"], ["apps4", "core", "deployment", "devise", "email", "extras", "frontend", "gems", "git", "init", "omniauth", "pundit", "railsapps", "readme", "setup", "tests"]]
@diagnostics_prefs = []
diagnostics = {}

# >-------------------------- templates/helpers.erb --------------------------start<
def recipes; @recipes end
def recipe?(name); @recipes.include?(name) end
def prefs; @prefs end
def prefer(key, value); @prefs[key].eql? value end
def gems; @gems end
def diagnostics_recipes; @diagnostics_recipes end
def diagnostics_prefs; @diagnostics_prefs end

def say_custom(tag, text); say "\033[1m\033[36m" + tag.to_s.rjust(10) + "\033[0m" + "  #{text}" end
def say_loud(tag, text); say "\033[1m\033[36m" + tag.to_s.rjust(10) + "  #{text}" + "\033[0m" end
def say_recipe(name); say "\033[1m\033[36m" + "recipe".rjust(10) + "\033[0m" + "  Running #{name} recipe..." end
def say_wizard(text); say_custom(@current_recipe || 'composer', text) end

def ask_wizard(question)
  ask "\033[1m\033[36m" + ("option").rjust(10) + "\033[1m\033[36m" + "  #{question}\033[0m"
end

def whisper_ask_wizard(question)
  ask "\033[1m\033[36m" + ("choose").rjust(10) + "\033[0m" + "  #{question}"
end

def yes_wizard?(question)
  answer = ask_wizard(question + " \033[33m(y/n)\033[0m")
  case answer.downcase
    when "yes", "y"
      true
    when "no", "n"
      false
    else
      yes_wizard?(question)
  end
end

def no_wizard?(question); !yes_wizard?(question) end

def multiple_choice(question, choices)
  say_custom('option', "\033[1m\033[36m" + "#{question}\033[0m")
  values = {}
  choices.each_with_index do |choice,i|
    values[(i + 1).to_s] = choice[1]
    say_custom( (i + 1).to_s + ')', choice[0] )
  end
  answer = whisper_ask_wizard("Enter your selection:") while !values.keys.include?(answer)
  values[answer]
end

@current_recipe = nil
@configs = {}

@after_blocks = []
def stage_two(&block); @after_blocks << [@current_recipe, block]; end
@stage_three_blocks = []
def stage_three(&block); @stage_three_blocks << [@current_recipe, block]; end
@stage_four_blocks = []
def stage_four(&block); @stage_four_blocks << [@current_recipe, block]; end
@before_configs = {}
def before_config(&block); @before_configs[@current_recipe] = block; end

def copy_from(source, destination)
  begin
    remove_file destination
    get source, destination
  rescue OpenURI::HTTPError
    say_wizard "Unable to obtain #{source}"
  end
end

def copy_from_repo(filename, opts = {})
  repo = 'https://raw.github.com/RailsApps/rails-composer/master/files/'
  repo = opts[:repo] unless opts[:repo].nil?
  if (!opts[:prefs].nil?) && (!prefs.has_value? opts[:prefs])
    return
  end
  source_filename = filename
  destination_filename = filename
  unless opts[:prefs].nil?
    if filename.include? opts[:prefs]
      destination_filename = filename.gsub(/\-#{opts[:prefs]}/, '')
    end
  end
  if (prefer :templates, 'slim') && (filename.include? 'views')
    remove_file destination_filename
    destination_filename = destination_filename.gsub(/.erb/, '.slim')
  end
  begin
    remove_file destination_filename
    if (prefer :templates, 'slim') && (filename.include? 'views')
      create_file destination_filename, html_to_slim(repo + source_filename)
    else
      get repo + source_filename, destination_filename
    end
  rescue OpenURI::HTTPError
    say_wizard "Unable to obtain #{source_filename} from the repo #{repo}"
  end
end

def html_to_slim(source)
  html = open(source) {|input| input.binmode.read }
  haml = Html2haml::HTML.new(html, :erb => true, :xhtml => true).render
  Haml2Slim.convert!(haml)
end

# full credit to @mislav in this StackOverflow answer for the #which() method:
# - http://stackoverflow.com/a/5471032
def which(cmd)
  exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
  ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
    exts.each do |ext|
    exe = "#{path}#{File::SEPARATOR}#{cmd}#{ext}"
      return exe if File.executable? exe
    end
  end
  return nil
end
# >-------------------------- templates/helpers.erb --------------------------end<

say_wizard("\033[1m\033[36m" + "" + "\033[0m")

say_wizard("\033[1m\033[36m" + ' _____       _ _' + "\033[0m")
say_wizard("\033[1m\033[36m" + "|  __ \\     \(_\) |       /\\" + "\033[0m")
say_wizard("\033[1m\033[36m" + "| |__) |__ _ _| |___   /  \\   _ __  _ __  ___" + "\033[0m")
say_wizard("\033[1m\033[36m" + "|  _  /\/ _` | | / __| / /\\ \\ | \'_ \| \'_ \\/ __|" + "\033[0m")
say_wizard("\033[1m\033[36m" + "| | \\ \\ (_| | | \\__ \\/ ____ \\| |_) | |_) \\__ \\" + "\033[0m")
say_wizard("\033[1m\033[36m" + "|_|  \\_\\__,_|_|_|___/_/    \\_\\ .__/| .__/|___/" + "\033[0m")
say_wizard("\033[1m\033[36m" + "                             \| \|   \| \|" + "\033[0m")
say_wizard("\033[1m\033[36m" + "                             \| \|   \| \|" + "\033[0m")
say_wizard("\033[1m\033[36m" + '' + "\033[0m")
say_wizard("Your new application will contain diagnostics in its README file.")

if diagnostics_recipes.sort.include? recipes.sort
  diagnostics[:recipes] = 'success'
else
  diagnostics[:recipes] = 'fail'
end

# this application template only supports Rails version 4.1 and newer
case Rails::VERSION::MAJOR.to_s
when "5"
  say_wizard "You are using Rails version #{Rails::VERSION::STRING}. Please report any issues."
when "4"
  case Rails::VERSION::MINOR.to_s
  when "0"
    say_wizard "You are using Rails version #{Rails::VERSION::STRING} which is not supported. Use Rails 4.1 or newer."
    raise StandardError.new "Rails #{Rails::VERSION::STRING} is not supported. Use Rails 4.1 or newer."
  end
else
  say_wizard "You are using Rails version #{Rails::VERSION::STRING} which is not supported. Use Rails 4.1 or newer."
  raise StandardError.new "Rails #{Rails::VERSION::STRING} is not supported. Use Rails 4.1 or newer."
end

# >---------------------------[ Autoload Modules/Classes ]-----------------------------<

inject_into_file 'config/application.rb', :after => 'config.autoload_paths += %W(#{config.root}/extras)' do <<-'RUBY'

    config.autoload_paths += %W(#{config.root}/lib)
RUBY
end

# >---------------------------------[ Recipes ]----------------------------------<

# >-------------------------- templates/recipe.erb ---------------------------start<
# >---------------------------------[ core ]----------------------------------<
@current_recipe = "core"
@before_configs["core"].call if @before_configs["core"]
say_recipe 'core'
@configs[@current_recipe] = config
# >----------------------------- recipes/core.rb -----------------------------start<

## Git
say_wizard "selected all core recipes"
# >----------------------------- recipes/core.rb -----------------------------end<
# >-------------------------- templates/recipe.erb ---------------------------end<

# >-------------------------- templates/recipe.erb ---------------------------start<
# >----------------------------------[ git ]----------------------------------<
@current_recipe = "git"
@before_configs["git"].call if @before_configs["git"]
say_recipe 'git'
@configs[@current_recipe] = config
# >----------------------------- recipes/git.rb ------------------------------start<

# Application template recipe for the rails_apps_composer. Change the recipe here:
# https://github.com/RailsApps/rails_apps_composer/blob/master/recipes/git.rb

## Git
say_wizard "initialize git"
prefs[:git] = true unless prefs.has_key? :git
if prefer :git, true
  copy_from 'https://raw.github.com/RailsApps/rails-composer/master/files/gitignore.txt', '.gitignore'
  git :init
  git :add => '-A'
  git :commit => '-qm "rails_apps_composer: initial commit"'
else
  stage_three do
    say_wizard "recipe stage three"
    say_wizard "removing .gitignore and .gitkeep files"
    git_files = Dir[File.join('**','.gitkeep')] + Dir[File.join('**','.gitignore')]
    File.unlink git_files
  end
end
# >----------------------------- recipes/git.rb ------------------------------end<

# >-------------------------- templates/recipe.erb ---------------------------start<
# >-------------------------------[ railsapps ]-------------------------------<
@current_recipe = "railsapps"
@before_configs["railsapps"].call if @before_configs["railsapps"]
say_recipe 'railsapps'
@configs[@current_recipe] = config
# >-------------------------- recipes/railsapps.rb ---------------------------start<

# Application template recipe for the rails_apps_composer. Change the recipe here:
# https://github.com/RailsApps/rails_apps_composer/blob/master/recipes/railsapps.rb

raise if (defined? defaults) || (defined? preferences) # Shouldn't happen.
if options[:verbose]
  print "\nrecipes: ";p recipes
  print "\ngems: "   ;p gems
  print "\nprefs: "  ;p prefs
  print "\nconfig: " ;p config
end

if (Rails::VERSION::MAJOR < 4 ||  (Rails::VERSION::MAJOR == 4 && Rails::VERSION::MINOR == 0))
  say_wizard "Please upgrade to Rails 4.1 or newer."
else
  prefs[:apps4] = "none"
end

# >-------------------------- recipes/railsapps.rb ---------------------------end<

# >-------------------------- templates/recipe.erb ---------------------------start<
# >---------------------------------[ setup ]---------------------------------<
@current_recipe = "setup"
@before_configs["setup"].call if @before_configs["setup"]
say_recipe 'setup'
@configs[@current_recipe] = config
# >---------------------------- recipes/setup.rb -----------------------------start<


## Ruby on Rails
HOST_OS = RbConfig::CONFIG['host_os']
say_wizard "Your operating system is #{HOST_OS}."
say_wizard "You are using Ruby version #{RUBY_VERSION}."
say_wizard "You are using Rails version #{Rails::VERSION::STRING}."

## Is sqlite3 in the Gemfile?
gemfile = File.read(destination_root() + '/Gemfile')
sqlite_detected = gemfile.include? 'sqlite3'

## Web Server
prefs[:dev_webserver] = multiple_choice "Web server for development?", [["Puma (default)", "puma"],
  ["Thin", "thin"], ["Unicorn", "unicorn"], ["Phusion Passenger (Apache/Nginx)", "passenger"],
  ["Phusion Passenger (Standalone)", "passenger_standalone"]] unless prefs.has_key? :dev_webserver
prefs[:prod_webserver] = multiple_choice "Web server for production?", [["Same as development", "same"],
  ["Thin", "thin"], ["Unicorn", "unicorn"], ["Phusion Passenger (Apache/Nginx)", "passenger"],
  ["Phusion Passenger (Standalone)", "passenger_standalone"]] unless prefs.has_key? :prod_webserver
prefs[:prod_webserver] = prefs[:dev_webserver] if prefs[:prod_webserver] == 'same'

## Database Adapter
prefs[:database] = "sqlite" if prefer :database, 'default'
prefs[:database] = multiple_choice "Database used in development?", [["SQLite", "sqlite"], ["PostgreSQL", "postgresql"],
  ["MySQL", "mysql"]] unless prefs.has_key? :database

## Template Engine
prefs[:templates] = multiple_choice "Template engine?", [["ERB", "erb"], ["Slim", "slim"]] unless prefs.has_key? :templates

## Testing Framework
if recipes.include? 'tests'
  prefs[:tests] = multiple_choice "Test framework?", [["None", "none"],
    ["RSpec with Capybara", "rspec"]] unless prefs.has_key? :tests
  case prefs[:tests]
    when 'rspec'
      say_wizard "Adding DatabaseCleaner, FactoryGirl, Faker"
      prefs[:continuous_testing] = multiple_choice "Continuous testing?", [["None", "none"], ["Guard", "guard"]] unless prefs.has_key? :continuous_testing
    end
end

## Front-end Framework
if recipes.include? 'frontend'
  prefs[:frontend] = multiple_choice "Front-end framework?", [["None", "none"],
    ["Bootstrap 4.0", "bootstrap4"], ["Bootstrap 3.3", "bootstrap3"],
    ["Zurb Foundation 5.5", "foundation5"],
    ["Simple CSS", "simple"]] unless prefs.has_key? :frontend
end

## Email
if recipes.include? 'email'
  unless prefs.has_key? :email
    say_wizard "The Devise 'forgot password' feature requires email." if prefer :authentication, 'devise'
    prefs[:email] = multiple_choice "Add support for sending email?", [["None", "none"], ["Gmail","gmail"], ["SMTP","smtp"],
      ["SendGrid","sendgrid"], ["Mandrill","mandrill"]]
  end
else
  prefs[:email] = 'none'
end

## Authentication and Authorization
if (recipes.include? 'devise') || (recipes.include? 'omniauth')
  prefs[:authentication] = multiple_choice "Authentication?", [["None", "none"], ["Devise", "devise"], ["OmniAuth", "omniauth"]] unless prefs.has_key? :authentication
  case prefs[:authentication]
    when 'devise'
      prefs[:devise_modules] = multiple_choice "Devise modules?", [["Devise with default modules","default"],
      ["Devise with Confirmable module","confirmable"],
      ["Devise with Confirmable and Invitable modules","invitable"]] unless prefs.has_key? :devise_modules
    when 'omniauth'
      prefs[:omniauth_provider] = multiple_choice "OmniAuth provider?", [["Facebook", "facebook"], ["Twitter", "twitter"], ["GitHub", "github"],
        ["LinkedIn", "linkedin"], ["Google-Oauth-2", "google_oauth2"], ["Tumblr", "tumblr"]] unless prefs.has_key? :omniauth_provider
  end
  prefs[:authorization] = multiple_choice "Authorization?", [["None", "none"], ["Simple role-based", "roles"], ["Pundit", "pundit"]] unless prefs.has_key? :authorization
  if prefer :authentication, 'devise'
    if (prefer :authorization, 'roles') || (prefer :authorization, 'pundit')
      prefs[:dashboard] = multiple_choice "Admin interface for database?", [["None", "none"],
        ["Thoughtbot Administrate", "administrate"]] unless prefs.has_key? :dashboard
    end
  end
end

## Form Builder
## (no simple_form for Bootstrap 4 yet)
unless prefs[:frontend] == 'bootstrap4'
  prefs[:form_builder] = multiple_choice "Use a form builder gem?", [["None", "none"], ["SimpleForm", "simple_form"]] unless prefs.has_key? :form_builder
end

## Pages
if recipes.include? 'pages'
  prefs[:pages] = multiple_choice "Add pages?", [["None", "none"],
    ["Home", "home"], ["Home and About", "about"],
    ["Home and Users", "users"],
    ["Home, About, and Users", "about+users"]] unless prefs.has_key? :pages
end

## Bootstrap Page Templates
if recipes.include? 'pages'
  if prefs[:frontend] == 'bootstrap3'
    say_wizard "Which Bootstrap page template? Visit startbootstrap.com."
    prefs[:layouts] = multiple_choice "Add Bootstrap page templates?", [["None", "none"]] unless prefs.has_key? :layouts
  end
end

# save configuration before anything can fail
create_file 'config/railscomposer.yml', "# This application was generated with Rails Composer\n\n"
append_to_file 'config/railscomposer.yml' do <<-TEXT
development:
  apps4: #{prefs[:apps4]}
  announcements: #{prefs[:announcements]}
  dev_webserver: #{prefs[:dev_webserver]}
  prod_webserver: #{prefs[:prod_webserver]}
  database: #{prefs[:database]}
  templates: #{prefs[:templates]}
  tests: #{prefs[:tests]}
  continuous_testing: #{prefs[:continuous_testing]}
  frontend: #{prefs[:frontend]}
  email: #{prefs[:email]}
  authentication: #{prefs[:authentication]}
  devise_modules: #{prefs[:devise_modules]}
  omniauth_provider: #{prefs[:omniauth_provider]}
  authorization: #{prefs[:authorization]}
  form_builder: #{prefs[:form_builder]}
  pages: #{prefs[:pages]}
  layouts: #{prefs[:layouts]}
  locale: #{prefs[:locale]}
  analytics: #{prefs[:analytics]}
  deployment: #{prefs[:deployment]}
  ban_spiders: #{prefs[:ban_spiders]}
  github: #{prefs[:github]}
  local_env_file: #{prefs[:local_env_file]}
  better_errors: #{prefs[:better_errors]}
  pry: #{prefs[:pry]}
  rvmrc: #{prefs[:rvmrc]}
  dashboard: #{prefs[:dashboard]}
TEXT
end
# >---------------------------- recipes/setup.rb -----------------------------end<
# >-------------------------- templates/recipe.erb ---------------------------end<

# >-------------------------- templates/recipe.erb ---------------------------start<
# >--------------------------------[ locale ]---------------------------------<
@current_recipe = "locale"
@before_configs["locale"].call if @before_configs["locale"]
say_recipe 'locale'
@configs[@current_recipe] = config
# >---------------------------- recipes/locale.rb ----------------------------start<

# Application template recipe for the rails_apps_composer. Change the recipe here:
# https://github.com/RailsApps/rails_apps_composer/blob/master/recipes/locale.rb

prefs[:locale] = 'none'

stage_two do
end
# >---------------------------- recipes/locale.rb ----------------------------end<
# >-------------------------- templates/recipe.erb ---------------------------end<

# >-------------------------- templates/recipe.erb ---------------------------start<
# >--------------------------------[ readme ]---------------------------------<
@current_recipe = "readme"
@before_configs["readme"].call if @before_configs["readme"]
say_recipe 'readme'
@configs[@current_recipe] = config
# >---------------------------- recipes/readme.rb ----------------------------start<

# Application template recipe for the rails_apps_composer. Change the recipe here:
# https://github.com/RailsApps/rails_apps_composer/blob/master/recipes/readme.rb

stage_three do
  say_wizard "recipe stage three"

  # remove default READMEs
  %w{
    README
    README.rdoc
    doc/README_FOR_APP
  }.each { |file| remove_file file }


  remove_file 'README.md'
  create_file 'README.md', "#{app_name.humanize.titleize}\n================\n\n"

  if prefer :deployment, 'heroku'
    append_to_file 'README.md' do <<-TEXT
[![Deploy to Heroku](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy)

TEXT
    end
  end

  append_to_file 'README.md' do <<-TEXT

Ruby on Rails
-------------

This application requires:

- Ruby #{RUBY_VERSION}
- Rails #{Rails::VERSION::STRING}

Learn more about [Installing Rails](http://railsapps.github.io/installing-rails.html).

Getting Started
---------------

Documentation and Support
-------------------------

Issues
-------------

License
-------
TEXT
  end

  git :add => '-A' if prefer :git, true
  git :commit => '-qm "rails_apps_composer: add README files"' if prefer :git, true

end
# >---------------------------- recipes/readme.rb ----------------------------end<

# >-------------------------- templates/recipe.erb ---------------------------start<
# >---------------------------------[ gems ]----------------------------------<
@current_recipe = "gems"
@before_configs["gems"].call if @before_configs["gems"]
say_recipe 'gems'
@configs[@current_recipe] = config
# >----------------------------- recipes/gems.rb -----------------------------start<

# Application template recipe for the rails_apps_composer. Change the recipe here:
# https://github.com/RailsApps/rails_apps_composer/blob/master/recipes/gems.rb

### GEMFILE ###

## Ruby on Rails
insert_into_file('Gemfile', "ruby '#{RUBY_VERSION}'\n", :before => /^ *gem 'rails'/, :force => false)

## Cleanup
# remove the 'sdoc' gem
if Rails::VERSION::MAJOR == 4 && Rails::VERSION::MINOR >= 2
  gsub_file 'Gemfile', /gem 'sdoc',\s+'~> 0.4.0',\s+group: :doc/, ''
else
  gsub_file 'Gemfile', /group :doc do/, ''
  gsub_file 'Gemfile', /\s*gem 'sdoc', require: false\nend/, ''
end

## Web Server
if (prefs[:dev_webserver] == prefs[:prod_webserver])
  add_gem 'thin' if prefer :dev_webserver, 'thin'
  add_gem 'unicorn' if prefer :dev_webserver, 'unicorn'
  add_gem 'unicorn-rails' if prefer :dev_webserver, 'unicorn'
  add_gem 'passenger' if prefer :dev_webserver, 'passenger_standalone'
else
  add_gem 'thin', :group => [:development, :test] if prefer :dev_webserver, 'thin'
  add_gem 'unicorn', :group => [:development, :test] if prefer :dev_webserver, 'unicorn'
  add_gem 'unicorn-rails', :group => [:development, :test] if prefer :dev_webserver, 'unicorn'
  add_gem 'passenger', :group => [:development, :test] if prefer :dev_webserver, 'passenger_standalone'
  add_gem 'thin', :group => :production if prefer :prod_webserver, 'thin'
  add_gem 'unicorn', :group => :production if prefer :prod_webserver, 'unicorn'
  add_gem 'passenger', :group => :production if prefer :prod_webserver, 'passenger_standalone'
end

## Database Adapter
gsub_file 'Gemfile', /gem 'sqlite3'\n/, '' unless prefer :database, 'sqlite'
gsub_file 'Gemfile', /gem 'pg'.*/, ''
add_gem 'pg' if prefer :database, 'postgresql'
gsub_file 'Gemfile', /gem 'mysql2'.*/, ''
add_gem 'mysql2', '~> 0.3.18' if prefer :database, 'mysql'

## Gem to set up controllers, views, and routing in the 'apps4' recipe
add_gem 'rails_apps_pages', :group => :development if prefs[:apps4]

## Template Engine
if prefer :templates, 'slim'
  add_gem 'slim-rails'
  add_gem 'html2haml', :group => :development
  add_gem 'haml2slim', :group => :development
end

## Testing Framework
if prefer :tests, 'rspec'
  add_gem 'rspec-rails', :group => [:development, :test]
  add_gem 'spring-commands-rspec', :group => :development
  add_gem 'factory_girl_rails', :group => [:development, :test]
  add_gem 'faker', :group => [:development, :test]
  add_gem 'capybara', :group => :test
  add_gem 'database_cleaner', :group => :test
  add_gem 'pry-byebug', :group => :test
  if prefer :continuous_testing, 'guard'
    add_gem 'guard-bundler', :group => :development
    add_gem 'guard-rails', :group => :development
    add_gem 'guard-rspec', :group => :development
    add_gem 'rb-inotify', :group => :development, :require => false
    add_gem 'rb-fsevent', :group => :development, :require => false
    add_gem 'rb-fchange', :group => :development, :require => false
  end
end

## Front-end Framework
add_gem 'rails_layout', :group => :development
case prefs[:frontend]
  when 'bootstrap3'
    add_gem 'bootstrap-sass'
  when 'bootstrap4'
    add_gem 'bootstrap', '~> 4.0.0.alpha3.1'
  when 'foundation5'
    add_gem 'foundation-rails', '~> 5.5'
end

## Pages
case prefs[:pages]
  when 'about'
    add_gem 'high_voltage'
  when 'about+users'
    add_gem 'high_voltage'
end

## Authentication (Devise)
if prefer :authentication, 'devise'
    add_gem 'devise'
    add_gem 'devise_invitable' if prefer :devise_modules, 'invitable'
end

## Administratative Interface
if prefer :dashboard, 'administrate'
  add_gem 'administrate'
  add_gem 'bourbon'
end

## Authentication (OmniAuth)
add_gem 'omniauth' if prefer :authentication, 'omniauth'
add_gem 'omniauth-twitter' if prefer :omniauth_provider, 'twitter'
add_gem 'omniauth-facebook' if prefer :omniauth_provider, 'facebook'
add_gem 'omniauth-github' if prefer :omniauth_provider, 'github'
add_gem 'omniauth-linkedin' if prefer :omniauth_provider, 'linkedin'
add_gem 'omniauth-google-oauth2' if prefer :omniauth_provider, 'google_oauth2'
add_gem 'omniauth-tumblr' if prefer :omniauth_provider, 'tumblr'

## Authorization
add_gem 'pundit' if prefer :authorization, 'pundit'

## Form Builder
add_gem 'simple_form' if prefer :form_builder, 'simple_form'

## Gems from a defaults file or added interactively
gems.each do |g|
  add_gem(*g)
end

## Git
git :add => '-A' if prefer :git, true
git :commit => '-qm "rails_apps_composer: Gemfile"' if prefer :git, true

### CREATE DATABASE ###
stage_two do
  say_wizard "recipe stage two"
  say_wizard "configuring database"
  unless prefer :database, 'sqlite'
    copy_from_repo 'config/database-postgresql.yml', :prefs => 'postgresql'
    copy_from_repo 'config/database-mysql.yml', :prefs => 'mysql'
    if prefer :database, 'postgresql'
      begin
        pg_username = prefs[:pg_username] || ask_wizard("Username for PostgreSQL?(leave blank to use the app name)")
        pg_host = prefs[:pg_host] || ask_wizard("Host for PostgreSQL in database.yml? (leave blank to use default socket connection)")
        if pg_username.blank?
          say_wizard "Creating a user named '#{app_name}' for PostgreSQL"
          run "createuser --createdb #{app_name}" if prefer :database, 'postgresql'
          gsub_file "config/database.yml", /username: .*/, "username: #{app_name}"
        else
          gsub_file "config/database.yml", /username: .*/, "username: #{pg_username}"
          pg_password = prefs[:pg_password] || ask_wizard("Password for PostgreSQL user #{pg_username}?")
          gsub_file "config/database.yml", /password:/, "password: #{pg_password}"
          say_wizard "set config/database.yml for username/password #{pg_username}/#{pg_password}"
        end
        if pg_host.present?
          gsub_file "config/database.yml", /  host:     localhost/, "  host:     #{pg_host}"
        end
      rescue StandardError => e
        raise "unable to create a user for PostgreSQL, reason: #{e}"
      end
      gsub_file "config/database.yml", /database: myapp_development/, "database: #{app_name}_development"
      gsub_file "config/database.yml", /database: myapp_test/,        "database: #{app_name}_test"
      gsub_file "config/database.yml", /database: myapp_production/,  "database: #{app_name}_production"
    end
    if prefer :database, 'mysql'
      mysql_username = prefs[:mysql_username] || ask_wizard("Username for MySQL? (leave blank to use the app name)")
      if mysql_username.blank?
        gsub_file "config/database.yml", /username: .*/, "username: #{app_name}"
      else
        gsub_file "config/database.yml", /username: .*/, "username: #{mysql_username}"
        mysql_password = prefs[:mysql_password] || ask_wizard("Password for MySQL user #{mysql_username}?")
        gsub_file "config/database.yml", /password:/, "password: #{mysql_password}"
        say_wizard "set config/database.yml for username/password #{mysql_username}/#{mysql_password}"
      end
      gsub_file "config/database.yml", /database: myapp_development/, "database: #{app_name}_development"
      gsub_file "config/database.yml", /database: myapp_test/,        "database: #{app_name}_test"
      gsub_file "config/database.yml", /database: myapp_production/,  "database: #{app_name}_production"
    end
    unless prefer :database, 'sqlite'
      if (prefs.has_key? :drop_database) ? prefs[:drop_database] :
          (yes_wizard? "Okay to drop all existing databases named #{app_name}? 'No' will abort immediately!")
        run 'bundle exec rake db:drop'
      else
        raise "aborted at user's request"
      end
    end
    run 'bundle exec rake db:create:all'
    ## Git
    git :add => '-A' if prefer :git, true
    git :commit => '-qm "rails_apps_composer: create database"' if prefer :git, true
  end
end

### GENERATORS ###
stage_two do
  say_wizard "recipe stage two"
  say_wizard "running generators"
  ## Form Builder
  if prefer :form_builder, 'simple_form'
    case prefs[:frontend]
      when 'bootstrap3'
        say_wizard "recipe installing simple_form for use with Bootstrap"
        generate 'simple_form:install --bootstrap'
      when 'bootstrap4'
        say_wizard "simple_form not yet available for use with Bootstrap 4"
      when 'foundation5'
        say_wizard "recipe installing simple_form for use with Zurb Foundation"
        generate 'simple_form:install --foundation'
      else
        say_wizard "recipe installing simple_form"
        generate 'simple_form:install'
    end
  end
  ## Figaro Gem
  if prefer :local_env_file, 'figaro'
    run 'figaro install'
    gsub_file 'config/application.yml', /# PUSHER_.*\n/, ''
    gsub_file 'config/application.yml', /# STRIPE_.*\n/, ''
    prepend_to_file 'config/application.yml' do <<-FILE
# Add account credentials and API keys here.
# See http://railsapps.github.io/rails-environment-variables.html
# This file should be listed in .gitignore to keep your settings secret!
# Each entry sets a local environment variable.
# For example, setting:
# GMAIL_USERNAME: Your_Gmail_Username
# makes 'Your_Gmail_Username' available as ENV["GMAIL_USERNAME"]

FILE
    end
  end
  ## Foreman Gem
  if prefer :local_env_file, 'foreman'
    create_file '.env' do <<-FILE
# Add account credentials and API keys here.
# This file should be listed in .gitignore to keep your settings secret!
# Each entry sets a local environment variable.
# For example, setting:
# GMAIL_USERNAME=Your_Gmail_Username
# makes 'Your_Gmail_Username' available as ENV["GMAIL_USERNAME"]

FILE
    end
    create_file 'Procfile', "web: bundle exec rails server -p $PORT\n" if prefer :prod_webserver, 'thin'
    create_file 'Procfile', "web: bundle exec unicorn -p $PORT\n" if prefer :prod_webserver, 'unicorn'
    create_file 'Procfile', "web: bundle exec passenger start -p $PORT\n" if prefer :prod_webserver, 'passenger_standalone'
    if (prefs[:dev_webserver] != prefs[:prod_webserver])
      create_file 'Procfile.dev', "web: bundle exec rails server -p $PORT\n" if prefer :dev_webserver, 'thin'
      create_file 'Procfile.dev', "web: bundle exec unicorn -p $PORT\n" if prefer :dev_webserver, 'unicorn'
      create_file 'Procfile.dev', "web: bundle exec passenger start -p $PORT\n" if prefer :dev_webserver, 'passenger_standalone'
    end
  end
  ## Git
  git :add => '-A' if prefer :git, true
  git :commit => '-qm "rails_apps_composer: generators"' if prefer :git, true
end
# >----------------------------- recipes/gems.rb -----------------------------end<

# >-------------------------- templates/recipe.erb ---------------------------start<
# >---------------------------------[ tests ]---------------------------------<
@current_recipe = "tests"
@before_configs["tests"].call if @before_configs["tests"]
say_recipe 'tests'
@configs[@current_recipe] = config
# >---------------------------- recipes/tests.rb -----------------------------start<

# Application template recipe for the rails_apps_composer. Change the recipe here:
# https://github.com/RailsApps/rails_apps_composer/blob/master/recipes/tests.rb

stage_two do
  say_wizard "recipe stage two"
  if prefer :tests, 'rspec'
    say_wizard "recipe installing RSpec"
    generate 'testing:configure rspec -f'
  end
  if prefer :continuous_testing, 'guard'
    say_wizard "recipe initializing Guard"
    run 'bundle exec guard init'
  end
  git :add => '-A' if prefer :git, true
  git :commit => '-qm "rails_apps_composer: testing framework"' if prefer :git, true
end

stage_three do
  say_wizard "recipe stage three"
  if prefer :tests, 'rspec'
    if prefer :authentication, 'devise'
      generate 'testing:configure devise -f'
      if (prefer :devise_modules, 'confirmable') || (prefer :devise_modules, 'invitable')
        inject_into_file 'spec/factories/users.rb', "    confirmed_at Time.now\n", :after => "factory :user do\n"
        default_url = '  config.action_mailer.default_url_options = { :host => Rails.application.secrets.domain_name }'
        inject_into_file 'config/environments/test.rb', default_url, :after => "delivery_method = :test\n"
        gsub_file 'spec/features/users/user_edit_spec.rb', /successfully./, 'successfully,'
        gsub_file 'spec/features/visitors/sign_up_spec.rb', /Welcome! You have signed up successfully./, 'A message with a confirmation'
      end
    end
    if prefer :authentication, 'omniauth'
      generate 'testing:configure omniauth -f'
    end
    if (prefer :authorization, 'roles') || (prefer :authorization, 'pundit')
      generate 'testing:configure pundit -f'
      remove_file 'spec/policies/user_policy_spec.rb' unless %w(users about+users).include?(prefs[:pages])
      remove_file 'spec/policies/user_policy_spec.rb' if prefer :authorization, 'roles'
      remove_file 'spec/support/pundit.rb' if prefer :authorization, 'roles'
      if (prefer :authentication, 'devise') &&\
        ((prefer :devise_modules, 'confirmable') || (prefer :devise_modules, 'invitable'))
        inject_into_file 'spec/factories/users.rb', "    confirmed_at Time.now\n", :after => "factory :user do\n"
      end
    end
    unless %w(users about+users).include?(prefs[:pages])
      remove_file 'spec/features/users/user_index_spec.rb'
      remove_file 'spec/features/users/user_show_spec.rb'
    end
  end
end
# >---------------------------- recipes/tests.rb -----------------------------end<

# >-------------------------- templates/recipe.erb ---------------------------start<
# >---------------------------------[ email ]---------------------------------<
@current_recipe = "email"
@before_configs["email"].call if @before_configs["email"]
say_recipe 'email'
@configs[@current_recipe] = config
# >---------------------------- recipes/email.rb -----------------------------start<

# Application template recipe for the rails_apps_composer. Change the recipe here:
# https://github.com/RailsApps/rails_apps_composer/blob/master/recipes/email.rb

stage_two do
  say_wizard "recipe stage two"
  unless prefer :email, 'none'
    ## ACTIONMAILER CONFIG
    dev_email_text = <<-TEXT
  # ActionMailer Config
  config.action_mailer.default_url_options = { :host => 'localhost:3000' }
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.raise_delivery_errors = true
  # Send email in development mode?
  config.action_mailer.perform_deliveries = true
TEXT
    prod_email_text = <<-TEXT
  # ActionMailer Config
  config.action_mailer.default_url_options = { :host => 'example.com' }
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = false
TEXT
    inject_into_file 'config/environments/development.rb', dev_email_text, :after => "config.assets.debug = true"
    inject_into_file 'config/environments/production.rb', prod_email_text, :after => "config.active_support.deprecation = :notify"
    gsub_file 'config/environments/production.rb', /'example.com'/, 'Rails.application.secrets.domain_name'
    ## SMTP_SETTINGS
    email_configuration_text = <<-TEXT
\n
  config.action_mailer.smtp_settings = {
    address: "smtp.gmail.com",
    port: 587,
    domain: Rails.application.secrets.domain_name,
    authentication: "plain",
    enable_starttls_auto: true,
    user_name: Rails.application.secrets.email_provider_username,
    password: Rails.application.secrets.email_provider_password
  }
TEXT
    inject_into_file 'config/environments/development.rb', email_configuration_text, :after => "config.assets.debug = true"
    inject_into_file 'config/environments/production.rb', email_configuration_text, :after => "config.active_support.deprecation = :notify"
    case prefs[:email]
      when 'sendgrid'
        gsub_file 'config/environments/development.rb', /smtp.gmail.com/, 'smtp.sendgrid.net'
        gsub_file 'config/environments/production.rb', /smtp.gmail.com/, 'smtp.sendgrid.net'
      when 'mandrill'
        gsub_file 'config/environments/development.rb', /smtp.gmail.com/, 'smtp.mandrillapp.com'
        gsub_file 'config/environments/production.rb', /smtp.gmail.com/, 'smtp.mandrillapp.com'
        gsub_file 'config/environments/development.rb', /email_provider_password/, 'email_provider_apikey'
        gsub_file 'config/environments/production.rb', /email_provider_password/, 'email_provider_apikey'
    end
  end
  ### GIT
  git :add => '-A' if prefer :git, true
  git :commit => '-qm "rails_apps_composer: set email accounts"' if prefer :git, true
end
# >---------------------------- recipes/email.rb -----------------------------end<

# >-------------------------- templates/recipe.erb ---------------------------start<
# >--------------------------------[ devise ]---------------------------------<
@current_recipe = "devise"
@before_configs["devise"].call if @before_configs["devise"]
say_recipe 'devise'
@configs[@current_recipe] = config
# >---------------------------- recipes/devise.rb ----------------------------start<

# Application template recipe for the rails_apps_composer. Change the recipe here:
# https://github.com/RailsApps/rails_apps_composer/blob/master/recipes/devise.rb

stage_two do
  say_wizard "recipe stage two"
  if prefer :authentication, 'devise'
    # prevent logging of password_confirmation
    gsub_file 'config/initializers/filter_parameter_logging.rb', /:password/, ':password, :password_confirmation'
    generate 'devise:install'
    generate 'devise_invitable:install' if prefer :devise_modules, 'invitable'
    generate 'devise user' # create the User model
    unless :apps4.to_s.include? 'rails-stripe-'
      generate 'migration AddNameToUsers name:string'
    end
    if (prefer :devise_modules, 'confirmable') || (prefer :devise_modules, 'invitable')
      gsub_file 'app/models/user.rb', /:registerable,/, ":registerable, :confirmable,"
      generate 'migration AddConfirmableToUsers confirmation_token:string confirmed_at:datetime confirmation_sent_at:datetime unconfirmed_email:string'
    end
    run 'bundle exec rake db:migrate'
  end
  ### GIT ###
  git :add => '-A' if prefer :git, true
  git :commit => '-qm "rails_apps_composer: devise"' if prefer :git, true
end
# >---------------------------- recipes/devise.rb ----------------------------end<
# >-------------------------- templates/recipe.erb ---------------------------end<

# >-------------------------- templates/recipe.erb ---------------------------start<
# >-------------------------------[ omniauth ]--------------------------------<
@current_recipe = "omniauth"
@before_configs["omniauth"].call if @before_configs["omniauth"]
say_recipe 'omniauth'
@configs[@current_recipe] = config
# >--------------------------- recipes/omniauth.rb ---------------------------start<

# Application template recipe for the rails_apps_composer. Change the recipe here:
# https://github.com/RailsApps/rails_apps_composer/blob/master/recipes/omniauth.rb

stage_two do
  say_wizard "recipe stage two"
  if prefer :authentication, 'omniauth'
    repo = 'https://raw.github.com/RailsApps/rails-omniauth/master/'
    copy_from_repo 'config/initializers/omniauth.rb', :repo => repo
    gsub_file 'config/initializers/omniauth.rb', /twitter/, prefs[:omniauth_provider] unless prefer :omniauth_provider, 'twitter'
    generate 'model User name:string provider:string uid:string'
    run 'bundle exec rake db:migrate'
    copy_from_repo 'app/models/user.rb', :repo => 'https://raw.github.com/RailsApps/rails-omniauth/master/'
    copy_from_repo 'app/controllers/application_controller.rb', :repo => repo
    filename = 'app/controllers/sessions_controller.rb'
    copy_from_repo filename, :repo => repo
    gsub_file filename, /twitter/, prefs[:omniauth_provider] unless prefer :omniauth_provider, 'twitter'
    routes = <<-TEXT
  get '/auth/:provider/callback' => 'sessions#create'
  get '/signin' => 'sessions#new', :as => :signin
  get '/signout' => 'sessions#destroy', :as => :signout
  get '/auth/failure' => 'sessions#failure'
TEXT
    inject_into_file 'config/routes.rb', routes + "\n", :after => "routes.draw do\n"
  end
  ### GIT ###
  git :add => '-A' if prefer :git, true
  git :commit => '-qm "rails_apps_composer: omniauth"' if prefer :git, true
end
# >--------------------------- recipes/omniauth.rb ---------------------------end<

# >-------------------------- templates/recipe.erb ---------------------------start<
# >---------------------------------[ roles ]---------------------------------<
@current_recipe = "roles"
@before_configs["roles"].call if @before_configs["roles"]
say_recipe 'roles'
@configs[@current_recipe] = config
# >---------------------------- recipes/roles.rb -----------------------------start<

# Application template recipe for the rails_apps_composer. Change the recipe here:
# https://github.com/RailsApps/rails_apps_composer/blob/master/recipes/roles.rb

stage_two do
  say_wizard "recipe stage two"
  if (prefer :authorization, 'roles') || (prefer :authorization, 'pundit')
    if prefer :authentication, 'none'
      generate 'model User email:string'
      run 'bundle exec rake db:migrate'
    end
    generate 'migration AddRoleToUsers role:integer'
    role_boilerplate = "  enum role: [:user, :vip, :admin]\n  after_initialize :set_default_role, :if => :new_record?\n\n"
    role_boilerplate << "  def set_default_role\n    self.role ||= :user\n  end\n\n" if prefer :authentication, 'devise'
    if prefer :authentication, 'omniauth'
      role_boilerplate << <<-RUBY
  def set_default_role
    if User.count == 0
      self.role ||= :admin
    else
      self.role ||= :user
    end
  end
RUBY
    end
    inject_into_class 'app/models/user.rb', 'User', role_boilerplate
  end
  ### GIT ###
  git :add => '-A' if prefer :git, true
  git :commit => '-qm "rails_apps_composer: add roles to a User model"' if prefer :git, true
end
# >---------------------------- recipes/roles.rb -----------------------------end<

# >-------------------------- templates/recipe.erb ---------------------------start<
# >-------------------------------[ frontend ]--------------------------------<
@current_recipe = "frontend"
@before_configs["frontend"].call if @before_configs["frontend"]
say_recipe 'frontend'
@configs[@current_recipe] = config
# >--------------------------- recipes/frontend.rb ---------------------------start<

# Application template recipe for the rails_apps_composer. Change the recipe here:
# https://github.com/RailsApps/rails_apps_composer/blob/master/recipes/frontend.rb

stage_two do
  say_wizard "recipe stage two"
  # set up a front-end framework using the rails_layout gem
  case prefs[:frontend]
    when 'simple'
      generate 'layout:install simple -f'
    when 'bootstrap3'
      generate 'layout:install bootstrap3 -f'
    when 'bootstrap4'
      generate 'layout:install bootstrap4 -f'
    when 'foundation5'
      generate 'layout:install foundation5 -f'
  end

  ### GIT ###
  git :add => '-A' if prefer :git, true
  git :commit => '-qm "rails_apps_composer: front-end framework"' if prefer :git, true
end
# >--------------------------- recipes/frontend.rb ---------------------------end<

# >-------------------------- templates/recipe.erb ---------------------------start<
# >---------------------------------[ init ]----------------------------------<
@current_recipe = "init"
@before_configs["init"].call if @before_configs["init"]
say_recipe 'init'
@configs[@current_recipe] = config
# >----------------------------- recipes/init.rb -----------------------------start<

# Application template recipe for the rails_apps_composer. Change the recipe here:
# https://github.com/RailsApps/rails_apps_composer/blob/master/recipes/init.rb

stage_three do
  say_wizard "recipe stage three"
  if (!prefs[:secrets].nil?)
    prefs[:secrets].each do |secret|
      env_var = "  #{secret}: <%= ENV[\"#{secret.upcase}\"] %>"
      inject_into_file 'config/secrets.yml', "\n" + env_var, :after => "development:"
      ### 'inject_into_file' doesn't let us inject the same text twice unless we append the extra space, why?
      inject_into_file 'config/secrets.yml', "\n" + env_var + " ", :after => "production:"
    end
  end
  case prefs[:email]
    when 'none'
      secrets_email = foreman_email = ''
    when 'smtp'
      secrets_email = foreman_email = ''
    when 'gmail'
      secrets_email = "  email_provider_username: <%= ENV[\"GMAIL_USERNAME\"] %>\n  email_provider_password: <%= ENV[\"GMAIL_PASSWORD\"] %>"
      foreman_email = "GMAIL_USERNAME=Your_Username\nGMAIL_PASSWORD=Your_Password\nDOMAIN_NAME=example.com\n"
    when 'sendgrid'
      secrets_email = "  email_provider_username: <%= ENV[\"SENDGRID_USERNAME\"] %>\n  email_provider_password: <%= ENV[\"SENDGRID_PASSWORD\"] %>"
      foreman_email = "SENDGRID_USERNAME=Your_Username\nSENDGRID_PASSWORD=Your_Password\nDOMAIN_NAME=example.com\n"
    when 'mandrill'
      secrets_email = "  email_provider_username: <%= ENV[\"MANDRILL_USERNAME\"] %>\n  email_provider_apikey: <%= ENV[\"MANDRILL_APIKEY\"] %>"
      foreman_email = "MANDRILL_USERNAME=Your_Username\nMANDRILL_APIKEY=Your_API_Key\nDOMAIN_NAME=example.com\n"
  end
  figaro_email  = foreman_email.gsub('=', ': ')
  secrets_d_devise = "  admin_name: First User\n  admin_email: user@example.com\n  admin_password: changeme"
  secrets_p_devise = "  admin_name: <%= ENV[\"ADMIN_NAME\"] %>\n  admin_email: <%= ENV[\"ADMIN_EMAIL\"] %>\n  admin_password: <%= ENV[\"ADMIN_PASSWORD\"] %>"
  foreman_devise = "ADMIN_NAME=First User\nADMIN_EMAIL=user@example.com\nADMIN_PASSWORD=changeme\n"
  figaro_devise  = foreman_devise.gsub('=', ': ')
  secrets_omniauth = "  omniauth_provider_key: <%= ENV[\"OMNIAUTH_PROVIDER_KEY\"] %>\n  omniauth_provider_secret: <%= ENV[\"OMNIAUTH_PROVIDER_SECRET\"] %>"
  foreman_omniauth = "OMNIAUTH_PROVIDER_KEY=Your_Provider_Key\nOMNIAUTH_PROVIDER_SECRET=Your_Provider_Secret\n"
  figaro_omniauth  = foreman_omniauth.gsub('=', ': ')
  ## EMAIL
  inject_into_file 'config/secrets.yml', "\n" + "  domain_name: example.com", :after => "development:"
  inject_into_file 'config/secrets.yml', "\n" + "  domain_name: <%= ENV[\"DOMAIN_NAME\"] %>", :after => "production:"
  inject_into_file 'config/secrets.yml', "\n" + secrets_email, :after => "development:"
  unless prefer :email, 'none'
    ### 'inject_into_file' doesn't let us inject the same text twice unless we append the extra space, why?
    inject_into_file 'config/secrets.yml', "\n" + secrets_email + " ", :after => "production:"
    append_file '.env', foreman_email if prefer :local_env_file, 'foreman'
    append_file 'config/application.yml', figaro_email if prefer :local_env_file, 'figaro'
  end
  ## DEVISE
  if prefer :authentication, 'devise'
    inject_into_file 'config/secrets.yml', "\n" + '  domain_name: example.com' + " ", :after => "test:"
    inject_into_file 'config/secrets.yml', "\n" + secrets_d_devise, :after => "development:"
    inject_into_file 'config/secrets.yml', "\n" + secrets_p_devise, :after => "production:"
    append_file '.env', foreman_devise if prefer :local_env_file, 'foreman'
    append_file 'config/application.yml', figaro_devise if prefer :local_env_file, 'figaro'
    gsub_file 'config/initializers/devise.rb', /'please-change-me-at-config-initializers-devise@example.com'/, "'no-reply@' + Rails.application.secrets.domain_name"
  end
  ## OMNIAUTH
  if prefer :authentication, 'omniauth'
    inject_into_file 'config/secrets.yml', "\n" + secrets_omniauth, :after => "development:"
    ### 'inject_into_file' doesn't let us inject the same text twice unless we append the extra space, why?
    inject_into_file 'config/secrets.yml', "\n" + secrets_omniauth + " ", :after => "production:"
    append_file '.env', foreman_omniauth if prefer :local_env_file, 'foreman'
    append_file 'config/application.yml', figaro_omniauth if prefer :local_env_file, 'figaro'
  end
  ### EXAMPLE FILE FOR FOREMAN AND FIGARO ###
  if prefer :local_env_file, 'figaro'
    copy_file destination_root + '/config/application.yml', destination_root + '/config/application.example.yml'
  elsif prefer :local_env_file, 'foreman'
    copy_file destination_root + '/.env', destination_root + '/.env.example'
  end
  ### DATABASE SEED ###
  if prefer :authentication, 'devise'
    copy_from_repo 'db/seeds.rb', :repo => 'https://raw.github.com/RailsApps/rails-devise/master/'
    if prefer :authorization, 'roles'
      copy_from_repo 'app/services/create_admin_service.rb', :repo => 'https://raw.github.com/RailsApps/rails-devise-roles/master/'
    elsif prefer :authorization, 'pundit'
      copy_from_repo 'app/services/create_admin_service.rb', :repo => 'https://raw.github.com/RailsApps/rails-devise-pundit/master/'
    else
      copy_from_repo 'app/services/create_admin_service.rb', :repo => 'https://raw.github.com/RailsApps/rails-devise/master/'
    end
  end
  if prefer :local_env_file, 'figaro'
    append_file 'db/seeds.rb' do <<-FILE
# Environment variables (ENV['...']) can be set in the file config/application.yml.
# See http://railsapps.github.io/rails-environment-variables.html
FILE
    end
  elsif prefer :local_env_file, 'foreman'
    append_file 'db/seeds.rb' do <<-FILE
# Environment variables (ENV['...']) can be set in the file .env file.
FILE
    end
  end
  ## DEVISE-CONFIRMABLE
  if (prefer :devise_modules, 'confirmable') || (prefer :devise_modules, 'invitable')
    inject_into_file 'app/services/create_admin_service.rb', "        user.confirm!\n", :after => "user.password_confirmation = Rails.application.secrets.admin_password\n"
  end
  ## DEVISE-INVITABLE
  if prefer :devise_modules, 'invitable'
    if prefer :local_env_file, 'foreman'
      run 'foreman run bundle exec rake db:migrate'
    else
      run 'bundle exec rake db:migrate'
    end
    generate 'devise_invitable user'
  end
  ### APPLY DATABASE SEED ###
  if File.exists?('db/migrate')
    ## ACTIVE_RECORD
    say_wizard "applying migrations and seeding the database"
    if prefer :local_env_file, 'foreman'
      run 'foreman run bundle exec rake db:migrate'
    else
      run 'bundle exec rake db:migrate'
    end
  end
  unless prefs[:skip_seeds]
    if prefer :local_env_file, 'foreman'
      run 'foreman run bundle exec rake db:seed'
    else
      run 'bundle exec rake db:seed'
    end
  end
  ### GIT ###
  git :add => '-A' if prefer :git, true
  git :commit => '-qm "rails_apps_composer: set up database"' if prefer :git, true
  ### FRONTEND (must run after database migrations) ###
  # generate Devise views with appropriate styling
  if prefer :authentication, 'devise'
    case prefs[:frontend]
      when 'bootstrap3'
        generate 'layout:devise bootstrap3 -f'
      when 'bootstrap4'
        generate 'layout:devise bootstrap3 -f'
      when 'foundation5'
        generate 'layout:devise foundation5 -f'
    end
  end
  # create navigation links using the rails_layout gem
  if prefs[:frontend] == 'bootstrap4'
    generate 'layout:navigation bootstrap4 -f'
  else
    generate 'layout:navigation -f'
  end
  ### GIT ###
  git :add => '-A' if prefer :git, true
  git :commit => '-qm "rails_apps_composer: navigation links"' if prefer :git, true
end
# >----------------------------- recipes/init.rb -----------------------------end<

# >-------------------------- templates/recipe.erb ---------------------------start<
# >-------------------------------[ analytics ]-------------------------------<
@current_recipe = "analytics"
@before_configs["analytics"].call if @before_configs["analytics"]
say_recipe 'analytics'
@configs[@current_recipe] = config
# >-------------------------- recipes/analytics.rb ---------------------------start<
# https://github.com/RailsApps/rails_apps_composer/blob/master/recipes/analytics.rb

prefs[:analytics] = multiple_choice "Install page-view analytics?", [["None", "none"],
  ["Google Analytics", "ga"],
  ["Segment.com", "segmentio"]] unless prefs.has_key? :analytics
case prefs[:analytics]
  when 'ga'
    ga_id = ask_wizard('Google Analytics ID?')
  when 'segmentio'
    segmentio_api_key = ask_wizard('Segment.com Write Key?')
end

stage_two do
  say_wizard "recipe stage two"
  unless prefer :analytics, 'none'
    # don't add the gem if it has already been added by the railsapps recipe
    add_gem 'rails_apps_pages', :group => :development unless prefs[:apps4]
  end
  case prefs[:analytics]
    when 'ga'
      generate 'analytics:google -f'
      gsub_file 'app/assets/javascripts/google_analytics.js.coffee', /UA-XXXXXXX-XX/, ga_id
    when 'segmentio'
      generate 'analytics:segmentio -f'
      gsub_file 'app/assets/javascripts/segmentio.js', /SEGMENTIO_API_KEY/, segmentio_api_key
  end
  ### GIT ###
  git :add => '-A' if prefer :git, true
  git :commit => '-qm "rails_apps_composer: add analytics"' if prefer :git, true
end
# >-------------------------- recipes/analytics.rb ---------------------------end<
# >-------------------------- templates/recipe.erb ---------------------------end<

# >-------------------------- templates/recipe.erb ---------------------------start<
# >------------------------------[ deployment ]-------------------------------<
@current_recipe = "deployment"
@before_configs["deployment"].call if @before_configs["deployment"]
say_recipe 'deployment'
@configs[@current_recipe] = config
# >-------------------------- recipes/deployment.rb --------------------------start<

# Application template recipe for the rails_apps_composer. Change the recipe here:
# https://github.com/RailsApps/rails_apps_composer/blob/master/recipes/deployment.rb

prefs[:deployment] = multiple_choice "Prepare for deployment?", [["no", "none"],
    ["Heroku", "heroku"],
    ["Capistrano", "capistrano3"]] unless prefs.has_key? :deployment

if prefer :deployment, 'heroku'
  say_wizard "installing gems for Heroku"
  if prefer :database, 'sqlite'
    gsub_file 'Gemfile', /.*gem 'sqlite3'\n/, ''
    add_gem 'sqlite3', group: [:development, :test]
    add_gem 'pg', group: :production
  end
end

if prefer :deployment, 'capistrano3'
  say_wizard "installing gems for Capistrano"
  add_gem 'capistrano', '~> 3.0.1', group: :development
  add_gem 'capistrano-rvm', '~> 0.1.1', group: :development
  add_gem 'capistrano-bundler', group: :development
  add_gem 'capistrano-rails', '~> 1.1.0', group: :development
  add_gem 'capistrano-rails-console', group: :development
  stage_two do
    say_wizard "recipe stage two"
    say_wizard "installing Capistrano files"
    run 'bundle exec cap install'
  end
end

stage_three do
  ### GIT ###
  git :add => '-A' if prefer :git, true
  git :commit => '-qm "rails_apps_composer: prepare for deployment"' if prefer :git, true
end
# >-------------------------- recipes/deployment.rb --------------------------end<

# >-------------------------- templates/recipe.erb ---------------------------start<
# >--------------------------------[ extras ]---------------------------------<
@current_recipe = "extras"
@before_configs["extras"].call if @before_configs["extras"]
say_recipe 'extras'
config = {}
config['disable_turbolinks'] = yes_wizard?("Disable Rails Turbolinks?") if true && true unless config.key?('disable_turbolinks') || prefs.has_key?(:disable_turbolinks)
config['ban_spiders'] = yes_wizard?("Set a robots.txt file to ban spiders?") if true && true unless config.key?('ban_spiders') || prefs.has_key?(:ban_spiders)
config['github'] = yes_wizard?("Create a GitHub repository?") if true && true unless config.key?('github') || prefs.has_key?(:github)
config['local_env_file'] = multiple_choice("Add gem and file for environment variables?", [["None", "none"], ["Add .env with Foreman", "foreman"]]) if true && true unless config.key?('local_env_file') || prefs.has_key?(:local_env_file)
config['better_errors'] = yes_wizard?("Improve error reporting with 'better_errors' during development?") if true && true unless config.key?('better_errors') || prefs.has_key?(:better_errors)
config['pry'] = yes_wizard?("Use 'pry' as console replacement during development and test?") if true && true unless config.key?('pry') || prefs.has_key?(:pry)
config['rubocop'] = yes_wizard?("Use 'rubocop' to ensure that your code conforms to the Ruby style guide?") if true && true unless config.key?('rubocop') || prefs.has_key?(:rubocop)
@configs[@current_recipe] = config
# >---------------------------- recipes/extras.rb ----------------------------start<
# https://github.com/RailsApps/rails_apps_composer/blob/master/recipes/extras.rb

## RVMRC
if prefs[:rvmrc]
   if File.exist?('.ruby-version')
     say_wizard ".ruby-version file already exists"
   else
     create_file '.ruby-version', "#{RUBY_VERSION}\n"
   end
   if File.exist?('.ruby-gemset')
     say_wizard ".ruby-gemset file already exists"
   else
     create_file '.ruby-gemset', "#{app_name}\n"
   end
end

## LOCAL_ENV.YML FILE
prefs[:local_env_file] = config['local_env_file'] unless (config['local_env_file'] == 'none')

if prefer :local_env_file, 'figaro'
  say_wizard "recipe creating application.yml file for environment variables with figaro"
  add_gem 'figaro'
elsif prefer :local_env_file, 'foreman'
  say_wizard "recipe creating .env file for development environment variables with foreman"
  add_gem 'foreman', :group => :development
end

## BETTER ERRORS
prefs[:better_errors] = true if config['better_errors']
if prefs[:better_errors]
  say_wizard "recipe adding better_errors gem"
  add_gem 'better_errors', :group => :development
  if RUBY_ENGINE == 'ruby'
    case RUBY_VERSION.split('.')[0] + "." + RUBY_VERSION.split('.')[1]
      when '2.1'
        add_gem 'binding_of_caller', :group => :development, :platforms => [:mri_21]
      when '2.0'
        add_gem 'binding_of_caller', :group => :development, :platforms => [:mri_20]
      when '1.9'
        add_gem 'binding_of_caller', :group => :development, :platforms => [:mri_19]
    end
  end
end

# Pry
prefs[:pry] = true if config['pry']
if prefs[:pry]
  say_wizard "recipe adding pry-rails gem"
  add_gem 'pry-rails', :group => [:development, :test]
  add_gem 'pry-rescue', :group => [:development, :test]
end

## Rubocop
prefs[:rubocop] = true if config['rubocop']
if prefs[:rubocop]
  say_wizard "recipe adding rubocop gem and basic .rubocop.yml"
  add_gem 'rubocop', :group => [:development, :test]
  copy_from_repo '.rubocop.yml'
end

## Disable Turbolinks
if config['disable_turbolinks']
  prefs[:disable_turbolinks] = true
end
if prefs[:disable_turbolinks]
  say_wizard "recipe removing support for Rails Turbolinks"
  stage_two do
    say_wizard "recipe stage two"
    gsub_file 'Gemfile', /gem 'turbolinks'\n/, ''
    gsub_file 'app/assets/javascripts/application.js', "//= require turbolinks\n", ''
    case prefs[:templates]
      when 'erb'
        gsub_file 'app/views/layouts/application.html.erb', /, 'data-turbolinks-track' => true/, ''
      when 'slim'
        gsub_file 'app/views/layouts/application.html.slim', /, 'data-turbolinks-track' => true/, ''
    end
  end
end

## JSRUNTIME
case RbConfig::CONFIG['host_os']
  when /linux/i
    prefs[:jsruntime] = yes_wizard? "Add 'therubyracer' JavaScript runtime (for Linux users without node.js)?" unless prefs.has_key? :jsruntime
    if prefs[:jsruntime]
      say_wizard "recipe adding 'therubyracer' JavaScript runtime gem"
      add_gem 'therubyracer', :platform => :ruby
    end
end

stage_four do
  say_wizard "recipe stage four"
  say_wizard "recipe removing unnecessary files and whitespace"
  %w{
    public/index.html
    app/assets/images/rails.png
  }.each { |file| remove_file file }
  # remove temporary Haml gems from Gemfile when Slim is selected
  if prefer :templates, 'slim'
    gsub_file 'Gemfile', /.*gem 'haml2slim'\n/, "\n"
    gsub_file 'Gemfile', /.*gem 'html2haml'\n/, "\n"
  end
  # remove gems and files used to assist rails_apps_composer
  gsub_file 'Gemfile', /.*gem 'rails_apps_pages'\n/, ''
  gsub_file 'Gemfile', /.*gem 'rails_apps_testing'\n/, ''
  remove_file 'config/railscomposer.yml'
  # remove commented lines and multiple blank lines from Gemfile
  # thanks to https://github.com/perfectline/template-bucket/blob/master/cleanup.rb
  gsub_file 'Gemfile', /#.*\n/, "\n"
  gsub_file 'Gemfile', /\n^\s*\n/, "\n"
  remove_file 'Gemfile.lock'
  # remove commented lines and multiple blank lines from config/routes.rb
  gsub_file 'config/routes.rb', /  #.*\n/, "\n"
  gsub_file 'config/routes.rb', /\n^\s*\n/, "\n"
  # GIT
  git :add => '-A' if prefer :git, true
  git :commit => '-qm "rails_apps_composer: extras"' if prefer :git, true
end

## GITHUB
prefs[:github] = true if config['github']
if prefs[:github]
  add_gem 'hub', :require => nil, :group => [:development]
  stage_three do
    say_wizard "recipe stage three"
    say_wizard "recipe creating GitHub repository"
    git_uri = `git config remote.origin.url`.strip
    unless git_uri.size == 0
      say_wizard "Repository already exists:"
      say_wizard "#{git_uri}"
    else
      run "hub create #{app_name}"
      run "hub push -u origin master"
    end
  end
end
# >---------------------------- recipes/extras.rb ----------------------------end<
# >-------------------------- templates/recipe.erb ---------------------------end<


# >-----------------------------[ Final Gemfile Write ]------------------------------<
Gemfile.write

# >---------------------------------[ Diagnostics ]----------------------------------<

# remove prefs which are diagnostically irrelevant
redacted_prefs = prefs.clone
redacted_prefs.delete(:ban_spiders)
redacted_prefs.delete(:better_errors)
redacted_prefs.delete(:pry)
redacted_prefs.delete(:dev_webserver)
redacted_prefs.delete(:git)
redacted_prefs.delete(:github)
redacted_prefs.delete(:jsruntime)
redacted_prefs.delete(:local_env_file)
redacted_prefs.delete(:main_branch)
redacted_prefs.delete(:prelaunch_branch)
redacted_prefs.delete(:prod_webserver)
redacted_prefs.delete(:rvmrc)
redacted_prefs.delete(:templates)

if diagnostics_prefs.include? redacted_prefs
  diagnostics[:prefs] = 'success'
else
  diagnostics[:prefs] = 'fail'
end

@current_recipe = nil

# >-----------------------------[ Run 'Bundle Install' ]-------------------------------<

say_wizard "Installing Bundler (in case it is not installed)."
run 'gem install bundler'
say_wizard "Installing gems. This will take a while."
run 'bundle install --without production'
say_wizard "Updating gem paths."
Gem.clear_paths
# >-----------------------------[ Run 'stage_two' Callbacks ]-------------------------------<

say_wizard "Stage Two (running recipe 'stage_two' callbacks)."
if prefer :templates, 'slim'
say_wizard "importing and haml2slim conversion tools"
  require 'html2haml'
  require 'haml2slim'
end
@after_blocks.each{|b| config = @configs[b[0]] || {}; @current_recipe = b[0]; puts @current_recipe; b[1].call}

# >-----------------------------[ Run 'stage_three' Callbacks ]-------------------------------<

@current_recipe = nil
say_wizard "Stage Three (running recipe 'stage_three' callbacks)."
@stage_three_blocks.each{|b| config = @configs[b[0]] || {}; @current_recipe = b[0]; puts @current_recipe; b[1].call}

# >-----------------------------[ Run 'stage_four' Callbacks ]-------------------------------<

@current_recipe = nil
say_wizard "Stage Four (running recipe 'stage_four' callbacks)."
@stage_four_blocks.each{|b| config = @configs[b[0]] || {}; @current_recipe = b[0]; puts @current_recipe; b[1].call}

@current_recipe = nil
say_wizard("Your new application will contain diagnostics in its README file.")
say_wizard("When reporting an issue on GitHub, include the README diagnostics.")
say_wizard "Your new Rails app is ready. Time to run 'bundle install'."
