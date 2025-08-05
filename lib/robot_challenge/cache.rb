# frozen_string_literal: true

begin
  require_relative 'cache/redis_cache'
  REDIS_CACHE_AVAILABLE = true
rescue LoadError
  REDIS_CACHE_AVAILABLE = false
end

require_relative 'cache/cacheable_robot'
require_relative 'cache/cached_command_processor'

module RobotChallenge
  module Cache
    # Create a new Redis cache instance
    def self.create_redis_cache(redis_url: nil, cache_ttl: 3600, namespace: 'robot_challenge')
      if REDIS_CACHE_AVAILABLE
        RedisCache.new(redis_url: redis_url, cache_ttl: cache_ttl, namespace: namespace)
      else
        # Return a mock cache when Redis is not available
        create_mock_cache
      end
    end

    # Create a cacheable robot
    def self.create_cacheable_robot(robot, cache: nil, robot_id: nil)
      CacheableRobot.new(robot, cache: cache, robot_id: robot_id)
    end

    # Create a cached command processor
    def self.create_cached_processor(processor, cache: nil)
      CachedCommandProcessor.new(processor, cache: cache)
    end

    # Check if Redis is available
    def self.redis_available?(redis_url: nil)
      return false unless REDIS_CACHE_AVAILABLE

      cache = create_redis_cache(redis_url: redis_url)
      cache.available?
    rescue StandardError
      false
    end

    # Get cache health status
    def self.health_check(redis_url: nil)
      unless REDIS_CACHE_AVAILABLE
        return {
          available: false,
          error: 'Redis gem not available',
          connection_info: { error: 'Redis gem not available' },
          cache_stats: { error: 'Redis gem not available' }
        }
      end

      cache = create_redis_cache(redis_url: redis_url)
      cache.health_check
    rescue StandardError => e
      {
        available: false,
        error: e.message,
        connection_info: { error: 'Unable to connect' },
        cache_stats: { error: 'Unable to get stats' }
      }
    end

    # Clear all cache
    def self.clear_all_cache(redis_url: nil, namespace: 'robot_challenge')
      return unless REDIS_CACHE_AVAILABLE

      cache = create_redis_cache(redis_url: redis_url, namespace: namespace)
      cache.clear_all_cache
    end

    # Get cache statistics
    def self.cache_stats(redis_url: nil, namespace: 'robot_challenge')
      unless REDIS_CACHE_AVAILABLE
        return {
          error: 'Redis gem not available',
          total_keys: 0,
          memory_usage: 'Unknown',
          hit_rate: 0.0,
          keys_by_type: {}
        }
      end

      cache = create_redis_cache(redis_url: redis_url, namespace: namespace)
      cache.cache_stats
    rescue StandardError => e
      {
        error: e.message,
        total_keys: 0,
        memory_usage: 'Unknown',
        hit_rate: 0.0,
        keys_by_type: {}
      }
    end

    # Create a mock cache when Redis is not available
    def self.create_mock_cache
      mock_cache = Object.new

      def mock_cache.cache_robot_state(robot_id, state)
        # No-op
      end

      def mock_cache.get_robot_state(_robot_id)
        nil
      end

      def mock_cache.set_command_result(command_key, result)
        # No-op
      end

      def mock_cache.get_command_result(_command_key)
        nil
      end

      def mock_cache.cache_table_state(table_id, state)
        # No-op
      end

      def mock_cache.get_table_state(_table_id)
        nil
      end

      def mock_cache.invalidate_robot_cache(robot_id)
        # No-op
      end

      def mock_cache.invalidate_table_cache(table_id)
        # No-op
      end

      def mock_cache.clear_all_cache
        # No-op
      end

      def mock_cache.cache_stats
        {
          error: 'Redis gem not available',
          total_keys: 0,
          memory_usage: 'Unknown',
          hit_rate: 0.0,
          keys_by_type: {}
        }
      end

      def mock_cache.available?
        false
      end

      def mock_cache.health_check
        {
          available: false,
          error: 'Redis gem not available',
          connection_info: { error: 'Redis gem not available' },
          cache_stats: { error: 'Redis gem not available' }
        }
      end

      mock_cache
    end
  end
end
