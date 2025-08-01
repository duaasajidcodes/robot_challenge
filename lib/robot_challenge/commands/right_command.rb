# frozen_string_literal: true

require_relative 'command'

module RobotChallenge
  module Commands
    # Command to turn the robot right
    class RightCommand < Command
      def execute(robot)
        robot.turn_right
        success_result
      rescue RobotNotPlacedError => e
        error_result(e.message, :robot_not_placed)
      end

      def to_s
        'RIGHT'
      end
    end
  end
end
