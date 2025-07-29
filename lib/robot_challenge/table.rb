# frozen_string_literal: true

module RobotChallenge
  class Table
    attr_reader :width, :height

    def initialize(width = 5, height = 5)
      @width = width
      @height = height
    end

    def valid_position?(position)
      return false unless position.is_a?(Position)

      position.x >= 0 && position.x < width &&
        position.y >= 0 && position.y < height
    end

    def all_positions
      positions = []
      (0...height).each do |y|
        (0...width).each do |x|
          positions << Position.new(x, y)
        end
      end
      positions
    end

    def to_s
      "#{width}x#{height} table"
    end

    def inspect
      "#<Table:#{object_id} width=#{width}, height=#{height}>"
    end

    def ==(other)
      return false unless other.is_a?(Table)

      width == other.width && height == other.height
    end
  end
end
