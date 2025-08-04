# frozen_string_literal: true

require_relative 'command'

module RobotChallenge
  module Commands
    # Command to report robot's current position and direction
    class ReportCommand < Command
      def initialize(*); end

      def execute(robot)
        handle_robot_placement_error do
          robot.report
          output_result(robot)
        end
      end
    end
  end
end
