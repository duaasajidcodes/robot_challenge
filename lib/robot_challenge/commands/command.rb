# frozen_string_literal: true

module RobotChallenge
  module Commands
    # Abstract base class for all commands
    class Command
      # Execute the command on the given robot
      # @param robot [Robot] the robot to execute the command on
      # @return [Hash] execution result with status and optional data
      def execute(robot)
        raise NotImplementedError, "#{self.class} must implement #execute"
      end

      # Validate command parameters before execution
      # @return [Boolean] true if command is valid
      def valid?
        true
      end

      # Get command name for identification
      # @return [Symbol] command name
      def name
        self.class.name.split('::').last.downcase.to_sym
      end

      protected

      # Standard success result
      def success_result(data = nil)
        { status: :success, data: data }
      end

      # Standard error result
      def error_result(message, error_type = :general_error)
        { status: :error, message: message, error_type: error_type }
      end

      # Result that should be displayed to user
      def output_result(message)
        { status: :output, message: message }
      end
    end
  end
end
