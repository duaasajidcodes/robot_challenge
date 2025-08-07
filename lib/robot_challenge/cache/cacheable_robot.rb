# frozen_string_literal: true

require_relative 'redis_cache'
require 'securerandom'

module RobotChallenge
  module Cache
    class CacheableRobot
      include RobotOperations

      attr_reader :robot, :cache, :robot_id

      def initialize(robot, cache: nil, robot_id: nil)
        @robot = robot
        @cache = cache || RedisCache.new
        @robot_id = robot_id || generate_robot_id
      end

      # Override robot operations to add caching
      def place(position, direction)
        result = @robot.place(position, direction)
        cache_robot_state
        result
      end

      def move
        result = @robot.move
        cache_robot_state
        result
      end

      def turn_left
        result = @robot.turn_left
        cache_robot_state
        result
      end

      def turn_right
        result = @robot.turn_right
        cache_robot_state
        result
      end

      def report
        @robot.report
      end

      def placed?
        @robot.placed?
      end

      def invalidate_cache
        @cache.invalidate_robot_cache(@robot_id)
      end

      def cache_stats
        @cache.cache_stats
      end

      def health_check
        @cache.health_check
      end

      def method_missing(method_name, ...)
        if @robot.respond_to?(method_name)
          @robot.send(method_name, ...)
        else
          super
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        @robot.respond_to?(method_name, include_private) || super
      end

      def load_from_cache
        cached_state = @cache.get_robot_state(@robot_id)
        return false unless cached_state

        # Reconstruct robot state from cache
        if cached_state[:position]
          position = Position.new(cached_state[:position][:x], cached_state[:position][:y])
          direction = Direction.new(cached_state[:direction])
          @robot.instance_variable_set(:@position, position)
          @robot.instance_variable_set(:@direction, direction)
        end
        true
      rescue StandardError => e
        log_cache_error('load_from_cache', e)
        false
      end

      private

      def cache_robot_state
        state = {
          position: robot_state_hash(@robot.position),
          direction: @robot.direction&.name,
          placed: @robot.placed?,
          table: {
            width: @robot.table.width,
            height: @robot.table.height
          },
          timestamp: Time.now.iso8601
        }

        @cache.cache_robot_state(@robot_id, state)
      rescue StandardError => e
        log_cache_error('cache_robot_state', e)
      end

      def robot_state_hash(position)
        return nil unless position

        {
          x: position.x,
          y: position.y
        }
      end

      def generate_robot_id
        "robot_#{SecureRandom.uuid}"
      end

      def log_cache_error(operation, error)
        # Error logging handled by main logger
      end
    end
  end
end
