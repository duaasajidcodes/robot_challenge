# frozen_string_literal: true

require_relative 'cache/redis_cache'
require_relative 'cache/cacheable_robot'
require_relative 'cache/cached_command_processor'

module RobotChallenge
  module Cache
    # Create a new Redis cache instance
    def self.create_redis_cache(redis_url: nil, cache_ttl: 3600, namespace: 'robot_challenge')
      RedisCache.new(redis_url: redis_url, cache_ttl: cache_ttl, namespace: namespace)
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
      cache = create_redis_cache(redis_url: redis_url)
      cache.available?
    rescue StandardError
      false
    end

    # Get cache health status
    def self.health_check(redis_url: nil)
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
      cache = create_redis_cache(redis_url: redis_url, namespace: namespace)
      cache.clear_all_cache
    end

    # Get cache statistics
    def self.cache_stats(redis_url: nil, namespace: 'robot_challenge')
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
  end
end
