# frozen_string_literal: true

module RobotChallenge
  # Responsible for dispatching and executing commands
  # Separates command execution from command parsing (SRP)
  class CommandDispatcher
    include CommandDispatcherInterface

    attr_accessor :output_formatter
    attr_reader :robot

    def initialize(robot, output_formatter: nil, logger: nil)
      @robot = robot
      @output_formatter = output_formatter || OutputFormatterFactory.from_environment
      @logger = logger || LoggerFactory.from_environment
    end

    # Execute a command object
    def dispatch(command, &)
      return false if command.nil?

      begin
        result = command.execute(robot)
        handle_result(result, &)
      rescue StandardError => e
        @logger.error("Error executing command: #{e.message}")
        handle_result({ status: :error, message: e.message, error_type: :execution_error }, &)
      end

      false # Continue processing
    end

    # Execute multiple commands
    def dispatch_commands(commands, &block)
      commands.each { |command| dispatch(command, &block) }
    end

    private

    def handle_result(result, &)
      case result[:status]
      when :output
        handle_output_result(result, &)
      when :error
        handle_error_result(result, &)
      when :success
        handle_success_result(result, &)
      end
    end

    def handle_output_result(result, &block)
      message = result[:message]

      if robot_report?(message)
        handle_robot_report(message, &block)
      elsif block
        block.call(message)
      end
    end

    def handle_robot_report(message, &block)
      robot_object = message.is_a?(RobotChallenge::Robot) ? message : @robot
      formatted_message = @output_formatter.format_report(robot_object)
      block.call(formatted_message) if formatted_message && block
    end

    def robot_report?(message)
      message.is_a?(RobotChallenge::Robot) ||
        (message.is_a?(String) && message.match?(/^\d+,\d+,(NORTH|SOUTH|EAST|WEST)$/))
    end

    def handle_error_result(result, &block)
      formatted_message = @output_formatter.format_error(result[:message], result[:error_type])
      block.call(formatted_message) if formatted_message && block
    end

    def handle_success_result(result, &block)
      formatted_message = @output_formatter.format_success(result[:message])
      block.call(formatted_message) if formatted_message && block
    end
  end
end
