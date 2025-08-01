# frozen_string_literal: true

module RobotChallenge
  module Commands
    # Abstract base class for command parsers
    class CommandParser
      # Parse a command string and return parsed parameters
      # @param command_string [String] the command string to parse
      # @return [Hash, nil] parsed parameters or nil if parsing fails
      def parse(command_string)
        raise NotImplementedError, "#{self.class} must implement #parse"
      end

      # Check if this parser can handle the given command
      # @param command_string [String] the command string to check
      # @return [Boolean] true if this parser can handle the command
      def can_parse?(command_string)
        raise NotImplementedError, "#{self.class} must implement #can_parse?"
      end
    end

    # Default parser for simple commands with no parameters
    class SimpleCommandParser < CommandParser
      def initialize(command_name)
        @command_name = command_name.upcase
      end

      def can_parse?(command_string)
        return false if command_string.nil? || command_string.strip.empty?

        parts = command_string.strip.upcase.split(/\s+/, 2)
        parts[0] == @command_name
      end

      def parse(command_string)
        return nil unless can_parse?(command_string)

        {
          name: @command_name,
          params: {}
        }
      end
    end

    # Parser for PLACE command with X,Y,DIRECTION format
    class PlaceCommandParser < CommandParser
      def can_parse?(command_string)
        return false if command_string.nil? || command_string.strip.empty?

        parts = command_string.strip.upcase.split(/\s+/, 2)
        parts[0] == 'PLACE' && parts[1]&.include?(',')
      end

      def parse(command_string)
        return nil unless can_parse?(command_string)

        parts = command_string.strip.upcase.split(/\s+/, 2)
        args = parts[1]

        return nil if args.nil? || args.empty?

        # Expected format: "X,Y,DIRECTION"
        arg_parts = args.split(',')
        return nil unless arg_parts.length == 3

        x, y, direction_name = arg_parts.map(&:strip)

        # Validate coordinates are integers
        begin
          x_coord = Integer(x)
          y_coord = Integer(y)
        rescue ArgumentError
          return nil
        end

        # Validate direction
        return nil unless Direction::VALID_DIRECTIONS.include?(direction_name.upcase)

        {
          name: 'PLACE',
          params: {
            x: x_coord,
            y: y_coord,
            direction: direction_name.upcase
          }
        }
      end
    end
  end
end
