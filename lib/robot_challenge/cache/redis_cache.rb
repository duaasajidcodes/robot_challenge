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
      end

      # Cache robot state
      def cache_robot_state(robot_id, state)
        key = build_key("robot:#{robot_id}:state")
        @redis.setex(key, @cache_ttl, state.to_json)
        log_cache_operation('cache_robot_state', key, state)
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
      rescue JSON::ParserError => e
        log_cache_error('get_robot_state', key, e)
        nil
      end

      # Cache command result
      def cache_command_result(command_hash, result)
        key = build_key("command:#{command_hash}")
        @redis.setex(key, @cache_ttl, result.to_json)
        log_cache_operation('cache_command_result', key, result)
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
      rescue JSON::ParserError => e
        log_cache_error('get_cached_result', key, e)
        nil
      end

      # Cache table state
      def cache_table_state(table_id, state)
        key = build_key("table:#{table_id}:state")
        @redis.setex(key, @cache_ttl, state.to_json)
        log_cache_operation('cache_table_state', key, state)
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
      rescue JSON::ParserError => e
        log_cache_error('get_table_state', key, e)
        nil
      end

      # Cache command statistics
      def cache_command_stats(stats)
        key = build_key('stats:commands')
        @redis.setex(key, @cache_ttl, stats.to_json)
        log_cache_operation('cache_command_stats', key, stats)
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
      rescue JSON::ParserError => e
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
      end

      # Invalidate table cache
      def invalidate_table_cache(table_id)
        pattern = build_key("table:#{table_id}:*")
        keys = @redis.keys(pattern)
        return unless keys.any?

        @redis.del(*keys)
        log_cache_operation('invalidate_table_cache', pattern, "Deleted #{keys.length} keys")
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
        # This is a simplified hit rate calculation
        # In production, you'd track hits/misses over time
        total_operations = @redis.get(build_key('stats:total_operations')).to_i
        total_hits = @redis.get(build_key('stats:total_hits')).to_i

        return 0.0 if total_operations.zero?

        (total_hits.to_f / total_operations * 100).round(2)
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
    end
  end
end
