# frozen_string_literal: true

require 'simplecov'

if ENV['COVERAGE']
  SimpleCov.start do
    add_filter '/spec/'
    add_filter '/vendor/'
    
    # Set coverage thresholds based on environment
    if ENV['CI']
      minimum_coverage 85  # Slightly lower for CI stability
    else
      minimum_coverage 90
      refuse_coverage_drop
    end
  end
end

require_relative '../lib/robot_challenge'
require_relative 'test_helper'

# Mock Redis for tests if not available
begin
  require 'redis'
  # Test Redis connection
  redis = Redis.new(url: ENV['REDIS_URL'] || 'redis://localhost:6379')
  redis.ping
  ENV['REDIS_AVAILABLE'] = 'true'
rescue LoadError, Redis::BaseError => e
  puts "Warning: Redis not available for tests: #{e.message}"
  puts 'Cache tests will use mocks instead.'
  ENV['REDIS_AVAILABLE'] = 'false'

  # Mock Redis class for tests
  unless defined?(Redis)
    class Redis
      class BaseError < StandardError; end

      def initialize(url: nil)
        @url = url
        @data = {}
      end

      def ping
        'PONG'
      end

      def setex(key, ttl, value)
        @data[key] = { value: value, expires_at: Time.now + ttl }
      end

      def set(key, value)
        @data[key] = { value: value, expires_at: Time.now + 3600 } # Default 1 hour TTL
      end

      def get(key)
        data = @data[key]
        return nil unless data
        return nil if data[:expires_at] < Time.now

        data[:value]
      end

      def exists(key)
        @data.key?(key) && @data[key][:expires_at] > Time.now
      end

      def del(*keys)
        keys.count { |key| @data.delete(key) }
      end

      def keys(pattern)
        @data.keys.select { |key| File.fnmatch(pattern, key) }
      end

      def info
        { 'used_memory_human' => '1.2MB' }
      end

      def client
        OpenStruct.new(
          host: 'localhost',
          port: 6379,
          db: 0,
          timeout: 5,
          url: @url
        )
      end
    end
  end
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on Module and main
  config.disable_monkey_patching!

  # Use expect syntax instead of should
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Filter out system gems from backtraces
  config.filter_gems_from_backtrace 'bundler'

  # Color output
  config.color = true

  # Format output
  config.formatter = :documentation

  # Setup for cache tests
  config.before(:each, type: :cache) do
    # Clear any existing cache data
    if ENV['REDIS_AVAILABLE'] == 'true'
      begin
        cache = RobotChallenge::Cache.create_redis_cache(namespace: 'test_robot_challenge')
        cache.clear_all_cache
      rescue StandardError
        # Ignore errors if Redis is not available
      end
    end
  end

  config.after(:each, type: :cache) do
    # Clean up cache data after each test
    if ENV['REDIS_AVAILABLE'] == 'true'
      begin
        cache = RobotChallenge::Cache.create_redis_cache(namespace: 'test_robot_challenge')
        cache.clear_all_cache
      rescue StandardError
        # Ignore errors if Redis is not available
      end
    end
  end
end
