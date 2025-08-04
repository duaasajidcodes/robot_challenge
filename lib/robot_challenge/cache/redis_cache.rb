# frozen_string_literal: true

require 'redis'
require 'json'

module RobotChallenge
  module Cache
    # Redis-based caching system for robot challenge
    class RedisCache
      attr_reader :redis, :cache_ttl, :namespace

      def initialize(redis_url: nil, cache_ttl: 3600, namespace: 'robot_challenge')
        @redis = Redis.new(url: redis_url || ENV['REDIS_URL'] || 'redis://localhost:6379')
        @cache_ttl = cache_ttl
        @namespace = namespace
      rescue Redis::BaseError => e
        # Fallback to mock Redis if Redis is not available
        @redis = create_mock_redis
        @cache_ttl = cache_ttl
        @namespace = namespace
      end

      # Cache robot state
      def cache_robot_state(robot_id, state)
        key = build_key("robot:#{robot_id}:state")
        @redis.setex(key, @cache_ttl, state.to_json)
        log_cache_operation('cache_robot_state', key, state)
      rescue Redis::BaseError => e
        log_cache_error('cache_robot_state', key, e)
      end

      # Get cached robot state
      def get_robot_state(robot_id)
        key = build_key("robot:#{robot_id}:state")
        data = @redis.get(key)
        if data
          log_cache_operation('get_robot_state', key, 'HIT')
          JSON.parse(data, symbolize_names: true)
        else
          log_cache_operation('get_robot_state', key, 'MISS')
          nil
        end
      rescue JSON::ParserError, Redis::BaseError => e
        log_cache_error('get_robot_state', key, e)
        nil
      end

      # Cache command result
      def cache_command_result(command_hash, result)
        key = build_key("command:#{command_hash}")
        @redis.setex(key, @cache_ttl, result.to_json)
        log_cache_operation('cache_command_result', key, result)
      rescue Redis::BaseError => e
        log_cache_error('cache_command_result', key, e)
      end

      # Get cached command result
      def get_cached_result(command_hash)
        key = build_key("command:#{command_hash}")
        data = @redis.get(key)
        if data
          log_cache_operation('get_cached_result', key, 'HIT')
          JSON.parse(data, symbolize_names: true)
        else
          log_cache_operation('get_cached_result', key, 'MISS')
          nil
        end
      rescue JSON::ParserError, Redis::BaseError => e
        log_cache_error('get_cached_result', key, e)
        nil
      end

      # Cache table state
      def cache_table_state(table_id, state)
        key = build_key("table:#{table_id}:state")
        @redis.setex(key, @cache_ttl, state.to_json)
        log_cache_operation('cache_table_state', key, state)
      rescue Redis::BaseError => e
        log_cache_error('cache_table_state', key, e)
      end

      # Get cached table state
      def get_table_state(table_id)
        key = build_key("table:#{table_id}:state")
        data = @redis.get(key)
        if data
          log_cache_operation('get_table_state', key, 'HIT')
          JSON.parse(data, symbolize_names: true)
        else
          log_cache_operation('get_table_state', key, 'MISS')
          nil
        end
      rescue JSON::ParserError, Redis::BaseError => e
        log_cache_error('get_table_state', key, e)
        nil
      end

      # Cache command statistics
      def cache_command_stats(stats)
        key = build_key('stats:commands')
        @redis.setex(key, @cache_ttl, stats.to_json)
        log_cache_operation('cache_command_stats', key, stats)
      rescue Redis::BaseError => e
        log_cache_error('cache_command_stats', key, e)
      end

      # Get cached command statistics
      def get_command_stats
        key = build_key('stats:commands')
        data = @redis.get(key)
        if data
          log_cache_operation('get_command_stats', key, 'HIT')
          JSON.parse(data, symbolize_names: true)
        else
          log_cache_operation('get_command_stats', key, 'MISS')
          nil
        end
      rescue JSON::ParserError, Redis::BaseError => e
        log_cache_error('get_command_stats', key, e)
        nil
      end

      # Invalidate robot cache
      def invalidate_robot_cache(robot_id)
        pattern = build_key("robot:#{robot_id}:*")
        keys = @redis.keys(pattern)
        return unless keys.any?

        @redis.del(*keys)
        log_cache_operation('invalidate_robot_cache', pattern, "Deleted #{keys.length} keys")
      rescue Redis::BaseError => e
        log_cache_error('invalidate_robot_cache', pattern, e)
      end

      # Invalidate table cache
      def invalidate_table_cache(table_id)
        pattern = build_key("table:#{table_id}:*")
        keys = @redis.keys(pattern)
        return unless keys.any?

        @redis.del(*keys)
        log_cache_operation('invalidate_table_cache', pattern, "Deleted #{keys.length} keys")
      rescue Redis::BaseError => e
        log_cache_error('invalidate_table_cache', pattern, e)
      end

      # Clear all cache
      def clear_all_cache
        pattern = build_key('*')
        keys = @redis.keys(pattern)
        return unless keys.any?

        @redis.del(*keys)
        log_cache_operation('clear_all_cache', pattern, "Deleted #{keys.length} keys")
      rescue Redis::BaseError => e
        log_cache_error('clear_all_cache', pattern, e)
      end

      # Get cache statistics
      def cache_stats
        pattern = build_key('*')
        keys = @redis.keys(pattern)

        stats = {
          total_keys: keys.length,
          memory_usage: @redis.info['used_memory_human'],
          hit_rate: calculate_hit_rate,
          keys_by_type: categorize_keys(keys)
        }

        log_cache_operation('cache_stats', 'stats', stats)
        stats
      rescue Redis::BaseError => e
        log_cache_error('cache_stats', 'stats', e)
        {
          total_keys: 0,
          memory_usage: 'Unknown',
          hit_rate: 0.0,
          keys_by_type: {}
        }
      end

      # Check if Redis is available
      def available?
        @redis.ping == 'PONG'
      rescue Redis::BaseError
        false
      end

      # Health check
      def health_check
        {
          available: available?,
          connection_info: connection_info,
          cache_stats: cache_stats
        }
      rescue Redis::BaseError => e
        {
          available: false,
          error: e.message,
          connection_info: { error: 'Unable to connect' },
          cache_stats: { error: 'Unable to get stats' }
        }
      end

      private

      def build_key(key)
        "#{@namespace}:#{key}"
      end

      def log_cache_operation(operation, key, data)
        return unless ENV['ROBOT_CACHE_DEBUG']

        puts "[CACHE] #{operation}: #{key} - #{data.class}"
      end

      def log_cache_error(operation, key, error)
        puts "[CACHE_ERROR] #{operation}: #{key} - #{error.message}"
      end

      def calculate_hit_rate
        total_operations = @redis.get(build_key('stats:total_operations')).to_i
        total_hits = @redis.get(build_key('stats:total_hits')).to_i

        return 0.0 if total_operations.zero?

        (total_hits.to_f / total_operations * 100).round(2)
      rescue Redis::BaseError
        0.0
      end

      def categorize_keys(keys)
        categories = Hash.new(0)
        keys.each do |key|
          if key.include?(':robot:')
            categories[:robot] += 1
          elsif key.include?(':table:')
            categories[:table] += 1
          elsif key.include?(':command:')
            categories[:command] += 1
          elsif key.include?(':stats:')
            categories[:stats] += 1
          else
            categories[:other] += 1
          end
        end
        categories
      end

      def connection_info
        {
          host: @redis.client.host,
          port: @redis.client.port,
          db: @redis.client.db,
          timeout: @redis.client.timeout
        }
      rescue StandardError
        { error: 'Unable to get connection info' }
      end

      def create_mock_redis
        # Create a simple mock Redis for when Redis is not available
        Class.new do
          def initialize
            @data = {}
          end

          def setex(key, ttl, value)
            @data[key] = { value: value, expires_at: Time.now + ttl }
          end

          def get(key)
            data = @data[key]
            return nil unless data
            return nil if data[:expires_at] < Time.now
            data[:value]
          end

          def del(*keys)
            keys.count { |key| @data.delete(key) }
          end

          def keys(pattern)
            @data.keys.select { |key| File.fnmatch(pattern, key) }
          end

          def info
            { 'used_memory_human' => '0B' }
          end

          def ping
            'PONG'
          end

          def client
            OpenStruct.new(
              host: 'localhost',
              port: 6379,
              db: 0,
              timeout: 5
            )
          end
        end.new
      end
    end
  end
end
