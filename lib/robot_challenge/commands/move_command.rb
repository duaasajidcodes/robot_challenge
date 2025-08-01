# frozen_string_literal: true

require_relative 'command'

module RobotChallenge
  module Commands
    # Command to move the robot forward
    class MoveCommand < Command
      def execute(robot)
        handle_robot_placement_error do
          robot.move
          success_result
        end
      end
    end
  end
end
