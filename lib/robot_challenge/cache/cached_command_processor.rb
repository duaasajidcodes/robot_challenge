# frozen_string_literal: true

require_relative 'redis_cache'
require 'digest'

module RobotChallenge
  module Cache
    # Cached command processor that adds Redis caching to command execution
    class CachedCommandProcessor
      attr_reader :processor, :cache

      def initialize(processor, cache: nil)
        @processor = processor
        @cache = cache || RedisCache.new
      end

      # Process command with caching
      def process_command_string(command_string)
        command_hash = generate_command_hash(command_string)

        # Try to get cached result first
        cached_result = @cache.get_cached_result(command_hash)
        if cached_result
          log_cache_hit(command_string, cached_result)
          return cached_result
        end

        # Execute command and cache result
        result = @processor.process_command_string(command_string)
        cache_command_result(command_hash, command_string, result)
        result
      end

      # Process command object with caching
      def process_command(command)
        command_string = command.to_s
        command_hash = generate_command_hash(command_string)

        # Try to get cached result first
        cached_result = @cache.get_cached_result(command_hash)
        if cached_result
          log_cache_hit(command_string, cached_result)
          return cached_result
        end

        # Execute command and cache result
        result = @processor.process_command(command)
        cache_command_result(command_hash, command_string, result)
        result
      end

      # Process multiple commands with caching
      def process_command_strings(command_strings)
        results = []

        command_strings.each do |command_string|
          result = process_command_string(command_string)
          results << result
        end

        results
      end

      # Delegate other methods to the underlying processor
      def method_missing(method_name, ...)
        if @processor.respond_to?(method_name)
          @processor.send(method_name, ...)
        else
          super
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        @processor.respond_to?(method_name, include_private) || super
      end

      # Cache management methods
      def invalidate_command_cache(command_hash)
        @cache.invalidate_command_cache(command_hash)
      end

      def clear_command_cache
        @cache.clear_all_cache
      end

      def cache_stats
        @cache.cache_stats
      end

      def health_check
        @cache.health_check
      end

      # Get command execution statistics
      def command_stats
        stats = @cache.get_command_stats || {
          total_commands: 0,
          cached_commands: 0,
          cache_hits: 0,
          cache_misses: 0,
          average_execution_time: 0.0
        }

        # Update stats
        stats[:last_updated] = Time.now.iso8601
        @cache.cache_command_stats(stats)

        stats
      end

      private

      def generate_command_hash(command_string)
        # Create a hash based on command string and robot state
        robot_state = get_robot_state_for_hash
        data_to_hash = "#{command_string}:#{robot_state}"
        Digest::SHA256.hexdigest(data_to_hash)
      end

      def get_robot_state_for_hash
        robot = @processor.robot
        return 'unplaced' unless robot.placed?

        "#{robot.position.x},#{robot.position.y},#{robot.direction.name}"
      end

      def cache_command_result(command_hash, command_string, result)
        cache_data = {
          command: command_string,
          result: result,
          robot_state: get_robot_state_for_hash,
          timestamp: Time.now.iso8601,
          execution_time: result[:execution_time] || 0.0
        }

        @cache.cache_command_result(command_hash, cache_data)
        log_cache_miss(command_string, cache_data)
      rescue StandardError => e
        log_cache_error('cache_command_result', command_string, e)
      end

      def log_cache_hit(command_string, _cached_result)
        return unless ENV['ROBOT_CACHE_DEBUG']

        puts "[CACHE_HIT] Command: #{command_string} - Using cached result"
      end

      def log_cache_miss(command_string, _cache_data)
        return unless ENV['ROBOT_CACHE_DEBUG']

        puts "[CACHE_MISS] Command: #{command_string} - Cached new result"
      end

      def log_cache_error(operation, command_string, error)
        puts "[CACHED_COMMAND_PROCESSOR_ERROR] #{operation}: #{command_string} - #{error.message}"
      end
    end
  end
end
