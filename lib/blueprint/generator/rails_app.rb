require 'blueprint/generator/base'

module Blueprint
  module Generator
    class RailsApp < Base

      private

        def execute(_config)
          puts "Generate rails application with path #{name}"

          shell "rails new #{name} --skip-bundle --database=postgresql --no-rc --skip-test-unit"
          cd_path(name)

          copy_file(".editorconfig")
        end

        def self.template_path
          'rails_app'
        end
    end
  end
end
