# frozen_string_literal: true

require_relative 'command'

module RobotChallenge
  module Commands
    class PlaceCommand < Command
      attr_reader :x, :y, :direction_name

      def initialize(x, y, direction_name)
        @x = x
        @y = y
        @direction_name = direction_name
      end

      def execute(robot)
        position = Position.new(x, y)
        direction = Direction.new(direction_name)

        robot.place(position, direction)
        success_result
      rescue InvalidPositionError, InvalidDirectionError => e
        error_result(e.message, :invalid_placement)
      end

      def valid?
        return false unless x.is_a?(Integer) && y.is_a?(Integer)
        return false unless x >= 0 && y >= 0
        return false unless Direction::VALID_DIRECTIONS.include?(direction_name.to_s.upcase)

        true
      end

      def to_s
        "PLACE #{x},#{y},#{direction_name}"
      end
    end
  end
end
