# frozen_string_literal: true

require_relative 'command_parser'

module RobotChallenge
  module Commands
    # Factory for creating commands from strings
    class CommandFactory
      attr_reader :registry, :parsers

      def initialize(registry = nil)
        @registry = registry || CommandRegistry.new
        @parsers = {}
        register_default_parsers
      end

      # Create a command from a string
      def create_from_string(command_string)
        return nil if command_string.nil? || command_string.strip.empty?

        original_string = command_string.strip
        command_string = original_string.upcase
        parser = find_parser_for_command(command_string)

        if parser
          parsed_params = parser.parse(original_string)
          return nil unless parsed_params

          create_command_from_params(command_string.split.first, parsed_params)
        else
          # Try to create simple command without parameters
          create_simple_command(command_string)
        end
      end

      # Register a new command parser
      def register_parser(parser)
        @parsers[parser.command_name] = parser
      end

      # Get available commands
      def available_commands
        registry.command_names
      end

      # Register a new command
      def register_command(name, command_class, aliases: [])
        registry.register(name, command_class, aliases: aliases)
      end

      private

      def find_parser_for_command(command_string)
        command_name = command_string.split.first
        @parsers[command_name]
      end

      def create_command_from_params(command_name, params)
        case command_name
        when 'PLACE'
          registry.create_command('PLACE', x: params[:x], y: params[:y], direction: params[:direction])
        else
          # For simple commands, don't pass empty parameters
          if params.empty?
            registry.create_command(command_name)
          else
            registry.create_command(command_name, **params)
          end
        end
      end

      def create_simple_command(command_string)
        command_name = command_string.split.first
        registry.create_command(command_name)
      end

      def register_default_parsers
        # Register PLACE command parser (most flexible)
        register_parser(PlaceCommandParser.new)
      end
    end
  end
end
