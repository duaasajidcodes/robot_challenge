# frozen_string_literal: true

module RobotChallenge
  # Value object representing a direction with rotation capabilities
  class Direction
    VALID_DIRECTIONS = %w[NORTH EAST SOUTH WEST].freeze
    DIRECTION_DELTAS = {
      'NORTH' => [0, 1],
      'EAST' => [1, 0],
      'SOUTH' => [0, -1],
      'WEST' => [-1, 0]
    }.freeze

    attr_reader :name

    def initialize(name)
      normalized_name = name.to_s.upcase
      unless VALID_DIRECTIONS.include?(normalized_name)
        raise InvalidDirectionError, "Invalid direction: #{name}. Must be one of #{VALID_DIRECTIONS.join(', ')}"
      end

      @name = normalized_name
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

    def inspect
      "#<Direction:#{object_id} name=#{name}>"
    end

    # Rotate 90 degrees counter-clockwise (left)
    def turn_left
      current_index = VALID_DIRECTIONS.index(name)
      new_index = (current_index - 1) % VALID_DIRECTIONS.length
      Direction.new(VALID_DIRECTIONS[new_index])
    end

    # Rotate 90 degrees clockwise (right)
    def turn_right
      current_index = VALID_DIRECTIONS.index(name)
      new_index = (current_index + 1) % VALID_DIRECTIONS.length
      Direction.new(VALID_DIRECTIONS[new_index])
    end

    # Get the movement deltas for this direction
    def delta
      DIRECTION_DELTAS[name]
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
  end
end
