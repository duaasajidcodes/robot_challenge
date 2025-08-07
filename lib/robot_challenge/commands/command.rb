# frozen_string_literal: true

module RobotChallenge
  module Commands
    class Command
      # Execute the command on the given robot
      # @param robot [Robot] the robot to execute the command on
      # @return [Hash] execution result with status and optional data
      def execute(robot)
        raise NotImplementedError, "#{self.class} must implement #execute"
      end

      def valid?
        true
      end

      def name
        self.class.name.split('::').last.downcase.to_sym
      end

      def to_s
        self.class.name.split('::').last.gsub('Command', '').upcase
      end

      protected

      def success_result(data = nil)
        { status: :success, data: data }
      end

      def error_result(message, error_type = :general_error)
        { status: :error, message: message, error_type: error_type }
      end

      def output_result(message)
        { status: :output, message: message }
      end

      def handle_robot_placement_error
        yield
      rescue RobotNotPlacedError => e
        error_result(e.message, :robot_not_placed)
      rescue InvalidPositionError => e
        error_result(e.message, :invalid_placement)
      end
    end
  end
end
