# frozen_string_literal: true

module RobotChallenge
  class CommandParser
    VALID_COMMANDS = %w[PLACE MOVE LEFT RIGHT REPORT EXIT QUIT].freeze

    def self.parse(command_string)
      return nil if command_string.nil? || command_string.strip.empty?

      parts = command_string.strip.upcase.split(/\s+/, 2)
      command_name = parts[0]

      return nil unless VALID_COMMANDS.include?(command_name)

      case command_name
      when 'PLACE'
        parse_place_command(parts[1])
      when 'MOVE', 'LEFT', 'RIGHT', 'REPORT', 'EXIT', 'QUIT'
        { command: command_name.downcase.to_sym }
      end
    end

    private_class_method def self.parse_place_command(args)
      return nil if args.nil? || args.empty?

      parts = args.split(',')
      return nil unless parts.length == 3

      x, y, direction_name = parts.map(&:strip)

      begin
        x_coord = Integer(x)
        y_coord = Integer(y)
      rescue ArgumentError
        return nil
      end

      return nil unless Direction::VALID_DIRECTIONS.include?(direction_name.upcase)

      {
        command: :place,
        x: x_coord,
        y: y_coord,
        direction: direction_name.upcase
      }
    end
  end
end
