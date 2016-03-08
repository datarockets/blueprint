require 'erb'

module Blueprint
  module Generator
    class Base
      class TemplateRendering
        attr_reader :name, :config

        def initialize(name, config)
          @name = name
          @config = config
        end

        def render(template_file)
          template = File.open(template_file).read
          ERB.new(template, 0, '%<>').result(binding)
        end

        def save(from, to)
          File.open(to, 'w+') do |f|
            f.write(render(from))
          end
        end
      end
    end
  end
end
