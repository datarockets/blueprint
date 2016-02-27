require 'blueprint/generator/base'

module Blueprint
  module Generator
    class RailsApp < Base
      private

        def execute(_config)
          puts "Generate rails application with name #{@name}"
        end
    end
  end
end
