# frozen_string_literal: true

module RobotChallenge
  class CommandParserService
    include CommandParser

    attr_reader :command_factory

    def initialize(command_factory: nil)
      @command_factory = command_factory || Commands::CommandFactory.new
    end

    # Parse a command string into a command object
    def parse(command_string)
      return nil if command_string.nil? || command_string.strip.empty?

      command_factory.create_from_string(command_string.strip)
    end

    # Parse multiple command strings into command objects
    def parse_commands(command_strings)
      command_strings.map { |cmd_string| parse(cmd_string) }.compact
    end

    # Get available commands
    def available_commands
      command_factory.available_commands
    end

    # Register a new command type
    def register_command(name, command_class)
      command_factory.register_command(name, command_class)
    end

    # Check if a command string is valid
    def valid_command?(command_string)
      !parse(command_string).nil?
    end
  end
end
