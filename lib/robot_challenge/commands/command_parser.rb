# frozen_string_literal: true

module RobotChallenge
  module Commands
    class CommandParser
      def parse(_command_string)
        raise NotImplementedError, 'Subclasses must implement parse method'
      end

      def command_name
        raise NotImplementedError, 'Subclasses must implement command_name method'
      end

      protected

      def normalize_command(command_string)
        command_string.to_s.strip.upcase
      end

      def extract_parameters(command_string)
        command_string.to_s.strip.split(/\s+/, 2).last || ''
      end
    end

    class SimpleCommandParser < CommandParser
      def initialize(command_name)
        @command_name = command_name.to_s.upcase
      end

      attr_reader :command_name

      def parse(command_string)
        normalized = normalize_command(command_string)
        normalized == @command_name ? {} : nil
      end
    end

    class PlaceCommandParser < CommandParser
      def command_name
        'PLACE'
      end

      def parse(command_string)
        normalized = normalize_command(command_string)
        return nil unless normalized.start_with?('PLACE')

        params = extract_parameters(command_string)
        return nil if params.empty?

        parse_parameters(params)
      rescue StandardError
        nil
      end

      private

      def parse_parameters(params)
        # Handle different formats: "0,0,NORTH", "0 0 NORTH", "(0,0,NORTH)"
        cleaned_params = params.gsub(/[()]/, '').strip
        parts = cleaned_params.split(/[,\s]+/)

        return nil unless parts.length == 3

        x_coord, y_coord, direction_name = parts
        validate_and_create_params(x_coord, y_coord, direction_name)
      end

      def validate_and_create_params(pos_x, pos_y, direction_name)
        x_val = pos_x.to_i
        y_val = pos_y.to_i
        direction = direction_name.to_s.upcase

        return nil unless x_val >= 0 && y_val >= 0
        return nil unless RobotChallenge::Direction::VALID_DIRECTIONS.include?(direction)

        { x: x_val, y: y_val, direction: direction }
      end
    end

    class FlexibleCommandParser < CommandParser
      def initialize(command_name)
        @command_name = command_name.to_s.upcase
      end

      attr_reader :command_name

      def parse(command_string)
        normalized = normalize_command(command_string)
        normalized == @command_name ? {} : nil
      end
    end
  end
end
