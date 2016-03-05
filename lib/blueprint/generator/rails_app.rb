require 'blueprint/generator/base'

module Blueprint
  module Generator
    class RailsApp < Base
      def self.template_path
        'rails_app'
      end

      private

        def execute
          cmd_title("Generate rails application with path #{name}")

          # Create application
          shell "rails new #{name} --skip-bundle --database=postgresql --no-rc --skip-test-unit"
          cd_path(name)

          # Copy dotfiles
          copy_file('.editorconfig')
          copy_file('.gitignore')
          copy_file('.ruby-version')

          # Create config/examples
          cmd_title('Create config\'s examples')
          shell 'mkdir config/examples'
          shell 'rm config/database.yml'
          shell 'mv config/secrets.yml config/examples/secrets.yml'
          copy_file_from_template('database.yml', 'config/examples/database.yml')

          copy_file_from_template('Gemfile')
        end
    end
  end
end
