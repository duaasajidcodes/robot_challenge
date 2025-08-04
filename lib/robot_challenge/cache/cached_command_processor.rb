# frozen_string_literal: true

require_relative '../command_processor'
require 'digest'

module RobotChallenge
  module Cache
    # Decorator that adds caching to CommandProcessor
    class CachedCommandProcessor
      attr_reader :processor, :cache

      def initialize(processor, cache = nil)
        @processor = processor
        @cache = cache || RedisCache.new
      end

      def process_command_string(command_string)
        cache_key = build_cache_key(command_string)
        cached_result = cache.get_command_result(cache_key)

        if cached_result
          log_cache_hit(command_string)
          return cached_result
        end

        result = processor.process_command_string(command_string)
        cache.set_command_result(cache_key, result)
        log_cache_miss(command_string)
        result
      end

      def process_command(command)
        cache_key = build_cache_key(command.to_s)
        cached_result = cache.get_command_result(cache_key)

        if cached_result
          log_cache_hit(command.to_s)
          return cached_result
        end

        result = processor.process_command(command)
        cache.set_command_result(cache_key, result)
        log_cache_miss(command.to_s)
        result
      end

      def robot
        processor.robot
      end

      def robot=(new_robot)
        processor.robot = new_robot
        invalidate_robot_cache
      end

      def available_commands
        processor.available_commands
      end

      def register_command(name, command_class)
        processor.register_command(name, command_class)
      end

      def command_factory
        processor.command_factory
      end

      private

      def build_cache_key(command_string)
        robot_state = robot_state_for_hash
        "command:#{Digest::MD5.hexdigest(command_string)}:#{robot_state}"
      end

      def robot_state_for_hash
        return 'unplaced' unless robot.placed?

        position = robot.position
        direction = robot.direction
        "#{position.x},#{position.y},#{direction.name}"
      end

      def invalidate_robot_cache
        robot_id = robot.object_id
        cache.invalidate_robot_cache(robot_id)
      end

      def log_cache_hit(command_string)
        # In a real application, you might want to log this
        # logger.debug("Cache hit for command: #{command_string}")
      end

      def log_cache_miss(command_string)
        # In a real application, you might want to log this
        # logger.debug("Cache miss for command: #{command_string}")
      end

      def method_missing(method_name, *, &)
        if processor.respond_to?(method_name)
          processor.send(method_name, *, &)
        else
          super
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        processor.respond_to?(method_name, include_private) || super
      end
    end
  end
end
