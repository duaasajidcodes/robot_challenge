# frozen_string_literal: true

module RobotChallenge
  # Represents a position on the table with x and y coordinates
  class Position
    attr_reader :x, :y

    def initialize(pos_x, pos_y)
      @x = pos_x.to_i
      @y = pos_y.to_i
    end

    def ==(other)
      return false unless other.is_a?(Position)

      x == other.x && y == other.y
    end

    def eql?(other)
      self == other
    end

    def hash
      [x, y].hash
    end

    def to_s
      "#{x},#{y}"
    end

    # Create a new position moved by the given deltas
    def move(delta_x, delta_y)
      Position.new(x + delta_x, y + delta_y)
    end
  end
end
