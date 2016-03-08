require 'blueprint/generator/base/template_rendering'

module Blueprint
  module Generator
    class Base
      attr_reader :name, :config

      def initialize(name:)
        @name = name
        @config = {}
      end

      def run!
        ask_questions
        execute
      end

      def self.template_path
        ''
      end

      private

        def ask_questions
        end

        def execute
        end

        def shell(cmd)
          cmd_title("Run #{cmd}")
          system(cmd)
        end

        def copy_file(from, to = nil)
          cmd_title("Copy file #{from}")
          to = from if to.nil?
          FileUtils.cp(template_path + from, to)
        end

        def copy_file_from_template(from, to = nil)
          cmd_title("Copy file #{from} from template")
          to = from if to.nil?

          template = TemplateRendering.new(name, config)
          template.save(template_path + from + '.erb', to)
        end

        def cd_path(path)
          cmd_title("Cnahge the current directory to #{path}")
          FileUtils.cd(path)
        end

        def template_path
          File.expand_path(File.dirname(__FILE__)) + '/templates/' + self.class.template_path + '/'
        end

        def cmd_title(title)
          puts
          puts title
          puts
        end
    end
  end
end
