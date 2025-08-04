# frozen_string_literal: true

require_relative 'command'

module RobotChallenge
  module Commands
    class PlaceCommand < Command
      attr_reader :x, :y, :direction, :direction_name

      def initialize(pos_x, pos_y, direction_name)
        @x = pos_x
        @y = pos_y
        @direction_name = direction_name.to_s.upcase
        @direction = RobotChallenge::Direction.new(@direction_name)
      rescue RobotChallenge::InvalidDirectionError
        # Set direction to nil if invalid
        @direction = nil
      end

      def execute(robot)
        # Check if command is valid before executing
        return error_result('Invalid PLACE command parameters', :invalid_placement) unless valid?

        handle_robot_placement_error do
          position = RobotChallenge::Position.new(x_coord, y_coord)
          robot.place(position, direction)
          success_result
        end
      end

      def valid?
        # Check if coordinates are valid integers
        return false unless pos_x_valid? && pos_y_valid?
        return false unless x_coord >= 0 && y_coord >= 0
        return false unless direction&.valid?

        true
      end

      def to_s
        "PLACE #{x},#{y},#{direction_name}"
      end

      private

      def x_coord
        @x.to_i
      end

      def y_coord
        @y.to_i
      end

      def pos_x_valid?
        @x.to_s == @x.to_i.to_s
      end

      def pos_y_valid?
        @y.to_s == @y.to_i.to_s
      end
    end
  end
end
