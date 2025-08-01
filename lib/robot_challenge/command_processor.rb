# frozen_string_literal: true

require_relative 'commands/command_factory'

module RobotChallenge
  # Processes commands using the Command Pattern
  class CommandProcessor
    attr_reader :robot, :output_handler, :command_factory

    def initialize(robot, output_handler: nil, command_factory: nil)
      @robot = robot
      @output_handler = output_handler || method(:default_output_handler)
      @command_factory = command_factory || Commands::CommandFactory.new
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
        output_handler.call(result[:message])
      when :error
        # Silently ignore errors as per requirements
        # The robot should ignore invalid commands and continue
      when :success
        # Command executed successfully, no output needed
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
