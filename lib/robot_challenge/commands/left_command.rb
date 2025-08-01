# frozen_string_literal: true

require_relative 'command'

module RobotChallenge
  module Commands
    class LeftCommand < Command
      def execute(robot)
        robot.turn_left
        success_result
      rescue RobotNotPlacedError => e
        error_result(e.message, :robot_not_placed)
      end

      def to_s
        'LEFT'
      end
    end
  end
end
