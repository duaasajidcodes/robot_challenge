# frozen_string_literal: true

module RobotChallenge
  class Robot
    attr_reader :position, :direction, :table

    def initialize(table)
      @table = table
      @position = nil
      @direction = nil
    end

    def place(position, direction)
      raise InvalidPositionError, "Position must be a Position object" unless position.is_a?(Position)
      raise InvalidDirectionError, "Direction must be a Direction object" unless direction.is_a?(Direction)
      
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
      raise RobotNotPlacedError, 'Robot must be placed before moving' unless placed?

      delta_x, delta_y = direction.delta
      new_position = position.move(delta_x, delta_y)

      @position = new_position if table.valid_position?(new_position)
      self
    end

    def turn_left
      raise RobotNotPlacedError, 'Robot must be placed before turning' unless placed?

      @direction = direction.turn_left
      self
    end

    def turn_right
      raise RobotNotPlacedError, 'Robot must be placed before turning' unless placed?

      @direction = direction.turn_right
      self
    end

    def report
      raise RobotNotPlacedError, 'Robot must be placed before reporting' unless placed?

      "#{position},#{direction}"
    end

    def to_s
      placed? ? "Robot at #{position} facing #{direction}" : 'Robot not placed'
    end

    def inspect
      "#<Robot:#{object_id} position=#{position&.inspect}, direction=#{direction&.inspect}>"
    end

    def reset
      @position = nil
      @direction = nil
      self
    end

    def can_move?
      return false unless placed?

      delta_x, delta_y = direction.delta
      new_position = position.move(delta_x, delta_y)
      table.valid_position?(new_position)
    end
  end
end
