# frozen_string_literal: true

require_relative 'commands/command_factory'

module RobotChallenge
  # Processes commands using the Command Pattern
  class CommandProcessor
    attr_reader :robot, :output_handler, :command_factory

    def initialize(robot, output_handler: nil, command_factory: nil, output_formatter: nil)
      @robot = robot
      @output_handler = output_handler || method(:default_output_handler)
      @command_factory = command_factory || Commands::CommandFactory.new
      @output_formatter = output_formatter || OutputFormatterFactory.from_environment
    end

    # Process a command string
    def process_command_string(command_string)
      command = command_factory.create_from_string(command_string)
      process_command(command)
    end

    # Process a command object
    def process_command(command)
      return false if command.nil?

      begin
        result = command.execute(robot)
        handle_result(result)
      rescue StandardError => e
        # Silently ignore errors as per requirements
        # The robot should ignore invalid commands and continue
        handle_result(error_result(e.message, :execution_error))
      end

      false # Continue processing
    end

    # Process a sequence of command strings
    def process_command_strings(command_strings)
      command_strings.each do |command_string|
        process_command_string(command_string)
      end
    end

    # Get available commands
    def available_commands
      command_factory.available_commands
    end

    # Register a new command type
    def register_command(name, command_class)
      command_factory.register_command(name, command_class)
    end

    private

    def handle_result(result)
      case result[:status]
      when :output
        # Use output formatter for robot reports
        if result[:message].is_a?(String) && result[:message].match?(/^\d+,\d+,(NORTH|SOUTH|EAST|WEST)$/)
          # This is a robot report, format it properly
          formatted_message = @output_formatter.format_report(@robot)
          output_handler.call(formatted_message) if formatted_message
        else
          # Regular message, pass through
          output_handler.call(result[:message])
        end
      when :error
        # Use output formatter for errors
        formatted_message = @output_formatter.format_error(result[:message], result[:error_type])
        output_handler.call(formatted_message) if formatted_message
      when :success
        # Use output formatter for success messages
        formatted_message = @output_formatter.format_success(result[:message])
        output_handler.call(formatted_message) if formatted_message
      end
    end

    def error_result(message, error_type = :general_error)
      { status: :error, message: message, error_type: error_type }
    end

    def default_output_handler(message)
      puts message
    end
  end
end
