# frozen_string_literal: true

require_relative 'command'

module RobotChallenge
  module Commands
    # Command to exit the robot application
    class ExitCommand < Command
      def execute(_robot)
        output_result('Goodbye! Thanks for using Robot Challenge!')
      end

      def valid_for_robot?(_robot)
        true # Can always exit regardless of robot state
      end
    end
  end
end
