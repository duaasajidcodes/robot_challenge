# frozen_string_literal: true

begin
  require 'redis'
  REDIS_AVAILABLE = true
rescue LoadError
  REDIS_AVAILABLE = false
end

require 'json'

module RobotChallenge
  module Cache
    class CacheStatsBuilder
      def initialize(redis, namespace, cache_ttl)
        @redis = redis
        @namespace = namespace
        @cache_ttl = cache_ttl
      end

      def build
        pattern = "#{@namespace}:*"
        keys = @redis.keys(pattern)
        keys_by_type = categorize_keys(keys)

        base_stats = create_base_stats(keys, keys_by_type)
        add_redis_specific_stats(base_stats)
      end

      private

      def categorize_keys(keys)
        {
          robot: keys.count { |k| k.include?('robot:') },
          command: keys.count { |k| k.include?('command:') },
          table: keys.count { |k| k.include?('table:') }
        }
      end

      def create_base_stats(keys, keys_by_type)
        {
          total_keys: keys.length,
          memory_usage: '0B',
          hit_rate: 0.0,
          keys_by_type: keys_by_type,
          robot_keys: keys_by_type[:robot],
          command_keys: keys_by_type[:command],
          table_keys: keys_by_type[:table],
          cache_ttl: @cache_ttl,
          namespace: @namespace,
          timestamp: Time.now.iso8601
        }
      end

      def add_redis_specific_stats(stats)
        info = @redis.info
        stats.merge!(
          redis_version: info['redis_version'],
          used_memory: info['used_memory_human'],
          connected_clients: info['connected_clients'],
          memory_usage: info['used_memory_human']
        )
        stats
      rescue StandardError
        stats
      end
    end

    # Health checker for Redis cache
    class CacheHealthChecker
      def initialize(redis, stats_builder)
        @redis = redis
        @stats_builder = stats_builder
      end

      def check
        @redis.ping
        cache_stats_data = @stats_builder.build
        create_healthy_response(cache_stats_data)
      rescue StandardError => e
        create_unhealthy_response(e)
      end

      private

      def create_healthy_response(cache_stats_data)
        {
          available: true,
          connection_info: extract_connection_info(cache_stats_data),
          cache_stats: cache_stats_data,
          status: 'healthy',
          redis_available: true,
          timestamp: Time.now.iso8601
        }
      end

      def create_unhealthy_response(error)
        {
          available: false,
          connection_info: { error: error.message },
          cache_stats: default_cache_stats,
          status: 'unhealthy',
          redis_available: false,
          error: error.message,
          timestamp: Time.now.iso8601
        }
      end

      def extract_connection_info(cache_stats_data)
        {
          redis_version: cache_stats_data[:redis_version],
          connected_clients: cache_stats_data[:connected_clients],
          used_memory: cache_stats_data[:used_memory]
        }
      end

      def default_cache_stats
        {
          total_keys: 0,
          memory_usage: '0B',
          hit_rate: 0.0,
          keys_by_type: {}
        }
      end
    end

    # Mock Redis implementation
    class MockRedis
      def initialize
        @data = {}
      end

      def setex(key, ttl, value)
        @data[key] = { value: value, expires_at: Time.now + ttl }
      end

      def get(key)
        entry = @data[key]
        return nil unless entry && entry[:expires_at] > Time.now

        entry[:value]
      end

      def del(*keys)
        keys.count { |key| @data.delete(key) }
      end

      def keys(pattern)
        pattern_regex = Regexp.new(pattern.gsub('*', '.*'))
        @data.keys.grep(pattern_regex)
      end

      def ping
        'PONG'
      end

      def info
        {
          'redis_version' => 'mock-1.0.0',
          'used_memory_human' => '1KB',
          'connected_clients' => '1'
        }
      end
    end

    # Redis-based caching system for robot challenge
    class RedisCache
      attr_reader :redis, :cache_ttl, :namespace

      def initialize(redis_url: nil, cache_ttl: 3600, namespace: 'robot_challenge')
        @cache_ttl = cache_ttl
        @namespace = namespace
        @redis = setup_redis_connection(redis_url)
        @stats_builder = CacheStatsBuilder.new(@redis, @namespace, @cache_ttl)
        @health_checker = CacheHealthChecker.new(@redis, @stats_builder)
      end

      # Cache robot state
      def cache_robot_state(robot_id, state)
        key = build_key("robot:#{robot_id}:state")
        store_data(key, state, "Cached robot state for #{robot_id}")
      end

      # Get cached robot state
      def robot_state(robot_id)
        key = build_key("robot:#{robot_id}:state")
        retrieve_data(key)
      end
      alias get_robot_state robot_state

      # Cache command result
      def cache_command_result(command_key, result)
        key = build_key("command:#{command_key}")
        store_data(key, result, 'Cached command result')
      end

      # Get cached command result
      def command_result(command_key)
        key = build_key("command:#{command_key}")
        retrieve_data(key)
      end
      alias get_cached_result command_result
      alias get_command_result command_result
      alias set_command_result cache_command_result

      # Cache table state
      def cache_table_state(table_id, state)
        key = build_key("table:#{table_id}:state")
        store_data(key, state, "Cached table state for #{table_id}")
      end

      # Get cached table state
      def table_state(table_id)
        key = build_key("table:#{table_id}:state")
        retrieve_data(key)
      end
      alias get_table_state table_state

      # Invalidate robot cache
      def invalidate_robot_cache(robot_id)
        invalidate_cache_by_pattern("robot:#{robot_id}:*", 'robot')
      end

      # Invalidate table cache
      def invalidate_table_cache(table_id)
        invalidate_cache_by_pattern("table:#{table_id}:*", 'table')
      end

      # Invalidate command cache
      def invalidate_command_cache(command_pattern)
        invalidate_cache_by_pattern("command:#{command_pattern}", 'command')
      end

      # Invalidate command cache by hash
      def invalidate_command_cache_by_hash(command_hash)
        key = build_key("command:#{command_hash}")
        @redis.del(key)
        log_cache_operation('invalidate_command_cache_by_hash', key, 'Deleted command cache')
      end

      # Clear all cache
      def clear_all_cache
        pattern = build_key('*')
        keys = @redis.keys(pattern)
        return unless keys.any?

        @redis.del(*keys)
        log_cache_operation('clear_all_cache', pattern, "Deleted #{keys.length} keys")
      end

      # Get cache statistics
      def cache_stats
        @stats_builder.build
      end

      # Health check
      def health_check
        @health_checker.check
      end

      # Check if Redis is available
      def available?
        @redis.ping
        true
      rescue StandardError
        false
      end

      # Cache command statistics
      def cache_command_stats(stats)
        key = build_key('stats:commands')
        store_data(key, stats, 'Cached command statistics')
      end

      # Get cached command statistics
      def cached_command_stats
        key = build_key('stats:commands')
        retrieve_data(key)
      end

      # Get cached result (alias for compatibility)
      def cached_result(command_hash)
        command_result(command_hash)
      end

      # Get command statistics
      def command_stats
        pattern = build_key('command:*')
        keys = @redis.keys(pattern)

        {
          total_commands: keys.length,
          cached_commands: keys.length,
          cache_hits: 0,
          cache_misses: 0,
          average_execution_time: 0.0,
          last_updated: Time.now.iso8601
        }
      end

      private

      def setup_redis_connection(redis_url)
        return MockRedis.new unless REDIS_AVAILABLE

        Redis.new(url: redis_url || ENV['REDIS_URL'] || 'redis://localhost:6379')
      rescue Redis::BaseError
        MockRedis.new
      end

      def store_data(key, data, log_message)
        @redis.setex(key, @cache_ttl, data.to_json)
        log_cache_operation('store_data', key, log_message)
      end

      def retrieve_data(key)
        data = @redis.get(key)
        return nil unless data

        JSON.parse(data, symbolize_names: true)
      rescue JSON::ParserError
        nil
      end

      def invalidate_cache_by_pattern(pattern, cache_type)
        full_pattern = build_key(pattern)
        keys = @redis.keys(full_pattern)
        return unless keys.any?

        @redis.del(*keys)
        log_cache_operation("invalidate_#{cache_type}_cache", full_pattern, "Deleted #{keys.length} keys")
      end

      def build_key(key_suffix)
        "#{@namespace}:#{key_suffix}"
      end

      def log_cache_operation(operation, key, message)
        return unless ENV['ROBOT_CACHE_DEBUG']

        puts "[REDIS_CACHE] #{operation}: #{key} - #{message}"
      end
    end
  end
end
