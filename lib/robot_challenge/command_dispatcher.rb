# frozen_string_literal: true

module RobotChallenge
  # Responsible for dispatching and executing commands
  # Separates command execution from command parsing (SRP)
  class CommandDispatcher
    include CommandDispatcherInterface

    attr_reader :robot, :output_formatter

    def initialize(robot, output_formatter: nil, logger: nil)
      @robot = robot
      @output_formatter = output_formatter || OutputFormatterFactory.from_environment
      @logger = logger || LoggerFactory.from_environment
    end

    # Execute a command object
    def dispatch(command, &block)
      return false if command.nil?

      @logger.debug("Dispatching command: #{command.class}")
      begin
        result = command.execute(robot)
        handle_result(result, &block)
      rescue StandardError => e
        @logger.error("Error executing command: #{e.message}")
        # Silently ignore errors as per requirements
        handle_result(error_result(e.message, :execution_error), &block)
      end

      false # Continue processing
    end

    # Execute multiple commands
    def dispatch_commands(commands, &block)
      commands.each { |command| dispatch(command, &block) }
    end

    private

    def handle_result(result, &block)
      case result[:status]
      when :output
        # Use output formatter for robot reports
        if result[:message].is_a?(String) && result[:message].match?(/^\d+,\d+,(NORTH|SOUTH|EAST|WEST)$/)
          # This is a robot report, format it properly
          formatted_message = @output_formatter.format_report(@robot)
          block.call(formatted_message) if formatted_message && block_given?
        elsif block_given?
          # Regular message, pass through
          block.call(result[:message])
        end
      when :error
        # Use output formatter for errors
        formatted_message = @output_formatter.format_error(result[:message], result[:error_type])
        block.call(formatted_message) if formatted_message && block_given?
      when :success
        # Use output formatter for success messages
        formatted_message = @output_formatter.format_success(result[:message])
        block.call(formatted_message) if formatted_message && block_given?
      end
    end

    def error_result(message, error_type = :general_error)
      { status: :error, message: message, error_type: error_type }
    end
  end
end
