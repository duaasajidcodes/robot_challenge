# frozen_string_literal: true

require_relative 'command'

module RobotChallenge
  module Commands
    # Command to report robot's current position and direction
    class ReportCommand < Command
      def execute(robot)
        report = robot.report
        output_result(report)
      rescue RobotNotPlacedError => e
        error_result(e.message, :robot_not_placed)
      end

      def to_s
        'REPORT'
      end
    end
  end
end
