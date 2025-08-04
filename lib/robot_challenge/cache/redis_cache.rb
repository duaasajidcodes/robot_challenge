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
      rescue Redis::BaseError
        # Fallback to mock Redis if Redis is not available
        @redis = create_mock_redis
        @cache_ttl = cache_ttl
        @namespace = namespace
      end

      # Cache robot state
      def cache_robot_state(robot_id, state)
        key = build_key("robot:#{robot_id}:state")
        @redis.setex(key, @cache_ttl, state.to_json)
        log_cache_operation('cache_robot_state', key, "Cached robot state for #{robot_id}")
      end

      # Get cached robot state
      def robot_state(robot_id)
        key = build_key("robot:#{robot_id}:state")
        data = @redis.get(key)
        return nil unless data

        JSON.parse(data, symbolize_names: true)
      rescue JSON::ParserError
        nil
      end

      # Alias for robot_state
      def get_robot_state(robot_id)
        robot_state(robot_id)
      end

      # Cache command result
      def set_command_result(command_key, result)
        key = build_key("command:#{command_key}")
        @redis.setex(key, @cache_ttl, result.to_json)
        log_cache_operation('set_command_result', key, 'Cached command result')
      end

      # Get cached command result
      def command_result(command_key)
        key = build_key("command:#{command_key}")
        data = @redis.get(key)
        return nil unless data

        JSON.parse(data, symbolize_names: true)
      rescue JSON::ParserError
        nil
      end

      # Alias for command_result
      def get_cached_result(command_key)
        command_result(command_key)
      end

      # Cache table state
      def cache_table_state(table_id, state)
        key = build_key("table:#{table_id}:state")
        @redis.setex(key, @cache_ttl, state.to_json)
        log_cache_operation('cache_table_state', key, "Cached table state for #{table_id}")
      end

      # Get cached table state
      def table_state(table_id)
        key = build_key("table:#{table_id}:state")
        data = @redis.get(key)
        return nil unless data

        JSON.parse(data, symbolize_names: true)
      rescue JSON::ParserError
        nil
      end

      # Alias for table_state
      def get_table_state(table_id)
        table_state(table_id)
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

      # Invalidate command cache
      def invalidate_command_cache(command_pattern)
        pattern = build_key("command:#{command_pattern}")
        keys = @redis.keys(pattern)
        return unless keys.any?

        @redis.del(*keys)
        log_cache_operation('invalidate_command_cache', pattern, "Deleted #{keys.length} keys")
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
        total_keys = keys.length

        keys_by_type = {
          robot: keys.count { |k| k.include?('robot:') },
          command: keys.count { |k| k.include?('command:') },
          table: keys.count { |k| k.include?('table:') }
        }

        stats = {
          total_keys: total_keys,
          memory_usage: '0B', # Default value
          hit_rate: 0.0, # Default value
          keys_by_type: keys_by_type,
          robot_keys: keys_by_type[:robot],
          command_keys: keys_by_type[:command],
          table_keys: keys_by_type[:table],
          cache_ttl: @cache_ttl,
          namespace: @namespace,
          timestamp: Time.now.iso8601
        }

        # Add Redis-specific stats if available
        begin
          info = @redis.info
          stats[:redis_version] = info['redis_version']
          stats[:used_memory] = info['used_memory_human']
          stats[:connected_clients] = info['connected_clients']
          stats[:memory_usage] = info['used_memory_human']
        rescue StandardError
          # Ignore Redis info errors
        end

        stats
      end

      # Health check
      def health_check
        @redis.ping
        cache_stats_data = cache_stats
        {
          available: true,
          connection_info: {
            redis_version: cache_stats_data[:redis_version],
            connected_clients: cache_stats_data[:connected_clients],
            used_memory: cache_stats_data[:used_memory]
          },
          cache_stats: cache_stats_data,
          status: 'healthy',
          redis_available: true,
          timestamp: Time.now.iso8601
        }
      rescue StandardError => e
        {
          available: false,
          connection_info: { error: e.message },
          cache_stats: { total_keys: 0, memory_usage: '0B', hit_rate: 0.0, keys_by_type: {} },
          status: 'unhealthy',
          redis_available: false,
          error: e.message,
          timestamp: Time.now.iso8601
        }
      end

      # Check if Redis is available
      def available?
        @redis.ping
        true
      rescue StandardError
        false
      end

      # Get command statistics
      def command_stats
        pattern = build_key('command:*')
        keys = @redis.keys(pattern)
        total_commands = keys.length

        stats = {
          total_commands: total_commands,
          cached_commands: total_commands,
          cache_hits: 0, # This would need to be tracked separately
          cache_misses: 0, # This would need to be tracked separately
          average_execution_time: 0.0, # This would need to be calculated from cached data
          last_updated: Time.now.iso8601
        }

        # Try to get more detailed stats from cached data
        begin
          execution_times = []
          keys.each do |key|
            data = @redis.get(key)
            next unless data

            parsed_data = JSON.parse(data, symbolize_names: true)
            execution_times << parsed_data[:execution_time] if parsed_data[:execution_time]
          end

          stats[:average_execution_time] = execution_times.sum / execution_times.length if execution_times.any?
        rescue StandardError
          # Ignore parsing errors
        end

        stats
      end

      # Cache command statistics
      def cache_command_stats(stats)
        key = build_key('stats:commands')
        @redis.setex(key, @cache_ttl, stats.to_json)
      end

      # Get cached command statistics
      def cached_command_stats
        key = build_key('stats:commands')
        data = @redis.get(key)
        return nil unless data

        JSON.parse(data, symbolize_names: true)
      rescue JSON::ParserError
        nil
      end

      # Cache command result with detailed information
      def cache_command_result(command_hash, cache_data)
        key = build_key("command:#{command_hash}")
        @redis.setex(key, @cache_ttl, cache_data.to_json)
        log_cache_operation('cache_command_result', key, 'Cached command result')
      end

      # Get cached result
      def cached_result(command_hash)
        key = build_key("command:#{command_hash}")
        data = @redis.get(key)
        return nil unless data

        JSON.parse(data, symbolize_names: true)
      rescue JSON::ParserError
        nil
      end

      # Invalidate command cache by hash
      def invalidate_command_cache_by_hash(command_hash)
        key = build_key("command:#{command_hash}")
        @redis.del(key)
        log_cache_operation('invalidate_command_cache_by_hash', key, 'Deleted command cache')
      end

      private

      def build_key(key_suffix)
        "#{@namespace}:#{key_suffix}"
      end

      def log_cache_operation(operation, key, message)
        return unless ENV['ROBOT_CACHE_DEBUG']

        puts "[REDIS_CACHE] #{operation}: #{key} - #{message}"
      end

      def create_mock_redis
        # Create a simple mock Redis implementation for testing
        mock_redis = Object.new

        def mock_redis.setex(key, ttl, value)
          @mock_data ||= {}
          @mock_data[key] = { value: value, expires_at: Time.now + ttl }
        end

        def mock_redis.get(key)
          @mock_data ||= {}
          data = @mock_data[key]
          return nil unless data && data[:expires_at] > Time.now

          data[:value]
        end

        def mock_redis.del(*keys)
          @mock_data ||= {}
          deleted_count = 0
          keys.each do |key|
            deleted_count += 1 if @mock_data.delete(key)
          end
          deleted_count
        end

        def mock_redis.keys(pattern)
          @mock_data ||= {}
          pattern_regex = pattern.gsub('*', '.*')
          @mock_data.keys.grep(pattern_regex)
        end

        def mock_redis.ping
          'PONG'
        end

        def mock_redis.info
          {
            'redis_version' => 'mock',
            'used_memory_human' => '0B',
            'connected_clients' => '1'
          }
        end

        mock_redis
      end
    end
  end
end
