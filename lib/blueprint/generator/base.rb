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
          system(cmd)
        end
    end
  end
end
