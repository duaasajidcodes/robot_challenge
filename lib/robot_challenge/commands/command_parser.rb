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

      protected

      def normalize_command(command_string)
        command_string.to_s.strip.upcase
      end

      # Extract command name from string
      def extract_command_name(command_string)
        normalize_command(command_string).split(/\s+/).first
      end

      # Extract parameters after command name
      def extract_parameters(command_string)
        normalized = normalize_command(command_string)
        parts = normalized.split(/\s+/, 2)
        parts.length > 1 ? parts[1] : ''
      end
    end

    # Parser for simple commands without parameters
    class SimpleCommandParser < CommandParser
      def parse(command_string)
        normalized = normalize_command(command_string)
        return nil unless normalized == command_name

        {}
      end
    end

    # Parser for PLACE command with flexible format support
    class PlaceCommandParser < CommandParser
      def initialize
        super('PLACE')
      end

      def parse(command_string)
        normalized = normalize_command(command_string)
        return nil unless normalized.start_with?('PLACE')

        # Extract parameters after PLACE
        params = extract_parameters(command_string)
        return nil if params.empty?

        # Try different parsing strategies
        parse_parameters(params)
      rescue StandardError
        nil
      end

      private

      def parse_parameters(params)
        # Strategy 1: Standard X,Y,DIRECTION format
        if params.include?(',')
          parse_comma_separated(params)
        # Strategy 2: Space-separated format (PLACE X Y DIRECTION)
        elsif params.split(/\s+/).length >= 3
          parse_space_separated(params)
        # Strategy 3: Mixed format with parentheses (PLACE(X,Y,DIRECTION))
        elsif params.match?(/\(.*,.*,.*\)/)
          parse_parentheses_format(params)
        else
          nil
        end
      end

      def parse_comma_separated(params)
        # Handle various comma formats: "X,Y,DIRECTION", "X, Y, DIRECTION", etc.
        parts = params.split(',').map(&:strip)
        return nil unless parts.length == 3

        x, y, direction = parts
        validate_and_create_params(x, y, direction)
      end

      def parse_space_separated(params)
        # Handle space-separated format: "X Y DIRECTION"
        parts = params.split(/\s+/)
        return nil unless parts.length >= 3

        x, y, direction = parts[0], parts[1], parts[2]
        validate_and_create_params(x, y, direction)
      end

      def parse_parentheses_format(params)
        # Handle parentheses format: "(X,Y,DIRECTION)" or "X,Y,DIRECTION"
        # Remove parentheses and parse as comma-separated
        clean_params = params.gsub(/[()]/, '')
        parse_comma_separated(clean_params)
      end

      def validate_and_create_params(x, y, direction)
        # Validate coordinates are integers (allow negative for future extensibility)
        return nil unless x.match?(/^-?\d+$/) && y.match?(/^-?\d+$/)

        # Validate direction (case insensitive)
        direction_up = direction.upcase
        return nil unless Direction.valid_directions.include?(direction_up)

        {
          x: x.to_i,
          y: y.to_i,
          direction: direction_up
        }
      end
    end

    # Flexible parser that can handle multiple command formats
    class FlexibleCommandParser < CommandParser
      def initialize(command_name)
        super(command_name)
      end

      def parse(command_string)
        normalized = normalize_command(command_string)
        
        # Try exact match first
        return {} if normalized == command_name
        
        # Try with extra whitespace
        return {} if normalized.gsub(/\s+/, '') == command_name
        
        # Try with different separators
        return {} if normalized.gsub(/[_\-\s]+/, '') == command_name
        
        nil
      end
    end
  end
end
