# frozen_string_literal: true

require 'spec_helper'
require 'securerandom'

RSpec.describe RobotChallenge::Cache do
  describe '.create_redis_cache' do
    it 'creates a Redis cache instance with default parameters' do
      cache = described_class.create_redis_cache
      expect(cache).to be_a(RobotChallenge::Cache::RedisCache)
      expect(cache.cache_ttl).to eq(3600)
      expect(cache.namespace).to eq('robot_challenge')
    end

    it 'creates a Redis cache instance with custom parameters' do
      cache = described_class.create_redis_cache(
        redis_url: 'redis://localhost:6379/1',
        cache_ttl: 1800,
        namespace: 'custom_namespace'
      )
      expect(cache).to be_a(RobotChallenge::Cache::RedisCache)
      expect(cache.cache_ttl).to eq(1800)
      expect(cache.namespace).to eq('custom_namespace')
    end
  end

  describe '.create_cacheable_robot' do
    let(:robot) { RobotChallenge::Robot.new(RobotChallenge::Table.new(5, 5)) }

    it 'creates a cacheable robot with default parameters' do
      cacheable_robot = described_class.create_cacheable_robot(robot)
      expect(cacheable_robot).to be_a(RobotChallenge::Cache::CacheableRobot)
      expect(cacheable_robot.robot).to eq(robot)
    end

    it 'creates a cacheable robot with custom parameters' do
      cache = described_class.create_redis_cache
      cacheable_robot = described_class.create_cacheable_robot(
        robot,
        cache: cache,
        robot_id: 'test_robot_123'
      )
      expect(cacheable_robot).to be_a(RobotChallenge::Cache::CacheableRobot)
      expect(cacheable_robot.robot).to eq(robot)
    end
  end

  describe '.create_cached_processor' do
    let(:processor) { RobotChallenge::CommandProcessor.new(RobotChallenge::Robot.new(RobotChallenge::Table.new(5, 5))) }

    it 'creates a cached command processor with default parameters' do
      cached_processor = described_class.create_cached_processor(processor)
      expect(cached_processor).to be_a(RobotChallenge::Cache::CachedCommandProcessor)
      expect(cached_processor.processor).to eq(processor)
    end

    it 'creates a cached command processor with custom cache' do
      cache = described_class.create_redis_cache
      cached_processor = described_class.create_cached_processor(processor, cache: cache)
      expect(cached_processor).to be_a(RobotChallenge::Cache::CachedCommandProcessor)
      expect(cached_processor.processor).to eq(processor)
    end
  end

  describe '.redis_available?' do
    context 'when Redis is available' do
      before do
        allow_any_instance_of(RobotChallenge::Cache::RedisCache).to receive(:available?).and_return(true)
      end

      it 'returns true' do
        expect(described_class.redis_available?).to be true
      end

      it 'returns true with custom Redis URL' do
        expect(described_class.redis_available?(redis_url: 'redis://localhost:6379/1')).to be true
      end
    end

    context 'when Redis is not available' do
      before do
        allow_any_instance_of(RobotChallenge::Cache::RedisCache).to receive(:available?).and_raise(StandardError,
                                                                                                   'Connection failed')
      end

      it 'returns false' do
        expect(described_class.redis_available?).to be false
      end

      it 'returns false with custom Redis URL' do
        expect(described_class.redis_available?(redis_url: 'redis://invalid:6379')).to be false
      end
    end
  end

  describe '.health_check' do
    context 'when Redis is available' do
      let(:health_info) do
        {
          available: true,
          connection_info: { host: 'localhost', port: 6379 },
          cache_stats: { total_keys: 10, memory_usage: '1.2MB' }
        }
      end

      before do
        allow_any_instance_of(RobotChallenge::Cache::RedisCache).to receive(:health_check).and_return(health_info)
      end

      it 'returns health information' do
        result = described_class.health_check
        expect(result).to eq(health_info)
      end

      it 'returns health information with custom Redis URL' do
        result = described_class.health_check(redis_url: 'redis://localhost:6379/1')
        expect(result).to eq(health_info)
      end
    end

    context 'when Redis is not available' do
      before do
        allow_any_instance_of(RobotChallenge::Cache::RedisCache).to receive(:health_check).and_raise(StandardError,
                                                                                                     'Connection failed')
      end

      it 'returns error information' do
        result = described_class.health_check
        expect(result[:available]).to be false
        expect(result[:error]).to eq('Connection failed')
        expect(result[:connection_info][:error]).to eq('Unable to connect')
        expect(result[:cache_stats][:error]).to eq('Unable to get stats')
      end
    end
  end

  describe '.clear_all_cache' do
    it 'clears all cache with default parameters' do
      cache_instance = instance_double(RobotChallenge::Cache::RedisCache)
      allow(RobotChallenge::Cache::RedisCache).to receive(:new).and_return(cache_instance)
      allow(cache_instance).to receive(:clear_all_cache)

      described_class.clear_all_cache

      expect(cache_instance).to have_received(:clear_all_cache)
    end

    it 'clears all cache with custom parameters' do
      cache_instance = instance_double(RobotChallenge::Cache::RedisCache)
      allow(RobotChallenge::Cache::RedisCache).to receive(:new).and_return(cache_instance)
      allow(cache_instance).to receive(:clear_all_cache)

      described_class.clear_all_cache(
        redis_url: 'redis://localhost:6379/1',
        namespace: 'custom_namespace'
      )

      expect(cache_instance).to have_received(:clear_all_cache)
    end
  end

  describe '.cache_stats' do
    context 'when Redis is available' do
      let(:stats) do
        {
          total_keys: 15,
          memory_usage: '2.1MB',
          hit_rate: 0.85,
          keys_by_type: { robot: 5, table: 3, command: 7 }
        }
      end

      before do
        allow_any_instance_of(RobotChallenge::Cache::RedisCache).to receive(:cache_stats).and_return(stats)
      end

      it 'returns cache statistics with default parameters' do
        result = described_class.cache_stats
        expect(result).to eq(stats)
      end

      it 'returns cache statistics with custom parameters' do
        result = described_class.cache_stats(
          redis_url: 'redis://localhost:6379/1',
          namespace: 'custom_namespace'
        )
        expect(result).to eq(stats)
      end
    end

    context 'when Redis is not available' do
      before do
        allow_any_instance_of(RobotChallenge::Cache::RedisCache).to receive(:cache_stats).and_raise(StandardError,
                                                                                                    'Stats unavailable')
      end

      it 'returns error information' do
        result = described_class.cache_stats
        expect(result[:error]).to eq('Stats unavailable')
        expect(result[:total_keys]).to eq(0)
        expect(result[:memory_usage]).to eq('Unknown')
        expect(result[:hit_rate]).to eq(0.0)
        expect(result[:keys_by_type]).to eq({})
      end
    end
  end
end
