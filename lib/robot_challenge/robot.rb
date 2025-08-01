# frozen_string_literal: true

module RobotChallenge
  class Robot
    include RobotOperations

    attr_reader :position, :direction, :table

    def initialize(table)
      @table = table
      @position = nil
      @direction = nil
    end

    def place(position, direction)
      raise InvalidPositionError, 'Position must be a Position object' unless position.is_a?(Position)
      raise InvalidDirectionError, 'Direction must be a Direction object' unless direction.is_a?(Direction)

      unless table.valid_position?(position)
        raise InvalidPositionError, "Position #{position} is outside table boundaries"
      end

      @position = position
      @direction = direction
      self
    end

    def placed?
      !position.nil? && !direction.nil?
    end

    def move
      ensure_placed!
      delta_x, delta_y = direction.delta
      new_position = position.move(delta_x, delta_y)

      @position = new_position if table.valid_position?(new_position)
      self
    end

    def turn_left
      ensure_placed!
      @direction = direction.turn_left
      self
    end

    def turn_right
      ensure_placed!
      @direction = direction.turn_right
      self
    end

    def report
      ensure_placed!
      "#{position},#{direction}"
    end

    def to_s
      placed? ? "Robot at #{position} facing #{direction}" : 'Robot not placed'
    end

    def inspect
      "#<Robot:#{object_id} position=#{position&.inspect}, direction=#{direction&.inspect}>"
    end

    private

    def ensure_placed!
      raise RobotNotPlacedError, 'Robot must be placed before performing this action' unless placed?
    end
  end
end
