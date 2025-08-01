# frozen_string_literal: true

require_relative 'command_registry'
require_relative 'command_parser'

module RobotChallenge
  module Commands
    # Factory for creating command objects from strings
    class CommandFactory
      attr_reader :registry, :parsers

      def initialize(registry = nil)
        @registry = registry || CommandRegistry.new
        @parsers = []
        register_default_parsers
      end

      # Create a command from a command string
      def create_from_string(command_string)
        parsed_command = parse_command_string(command_string)
        return nil unless parsed_command

        registry.create_command(
          parsed_command[:name],
          **parsed_command[:params]
        )
      end

      # Get list of available commands
      def available_commands
        registry.command_names
      end

      # Register a new command type
      def register_command(name, command_class)
        registry.register(name, command_class)
      end

      # Register a new command parser
      def register_parser(parser)
        @parsers << parser
      end

      private

      def parse_command_string(command_string)
        return nil if command_string.nil? || command_string.strip.empty?

        # Try each parser in order
        @parsers.each do |parser|
          if parser.can_parse?(command_string)
            result = parser.parse(command_string)
            return result if result && registry.registered?(result[:name])
          end
        end

        nil
      end

      def register_default_parsers
        # Register PLACE command parser first (more specific)
        register_parser(PlaceCommandParser.new)

        # Register simple parsers for commands with no parameters
        %w[MOVE LEFT RIGHT REPORT].each do |command_name|
          register_parser(SimpleCommandParser.new(command_name))
        end
      end
    end
  end
end
