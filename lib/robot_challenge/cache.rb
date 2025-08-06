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
        MockCacheProvider.new
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
      return unavailable_health_response('Redis gem not available') unless REDIS_CACHE_AVAILABLE

      cache = create_redis_cache(redis_url: redis_url)
      cache.health_check
    rescue StandardError => e
      unavailable_health_response(e.message)
    end

    # Clear all cache
    def self.clear_all_cache(redis_url: nil, namespace: 'robot_challenge')
      return unless REDIS_CACHE_AVAILABLE

      cache = create_redis_cache(redis_url: redis_url, namespace: namespace)
      cache.clear_all_cache
    end

    # Get cache statistics
    def self.cache_stats(redis_url: nil, namespace: 'robot_challenge')
      return unavailable_stats_response('Redis gem not available') unless REDIS_CACHE_AVAILABLE

      cache = create_redis_cache(redis_url: redis_url, namespace: namespace)
      cache.cache_stats
    rescue StandardError => e
      unavailable_stats_response(e.message)
    end

    # Private helper methods
    class << self
      private

      def unavailable_health_response(error_message)
        {
          available: false,
          error: error_message,
          connection_info: { error: error_message },
          cache_stats: { error: error_message }
        }
      end

      def unavailable_stats_response(error_message)
        {
          error: error_message,
          total_keys: 0,
          memory_usage: 'Unknown',
          hit_rate: 0.0,
          keys_by_type: {}
        }
      end
    end

    # Mock cache provider when Redis is not available
    class MockCacheProvider
      def cache_robot_state(_robot_id, _state)
        # No-op for mock implementation
      end

      def get_robot_state(_robot_id)
        nil
      end

      def set_command_result(_command_key, _result)
        # No-op for mock implementation
      end

      def get_command_result(_command_key)
        nil
      end

      def cache_table_state(_table_id, _state)
        # No-op for mock implementation
      end

      def get_table_state(_table_id)
        nil
      end

      def invalidate_robot_cache(_robot_id)
        # No-op for mock implementation
      end

      def invalidate_table_cache(_table_id)
        # No-op for mock implementation
      end

      def clear_all_cache
        # No-op for mock implementation
      end

      def cache_stats
        default_unavailable_stats
      end

      def available?
        false
      end

      def health_check
        default_unavailable_health
      end

      private

      def default_unavailable_stats
        {
          error: 'Redis not available',
          total_keys: 0,
          memory_usage: 'Unknown',
          hit_rate: 0.0,
          keys_by_type: {}
        }
      end

      def default_unavailable_health
        {
          available: false,
          error: 'Redis not available',
          connection_info: { error: 'Redis not available' },
          cache_stats: { error: 'Redis not available' }
        }
      end
    end
  end
end
