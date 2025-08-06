# frozen_string_literal: true

module RobotChallenge
  # Represents a direction the robot can face
  class Direction
    VALID_DIRECTIONS = %w[NORTH EAST SOUTH WEST].freeze

    attr_reader :name

    def initialize(name)
      @name = name.to_s.upcase
      validate_direction!
    end

    def ==(other)
      return false unless other.is_a?(Direction)

      name == other.name
    end

    def eql?(other)
      self == other
    end

    def hash
      name.hash
    end

    def to_s
      name
    end

    def turn_left
      case name
      when 'NORTH' then Direction.new('WEST')
      when 'WEST' then Direction.new('SOUTH')
      when 'SOUTH' then Direction.new('EAST')
      when 'EAST' then Direction.new('NORTH')
      else
        raise InvalidDirectionError, "Cannot turn left from invalid direction: #{name}"
      end
    end

    def turn_right
      case name
      when 'NORTH' then Direction.new('EAST')
      when 'EAST' then Direction.new('SOUTH')
      when 'SOUTH' then Direction.new('WEST')
      when 'WEST' then Direction.new('NORTH')
      else
        raise InvalidDirectionError, "Cannot turn right from invalid direction: #{name}"
      end
    end

    def delta_x
      case name
      when 'EAST' then 1
      when 'WEST' then -1
      else 0
      end
    end

    def delta_y
      case name
      when 'NORTH' then 1
      when 'SOUTH' then -1
      else 0
      end
    end

    def delta
      [delta_x, delta_y]
    end

    # Class methods for creating common directions
    class << self
      def north
        @north ||= new('NORTH')
      end

      def east
        @east ||= new('EAST')
      end

      def south
        @south ||= new('SOUTH')
      end

      def west
        @west ||= new('WEST')
      end

      def valid_directions
        VALID_DIRECTIONS.dup
      end
    end

    private

    def validate_direction!
      return if VALID_DIRECTIONS.include?(@name)

      raise InvalidDirectionError, "Invalid direction: #{@name}. Must be one of #{VALID_DIRECTIONS.join(', ')}"
    end
  end
end
