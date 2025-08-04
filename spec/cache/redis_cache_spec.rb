# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RobotChallenge::Cache::RedisCache, type: :cache do
  let(:cache) { described_class.new(cache_ttl: 60, namespace: 'test_robot_challenge') }
  let(:robot_id) { 'test_robot_123' }
  let(:table_id) { 'test_table_456' }
  let(:command_hash) { 'test_command_hash_789' }

  before do
    cache.clear_all_cache
  end

  after do
    cache.clear_all_cache
  end

  describe '#initialize' do
    it 'creates a Redis cache instance with default settings' do
      expect(cache.redis).to be_a(Redis)
      expect(cache.cache_ttl).to eq(60)
      expect(cache.namespace).to eq('test_robot_challenge')
    end

    it 'uses environment variable for Redis URL' do
      ENV['REDIS_URL'] = 'redis://localhost:6379/1'
      cache_with_env = described_class.new
      expect(cache_with_env.redis).to be_a(Redis)
    end
  end

  describe '#cache_robot_state' do
    let(:robot_state) do
      {
        position: { x: 1, y: 2 },
        direction: 'NORTH',
        placed: true,
        timestamp: Time.now.iso8601
      }
    end

    it 'caches robot state successfully' do
      expect { cache.cache_robot_state(robot_id, robot_state) }.not_to raise_error
    end

    it 'caches robot state with correct key format' do
      cache.cache_robot_state(robot_id, robot_state)
      key = "test_robot_challenge:robot:#{robot_id}:state"
      # exists returns integer (1 for exists, 0 for not exists)
      expect(cache.redis.exists(key)).to eq(1)
    end
  end

  describe '#get_robot_state' do
    let(:robot_state) do
      {
        position: { x: 3, y: 4 },
        direction: 'SOUTH',
        placed: true,
        timestamp: Time.now.iso8601
      }
    end

    context 'when robot state is cached' do
      before do
        cache.cache_robot_state(robot_id, robot_state)
      end

      it 'returns cached robot state' do
        result = cache.get_robot_state(robot_id)
        expect(result).to include(
          position: { x: 3, y: 4 },
          direction: 'SOUTH',
          placed: true
        )
      end

      it 'returns symbolized keys' do
        result = cache.get_robot_state(robot_id)
        expect(result.keys).to all(be_a(Symbol))
      end
    end

    context 'when robot state is not cached' do
      it 'returns nil' do
        result = cache.get_robot_state(robot_id)
        expect(result).to be_nil
      end
    end

    context 'when cached data is corrupted' do
      before do
        key = "test_robot_challenge:robot:#{robot_id}:state"
        cache.redis.set(key, 'invalid json')
      end

      it 'returns nil and logs error' do
        expect { cache.get_robot_state(robot_id) }.not_to raise_error
        expect(cache.get_robot_state(robot_id)).to be_nil
      end
    end
  end

  describe '#cache_command_result' do
    let(:command_result) do
      {
        success: true,
        message: 'Robot moved successfully',
        robot_state: { x: 1, y: 2, direction: 'NORTH' },
        timestamp: Time.now.iso8601
      }
    end

    it 'caches command result successfully' do
      expect { cache.cache_command_result(command_hash, command_result) }.not_to raise_error
    end

    it 'caches command result with correct key format' do
      cache.cache_command_result(command_hash, command_result)
      key = "test_robot_challenge:command:#{command_hash}"
      # exists returns integer (1 for exists, 0 for not exists)
      expect(cache.redis.exists(key)).to eq(1)
    end
  end

  describe '#get_cached_result' do
    let(:command_result) do
      {
        success: true,
        message: 'Robot placed successfully',
        robot_state: { x: 0, y: 0, direction: 'NORTH' },
        timestamp: Time.now.iso8601
      }
    end

    context 'when command result is cached' do
      before do
        cache.cache_command_result(command_hash, command_result)
      end

      it 'returns cached command result' do
        result = cache.get_cached_result(command_hash)
        expect(result).to include(
          success: true,
          message: 'Robot placed successfully'
        )
      end
    end

    context 'when command result is not cached' do
      it 'returns nil' do
        result = cache.get_cached_result(command_hash)
        expect(result).to be_nil
      end
    end
  end

  describe '#cache_table_state' do
    let(:table_state) do
      {
        width: 5,
        height: 5,
        occupied_positions: [{ x: 1, y: 1 }],
        timestamp: Time.now.iso8601
      }
    end

    it 'caches table state successfully' do
      expect { cache.cache_table_state(table_id, table_state) }.not_to raise_error
    end
  end

  describe '#get_table_state' do
    let(:table_state) do
      {
        width: 5,
        height: 5,
        occupied_positions: [{ x: 2, y: 2 }],
        timestamp: Time.now.iso8601
      }
    end

    context 'when table state is cached' do
      before do
        cache.cache_table_state(table_id, table_state)
      end

      it 'returns cached table state' do
        result = cache.get_table_state(table_id)
        expect(result).to include(
          width: 5,
          height: 5
        )
      end
    end

    context 'when table state is not cached' do
      it 'returns nil' do
        result = cache.get_table_state(table_id)
        expect(result).to be_nil
      end
    end
  end

  describe '#invalidate_robot_cache' do
    before do
      cache.cache_robot_state(robot_id, { position: { x: 1, y: 1 } })
      cache.cache_robot_state("#{robot_id}_other", { position: { x: 2, y: 2 } })
    end

    it 'removes only robot-specific cache entries' do
      expect(cache.get_robot_state(robot_id)).not_to be_nil
      expect(cache.get_robot_state("#{robot_id}_other")).not_to be_nil

      cache.invalidate_robot_cache(robot_id)

      expect(cache.get_robot_state(robot_id)).to be_nil
      expect(cache.get_robot_state("#{robot_id}_other")).not_to be_nil
    end
  end

  describe '#invalidate_table_cache' do
    before do
      cache.cache_table_state(table_id, { width: 5, height: 5 })
      cache.cache_table_state("#{table_id}_other", { width: 10, height: 10 })
    end

    it 'removes only table-specific cache entries' do
      expect(cache.get_table_state(table_id)).not_to be_nil
      expect(cache.get_table_state("#{table_id}_other")).not_to be_nil

      cache.invalidate_table_cache(table_id)

      expect(cache.get_table_state(table_id)).to be_nil
      expect(cache.get_table_state("#{table_id}_other")).not_to be_nil
    end
  end

  describe '#clear_all_cache' do
    before do
      cache.cache_robot_state(robot_id, { position: { x: 1, y: 1 } })
      cache.cache_table_state(table_id, { width: 5, height: 5 })
      cache.cache_command_result(command_hash, { success: true })
    end

    it 'removes robot state cache entries' do
      expect(cache.get_robot_state(robot_id)).not_to be_nil
      cache.clear_all_cache
      expect(cache.get_robot_state(robot_id)).to be_nil
    end

    it 'removes table state cache entries' do
      expect(cache.get_table_state(table_id)).not_to be_nil
      cache.clear_all_cache
      expect(cache.get_table_state(table_id)).to be_nil
    end

    it 'removes command result cache entries' do
      expect(cache.get_cached_result(command_hash)).not_to be_nil
      cache.clear_all_cache
      expect(cache.get_cached_result(command_hash)).to be_nil
    end
  end

  describe '#cache_stats' do
    before do
      cache.cache_robot_state(robot_id, { position: { x: 1, y: 1 } })
      cache.cache_table_state(table_id, { width: 5, height: 5 })
      cache.cache_command_result(command_hash, { success: true })
    end

    it 'returns cache statistics' do
      stats = cache.cache_stats

      expect(stats).to include(
        :total_keys,
        :memory_usage,
        :hit_rate,
        :keys_by_type
      )

      expect(stats[:total_keys]).to be >= 3
      expect(stats[:keys_by_type]).to include(:robot, :table, :command)
    end
  end

  describe '#available?' do
    context 'when Redis is available' do
      it 'returns true' do
        expect(cache.available?).to be true
      end
    end

    context 'when Redis is not available' do
      before do
        allow(cache.redis).to receive(:ping).and_raise(Redis::BaseError)
      end

      it 'returns false' do
        expect(cache.available?).to be false
      end
    end
  end

  describe '#health_check' do
    it 'returns health information' do
      health = cache.health_check

      expect(health).to include(
        :available,
        :connection_info,
        :cache_stats
      )

      expect(health[:available]).to be true
      # NOTE: connection_info might vary depending on Redis version
      expect(health[:connection_info]).to be_a(Hash)
    end
  end

  describe 'TTL functionality' do
    let(:short_ttl_cache) { described_class.new(cache_ttl: 1, namespace: 'test_ttl') }
    let(:robot_state) { { position: { x: 1, y: 1 } } }

    it 'expires cache entries after TTL' do
      short_ttl_cache.cache_robot_state(robot_id, robot_state)
      expect(short_ttl_cache.get_robot_state(robot_id)).not_to be_nil

      sleep(2) # Wait for TTL to expire

      expect(short_ttl_cache.get_robot_state(robot_id)).to be_nil
    end
  end

  describe 'namespace isolation' do
    let(:cache1) { described_class.new(namespace: 'namespace1') }
    let(:cache2) { described_class.new(namespace: 'namespace2') }
    let(:robot_state) { { position: { x: 1, y: 1 } } }

    it 'isolates cache entries by namespace' do
      cache1.cache_robot_state(robot_id, robot_state)
      cache2.cache_robot_state(robot_id, robot_state)

      expect(cache1.get_robot_state(robot_id)).not_to be_nil
      expect(cache2.get_robot_state(robot_id)).not_to be_nil

      cache1.clear_all_cache

      expect(cache1.get_robot_state(robot_id)).to be_nil
      expect(cache2.get_robot_state(robot_id)).not_to be_nil
    end
  end
end
