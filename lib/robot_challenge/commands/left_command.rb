# frozen_string_literal: true

require_relative 'command'

module RobotChallenge
  module Commands
    class LeftCommand < Command
      def initialize(*); end

      def execute(robot)
        handle_robot_placement_error do
          robot.turn_left
          success_result
        end
      end
    end
  end
end
