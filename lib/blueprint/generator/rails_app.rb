require 'blueprint/generator/base'

module Blueprint
  module Generator
    class RailsApp < Base
      private

        def execute(_config)
          puts "Generate rails application with path #{name}"

          shell "rails new #{name} --skip-bundle --database=postgresql --no-rc --skip-test-unit"
          shell "cd #{name}"
        end
    end
  end
end
