# frozen_string_literal: true

require_relative 'command'

module RobotChallenge
  module Commands
    # Command to report robot's current position and direction
    class ReportCommand < Command
      def execute(robot)
        handle_robot_placement_error do
          report = robot.report
          output_result(report)
        end
      end


    end
  end
end
