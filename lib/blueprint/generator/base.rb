module Blueprint
  module Generator
    class Base
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
    end
  end
end
