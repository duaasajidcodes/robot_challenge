# frozen_string_literal: true

module RobotChallenge
  # Value object representing a position on the table
  class Position
    attr_reader :x, :y

    def initialize(x, y)
      @x = x.to_i
      @y = y.to_i
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

    def inspect
      "#<Position:#{object_id} x=#{x}, y=#{y}>"
    end

    # Create a new position moved by the given deltas
    def move(delta_x, delta_y)
      Position.new(x + delta_x, y + delta_y)
    end
  end
end
