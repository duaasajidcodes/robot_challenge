# frozen_string_literal: true

module RobotChallenge
  module Commands
    # Base class for command parsers
    class CommandParser
      attr_reader :command_name

      def initialize(command_name)
        @command_name = command_name.to_s.upcase
      end

      def parse(command_string)
        raise NotImplementedError, "#{self.class} must implement #parse"
      end
    end

    # Parser for simple commands without parameters
    class SimpleCommandParser < CommandParser
      def parse(command_string)
        return nil unless command_string.strip.upcase == command_name

        {}
      end
    end

    # Parser for PLACE command
    class PlaceCommandParser < CommandParser
      def initialize
        super('PLACE')
      end

      def parse(command_string)
        return nil unless command_string.start_with?('PLACE ')

        # Extract parameters after PLACE
        params = command_string[6..].strip
        return nil if params.empty?

        # Parse X,Y,DIRECTION format
        parts = params.split(',')
        return nil unless parts.length == 3

        x, y, direction = parts.map(&:strip)

        # Validate coordinates are integers
        return nil unless x.match?(/^\d+$/) && y.match?(/^\d+$/)

        # Validate direction
        return nil unless Direction.valid_directions.include?(direction.upcase)

        {
          x: x.to_i,
          y: y.to_i,
          direction: direction.upcase
        }
      rescue StandardError
        nil
      end
    end
  end
end
