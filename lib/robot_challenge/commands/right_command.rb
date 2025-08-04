# frozen_string_literal: true

require_relative 'command'

module RobotChallenge
  module Commands
    # Command to turn the robot right
    class RightCommand < Command
      def initialize(*); end

      def execute(robot)
        handle_robot_placement_error do
          robot.turn_right
          success_result
        end
      end
    end
  end
end
