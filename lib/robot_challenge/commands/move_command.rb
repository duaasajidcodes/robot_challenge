# frozen_string_literal: true

require_relative 'command'

module RobotChallenge
  module Commands
    # Command to move the robot forward
    class MoveCommand < Command
      def execute(robot)
        robot.move
        success_result
      rescue RobotNotPlacedError => e
        error_result(e.message, :robot_not_placed)
      end

      def to_s
        'MOVE'
      end
    end
  end
end
