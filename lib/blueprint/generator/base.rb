module Blueprint
  module Generator
    class Base
      attr_reader :name

      def initialize(name:)
        @name = name
      end

      def run!
        config = ask_questions
        execute(config)
      end

      def self.test
        puts 'test'
      end

      private

        def ask_questions
          {}
        end

        def execute(config)
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

        def cd_path(path)
          cmd_title("Cnahge the current directory to #{path}")
          FileUtils.cd(path)
        end

        def template_path
          File.expand_path(File.dirname(__FILE__)) + '/templates/' + self.class.template_path + '/'
        end

        def self.template_path
          ''
        end

        def cmd_title(title)
          puts
          puts title
          puts
        end
    end
  end
end
