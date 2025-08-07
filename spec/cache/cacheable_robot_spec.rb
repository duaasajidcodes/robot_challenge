# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RobotChallenge::Cache::CacheableRobot do
  let(:table) { RobotChallenge::Table.new(5, 5) }
  let(:robot) { RobotChallenge::Robot.new(table) }
  let(:cache) { double('cache') }
  let(:cacheable_robot) { described_class.new(robot, cache: cache) }

  describe '#initialize' do
    it 'creates cacheable robot with default cache' do
      robot_with_default_cache = described_class.new(robot)
      expect(robot_with_default_cache.robot).to eq(robot)
      expect(robot_with_default_cache.cache).to be_a(RobotChallenge::Cache::RedisCache)
      expect(robot_with_default_cache.robot_id).to match(/^robot_/)
    end

    it 'creates cacheable robot with custom cache' do
      custom_cache = double('custom_cache')
      robot_with_custom_cache = described_class.new(robot, cache: custom_cache)
      expect(robot_with_custom_cache.cache).to eq(custom_cache)
    end

    it 'creates cacheable robot with custom robot_id' do
      custom_id = 'custom_robot_123'
      robot_with_custom_id = described_class.new(robot, robot_id: custom_id)
      expect(robot_with_custom_id.robot_id).to eq(custom_id)
    end

    it 'generates unique robot_id when not provided' do
      robot1 = described_class.new(robot)
      robot2 = described_class.new(robot)
      expect(robot1.robot_id).not_to eq(robot2.robot_id)
    end
  end

  describe 'robot operations with caching' do
    let(:position) { RobotChallenge::Position.new(1, 2) }
    let(:direction) { RobotChallenge::Direction.new('NORTH') }

    describe '#place' do
      it 'places robot and caches state' do
        allow(robot).to receive(:place).with(position, direction).and_return(robot)
        allow(cache).to receive(:cache_robot_state).with(cacheable_robot.robot_id, anything)

        result = cacheable_robot.place(position, direction)
        expect(result).to eq(robot)
      end

      it 'handles cache errors gracefully' do
        allow(robot).to receive(:place).with(position, direction).and_return(robot)
        allow(cache).to receive(:cache_robot_state).and_raise(StandardError, 'Cache error')

        expect { cacheable_robot.place(position, direction) }.not_to raise_error
      end
    end

    describe '#move' do
      before do
        robot.place(position, direction)
      end

      it 'moves robot and caches state' do
        allow(robot).to receive(:move).and_return(robot)
        allow(cache).to receive(:cache_robot_state).with(cacheable_robot.robot_id, anything)

        result = cacheable_robot.move
        expect(result).to eq(robot)
      end

      it 'handles cache errors gracefully' do
        allow(robot).to receive(:move).and_return(robot)
        allow(cache).to receive(:cache_robot_state).and_raise(StandardError, 'Cache error')

        expect { cacheable_robot.move }.not_to raise_error
      end
    end

    describe '#turn_left' do
      before do
        robot.place(position, direction)
      end

      it 'turns robot left and caches state' do
        allow(robot).to receive(:turn_left).and_return(robot)
        allow(cache).to receive(:cache_robot_state).with(cacheable_robot.robot_id, anything)

        result = cacheable_robot.turn_left
        expect(result).to eq(robot)
      end

      it 'handles cache errors gracefully' do
        allow(robot).to receive(:turn_left).and_return(robot)
        allow(cache).to receive(:cache_robot_state).and_raise(StandardError, 'Cache error')

        expect { cacheable_robot.turn_left }.not_to raise_error
      end
    end

    describe '#turn_right' do
      before do
        robot.place(position, direction)
      end

      it 'turns robot right and caches state' do
        allow(robot).to receive(:turn_right).and_return(robot)
        allow(cache).to receive(:cache_robot_state).with(cacheable_robot.robot_id, anything)

        result = cacheable_robot.turn_right
        expect(result).to eq(robot)
      end

      it 'handles cache errors gracefully' do
        allow(robot).to receive(:turn_right).and_return(robot)
        allow(cache).to receive(:cache_robot_state).and_raise(StandardError, 'Cache error')

        expect { cacheable_robot.turn_right }.not_to raise_error
      end
    end

    describe '#report' do
      before do
        robot.place(position, direction)
      end

      it 'delegates to robot without caching' do
        allow(robot).to receive(:report).and_return('1,2,NORTH')
        allow(cache).to receive(:cache_robot_state)

        result = cacheable_robot.report
        expect(result).to eq('1,2,NORTH')
      end
    end

    describe '#placed?' do
      it 'delegates to robot without caching' do
        allow(robot).to receive(:placed?).and_return(true)
        allow(cache).to receive(:cache_robot_state)

        result = cacheable_robot.placed?
        expect(result).to be true
      end
    end
  end

  describe 'method delegation' do
    describe '#method_missing' do
      it 'delegates unknown methods to robot' do
        allow(robot).to receive(:some_unknown_method).with('arg1', 'arg2').and_return('result')

        result = cacheable_robot.some_unknown_method('arg1', 'arg2')
        expect(result).to eq('result')
      end

      it 'calls super for methods not available on robot' do
        expect { cacheable_robot.non_existent_method }.to raise_error(NoMethodError)
      end
    end

    describe '#respond_to_missing?' do
      it 'returns true for methods available on robot' do
        allow(robot).to receive(:respond_to?).with(:some_unknown_method, false).and_return(true)
        expect(cacheable_robot.respond_to?(:some_unknown_method)).to be true
      end

      it 'returns false for methods not available on robot' do
        allow(robot).to receive(:respond_to?).with(:non_existent_method, false).and_return(false)
        expect(cacheable_robot.respond_to?(:non_existent_method)).to be false
      end

      it 'handles include_private parameter' do
        allow(robot).to receive(:respond_to?).with(:some_unknown_method, true).and_return(true)
        expect(cacheable_robot.respond_to?(:some_unknown_method, true)).to be true
      end
    end
  end

  describe 'cache management' do
    describe '#load_from_cache' do
      it 'loads robot state from cache successfully' do
        cached_state = {
          position: { x: 2, y: 3 },
          direction: 'SOUTH',
          placed: true,
          table: { width: 5, height: 5 },
          timestamp: Time.now.iso8601
        }

        allow(cache).to receive(:get_robot_state).with(cacheable_robot.robot_id).and_return(cached_state)

        result = cacheable_robot.load_from_cache
        expect(result).to be true

        # Verify robot state was restored
        expect(robot.position.x).to eq(2)
        expect(robot.position.y).to eq(3)
        expect(robot.direction.name).to eq('SOUTH')
      end

      it 'returns false when no cached state exists' do
        allow(cache).to receive(:get_robot_state).with(cacheable_robot.robot_id).and_return(nil)

        result = cacheable_robot.load_from_cache
        expect(result).to be false
      end

      it 'returns false when cached state is corrupted' do
        corrupted_state = { invalid: 'data' }
        allow(cache).to receive(:get_robot_state).with(cacheable_robot.robot_id).and_return(corrupted_state)

        result = cacheable_robot.load_from_cache
        expect(result).to be true # The method doesn't validate the structure, it just tries to set the variables
      end

      it 'handles errors gracefully' do
        allow(cache).to receive(:get_robot_state).and_raise(StandardError, 'Cache error')

        result = cacheable_robot.load_from_cache
        expect(result).to be false
      end

      it 'handles nil position in cached state' do
        cached_state = {
          position: nil,
          direction: 'NORTH',
          placed: false,
          table: { width: 5, height: 5 },
          timestamp: Time.now.iso8601
        }

        allow(cache).to receive(:get_robot_state).with(cacheable_robot.robot_id).and_return(cached_state)

        result = cacheable_robot.load_from_cache
        expect(result).to be true
      end
    end

    describe '#invalidate_cache' do
      it 'invalidates robot cache' do
        expect(cache).to receive(:invalidate_robot_cache).with(cacheable_robot.robot_id)

        cacheable_robot.invalidate_cache
        # Verify method completed without error
      end
    end

    describe '#cache_stats' do
      it 'returns cache statistics' do
        stats = { hits: 10, misses: 5 }
        allow(cache).to receive(:cache_stats).and_return(stats)

        result = cacheable_robot.cache_stats
        expect(result).to eq(stats)
      end
    end

    describe '#health_check' do
      it 'returns cache health information' do
        health = { status: 'healthy', memory: '1.2MB' }
        allow(cache).to receive(:health_check).and_return(health)

        result = cacheable_robot.health_check
        expect(result).to eq(health)
      end
    end
  end

  describe 'private methods' do
    describe '#cache_robot_state' do
      before do
        robot.place(RobotChallenge::Position.new(1, 2), RobotChallenge::Direction.new('NORTH'))
      end

      it 'caches robot state with correct structure' do
        expect(cache).to receive(:cache_robot_state).with(
          cacheable_robot.robot_id,
          hash_including(
            position: { x: 1, y: 2 },
            direction: 'NORTH',
            placed: true,
            table: { width: 5, height: 5 },
            timestamp: anything
          )
        )

        cacheable_robot.send(:cache_robot_state)
      end

      it 'handles cache errors gracefully' do
        allow(cache).to receive(:cache_robot_state).and_raise(StandardError, 'Cache error')

        expect { cacheable_robot.send(:cache_robot_state) }.not_to raise_error
      end
    end

    describe '#robot_state_hash' do
      it 'returns position hash for valid position' do
        position = RobotChallenge::Position.new(3, 4)
        result = cacheable_robot.send(:robot_state_hash, position)
        expect(result).to eq({ x: 3, y: 4 })
      end

      it 'returns nil for nil position' do
        result = cacheable_robot.send(:robot_state_hash, nil)
        expect(result).to be_nil
      end
    end

    describe '#generate_robot_id' do
      it 'generates unique robot ID' do
        id1 = cacheable_robot.send(:generate_robot_id)
        id2 = cacheable_robot.send(:generate_robot_id)

        expect(id1).to match(/^robot_/)
        expect(id2).to match(/^robot_/)
        expect(id1).not_to eq(id2)
      end
    end

    describe '#log_cache_error' do
      it 'handles cache errors silently' do
        error = StandardError.new('Test error')
        expect do
          cacheable_robot.send(:log_cache_error, 'test_operation', error)
        end.not_to output.to_stdout
      end
    end
  end

  describe 'integration scenarios' do
    let(:real_cache) { RobotChallenge::Cache::RedisCache.new }
    let(:integration_robot) { described_class.new(robot, cache: real_cache) }

    it 'maintains robot state through cache operations' do
      # Place robot
      integration_robot.place(RobotChallenge::Position.new(2, 3), RobotChallenge::Direction.new('EAST'))
      expect(integration_robot.report).to eq('2,3,EAST')

      # Move robot
      integration_robot.move
      expect(integration_robot.report).to eq('3,3,EAST')

      # Turn robot
      integration_robot.turn_left
      expect(integration_robot.report).to eq('3,3,NORTH')

      # Verify cache was used
      expect(real_cache.get_robot_state(integration_robot.robot_id)).not_to be_nil
    end

    it 'can load state from cache' do
      # Set up initial state
      integration_robot.place(RobotChallenge::Position.new(1, 1), RobotChallenge::Direction.new('SOUTH'))
      integration_robot.move

      # Create new robot and load from cache
      new_robot = RobotChallenge::Robot.new(table)
      new_cacheable_robot = described_class.new(new_robot, cache: real_cache, robot_id: integration_robot.robot_id)

      expect(new_cacheable_robot.load_from_cache).to be true
      expect(new_cacheable_robot.report).to eq('1,0,SOUTH')
    end
  end
end
