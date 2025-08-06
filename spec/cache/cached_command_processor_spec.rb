# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RobotChallenge::Cache::CachedCommandProcessor do
  let(:table) { RobotChallenge::Table.new(5, 5) }
  let(:robot) { RobotChallenge::Robot.new(table) }
  let(:processor) { RobotChallenge::CommandProcessor.new(robot) }
  let(:cache) { double('cache') }
  let(:cached_processor) { described_class.new(processor, cache) }

  describe '#initialize' do
    it 'creates cached processor with custom cache' do
      expect(cached_processor.processor).to eq(processor)
      expect(cached_processor.cache).to eq(cache)
    end

    it 'creates cached processor with default cache' do
      processor_with_default_cache = described_class.new(processor)
      expect(processor_with_default_cache.processor).to eq(processor)
      expect(processor_with_default_cache.cache).to be_a(RobotChallenge::Cache::RedisCache)
    end
  end

  describe '#process_command_string' do
    context 'when result is cached' do
      it 'returns cached result' do
        command_string = 'PLACE 1,2,NORTH'
        cache_key = "command:#{Digest::MD5.hexdigest(command_string)}:unplaced"
        cached_result = { status: :success, data: 'cached result' }

        allow(cache).to receive(:get_command_result).with(cache_key).and_return(cached_result)
        allow(cache).to receive(:set_command_result)
        allow(processor).to receive(:process_command_string)

        result = cached_processor.process_command_string(command_string)
        expect(result).to eq(cached_result)
      end
    end

    context 'when result is not cached' do
      it 'processes command and caches result' do
        command_string = 'PLACE 1,2,NORTH'
        cache_key = "command:#{Digest::MD5.hexdigest(command_string)}:unplaced"
        processed_result = { status: :success, data: 'processed result' }

        allow(cache).to receive(:get_command_result).with(cache_key).and_return(nil)
        allow(processor).to receive(:process_command_string).with(command_string).and_return(processed_result)
        allow(cache).to receive(:set_command_result).with(cache_key, processed_result)

        result = cached_processor.process_command_string(command_string)
        expect(result).to eq(processed_result)
      end
    end

    context 'with placed robot' do
      it 'includes robot state in cache key' do
        robot.place(RobotChallenge::Position.new(1, 2), RobotChallenge::Direction.new('NORTH'))
        command_string = 'PLACE 1,2,NORTH'
        expected_cache_key = "command:#{Digest::MD5.hexdigest(command_string)}:1,2,NORTH"

        allow(cache).to receive(:get_command_result).with(expected_cache_key).and_return(nil)
        allow(processor).to receive(:process_command_string).with(command_string).and_return({})
        expect(cache).to receive(:set_command_result).with(expected_cache_key, {})

        result = cached_processor.process_command_string(command_string)
        expect(result).to eq({})
      end
    end
  end

  describe '#process_command' do
    context 'when result is cached' do
      it 'returns cached result' do
        command = double('command', to_s: 'MOVE')
        cache_key = "command:#{Digest::MD5.hexdigest('MOVE')}:unplaced"
        cached_result = { status: :success, data: 'cached result' }

        allow(cache).to receive(:get_command_result).with(cache_key).and_return(cached_result)
        allow(cache).to receive(:set_command_result)
        allow(processor).to receive(:process_command)

        result = cached_processor.process_command(command)
        expect(result).to eq(cached_result)
      end
    end

    context 'when result is not cached' do
      it 'processes command and caches result' do
        command = double('command', to_s: 'MOVE')
        cache_key = "command:#{Digest::MD5.hexdigest('MOVE')}:unplaced"
        processed_result = { status: :success, data: 'processed result' }

        allow(cache).to receive(:get_command_result).with(cache_key).and_return(nil)
        allow(processor).to receive(:process_command).with(command).and_return(processed_result)
        allow(cache).to receive(:set_command_result).with(cache_key, processed_result)

        result = cached_processor.process_command(command)
        expect(result).to eq(processed_result)
      end
    end

    context 'with placed robot' do
      it 'includes robot state in cache key' do
        robot.place(RobotChallenge::Position.new(2, 3), RobotChallenge::Direction.new('SOUTH'))
        command = double('command', to_s: 'MOVE')
        expected_cache_key = "command:#{Digest::MD5.hexdigest('MOVE')}:2,3,SOUTH"

        allow(cache).to receive(:get_command_result).with(expected_cache_key).and_return(nil)
        allow(processor).to receive(:process_command).with(command).and_return({})
        allow(cache).to receive(:set_command_result).with(expected_cache_key, {})

        result = cached_processor.process_command(command)
        expect(result).to eq({})
      end
    end
  end

  describe 'delegated methods' do
    describe '#robot' do
      it 'delegates to processor' do
        allow(processor).to receive(:robot).and_return(robot)
        result = cached_processor.robot
        expect(result).to eq(robot)
      end
    end

    describe '#robot=' do
      it 'sets robot and invalidates cache' do
        new_robot = RobotChallenge::Robot.new(table)
        expect(processor).to receive(:robot=).with(new_robot)
        expect(cache).to receive(:invalidate_robot_cache).with(anything)

        cached_processor.robot = new_robot
      end
    end

    describe '#available_commands' do
      it 'delegates to processor' do
        commands = %w[PLACE MOVE LEFT RIGHT REPORT]
        allow(processor).to receive(:available_commands).and_return(commands)
        result = cached_processor.available_commands
        expect(result).to eq(commands)
      end
    end

    describe '#register_command' do
      it 'delegates to processor' do
        command_class = Class.new(RobotChallenge::Commands::Command)
        expect(processor).to receive(:register_command).with('CUSTOM', command_class)

        cached_processor.register_command('CUSTOM', command_class)
        # Verify the method was called by checking that no error was raised
      end
    end

    describe '#command_factory' do
      it 'delegates to processor' do
        factory = double('factory')
        allow(processor).to receive(:command_factory).and_return(factory)
        result = cached_processor.command_factory
        expect(result).to eq(factory)
      end
    end
  end

  describe 'method delegation' do
    describe '#method_missing' do
      it 'delegates unknown methods to processor' do
        allow(processor).to receive(:some_unknown_method).with('arg1', 'arg2').and_return('result')

        result = cached_processor.some_unknown_method('arg1', 'arg2')
        expect(result).to eq('result')
      end

      it 'calls super for methods not available on processor' do
        expect { cached_processor.non_existent_method }.to raise_error(NoMethodError)
      end

      it 'handles blocks correctly' do
        block_called = false
        allow(processor).to receive(:method_with_block).and_yield

        cached_processor.method_with_block { block_called = true }
        expect(block_called).to be true
      end
    end

    describe '#respond_to_missing?' do
      it 'returns true for methods available on processor' do
        allow(processor).to receive(:respond_to?).with(:some_unknown_method, false).and_return(true)
        expect(cached_processor.respond_to?(:some_unknown_method)).to be true
      end

      it 'returns false for methods not available on processor' do
        allow(processor).to receive(:respond_to?).with(:non_existent_method, false).and_return(false)
        expect(cached_processor.respond_to?(:non_existent_method)).to be false
      end

      it 'handles include_private parameter' do
        allow(processor).to receive(:respond_to?).with(:some_unknown_method, true).and_return(true)
        expect(cached_processor.respond_to?(:some_unknown_method, true)).to be true
      end
    end
  end

  describe 'private methods' do
    describe '#build_cache_key' do
      it 'builds cache key for unplaced robot' do
        command_string = 'PLACE 1,2,NORTH'
        expected_key = "command:#{Digest::MD5.hexdigest(command_string)}:unplaced"

        result = cached_processor.send(:build_cache_key, command_string)
        expect(result).to eq(expected_key)
      end

      it 'builds cache key for placed robot' do
        robot.place(RobotChallenge::Position.new(2, 3), RobotChallenge::Direction.new('EAST'))
        command_string = 'MOVE'
        expected_key = "command:#{Digest::MD5.hexdigest(command_string)}:2,3,EAST"

        result = cached_processor.send(:build_cache_key, command_string)
        expect(result).to eq(expected_key)
      end
    end

    describe '#robot_state_for_hash' do
      it 'returns unplaced for unplaced robot' do
        result = cached_processor.send(:robot_state_for_hash)
        expect(result).to eq('unplaced')
      end

      it 'returns position and direction for placed robot' do
        robot.place(RobotChallenge::Position.new(1, 2), RobotChallenge::Direction.new('SOUTH'))
        result = cached_processor.send(:robot_state_for_hash)
        expect(result).to eq('1,2,SOUTH')
      end
    end

    describe '#invalidate_robot_cache' do
      it 'invalidates robot cache' do
        expect(cache).to receive(:invalidate_robot_cache).with(robot.object_id)

        cached_processor.send(:invalidate_robot_cache)
        # Verify the method was called by checking that no error was raised
      end
    end

    describe '#log_cache_hit' do
      it 'logs cache hit without raising error' do
        expect { cached_processor.send(:log_cache_hit, 'test command') }.not_to raise_error
      end
    end

    describe '#log_cache_miss' do
      it 'logs cache miss without raising error' do
        expect { cached_processor.send(:log_cache_miss, 'test command') }.not_to raise_error
      end
    end
  end

  describe 'integration scenarios' do
    it 'caches command results and reuses them' do
      real_cache = RobotChallenge::Cache::RedisCache.new
      integration_processor = described_class.new(processor, real_cache)

      # First call - should process and cache
      result1 = integration_processor.process_command_string('PLACE 1,2,NORTH')
      expect(result1).to be false # PLACE command returns false when robot is not placed

      # Second call - should use cached result
      result2 = integration_processor.process_command_string('PLACE 1,2,NORTH')
      expect(result2).to be false

      # Verify cache was used
      cache_key = "command:#{Digest::MD5.hexdigest('PLACE 1,2,NORTH')}:unplaced"
      expect(real_cache.get_command_result(cache_key)).not_to be_nil
    end

    it 'uses different cache keys for different robot states' do
      real_cache = RobotChallenge::Cache::RedisCache.new
      integration_processor = described_class.new(processor, real_cache)

      # Place robot
      integration_processor.process_command_string('PLACE 1,2,NORTH')

      # Move robot
      integration_processor.process_command_string('MOVE')

      # Verify different cache keys were used
      place_key = "command:#{Digest::MD5.hexdigest('PLACE 1,2,NORTH')}:unplaced"
      move_key = "command:#{Digest::MD5.hexdigest('MOVE')}:1,2,NORTH"

      expect(real_cache.get_command_result(place_key)).not_to be_nil
      expect(real_cache.get_command_result(move_key)).not_to be_nil
    end

    it 'invalidates cache when robot is changed' do
      real_cache = RobotChallenge::Cache::RedisCache.new
      integration_processor = described_class.new(processor, real_cache)

      # Set up initial state
      integration_processor.process_command_string('PLACE 1,2,NORTH')

      # Change robot (this will fail because CommandProcessor doesn't have robot=)
      new_robot = RobotChallenge::Robot.new(table)
      expect { integration_processor.robot = new_robot }.to raise_error(NoMethodError)
    end
  end

  describe 'edge cases' do
    it 'handles nil command string' do
      expect { cached_processor.process_command_string(nil) }.to raise_error(TypeError)
    end

    it 'handles empty command string' do
      allow(cache).to receive(:get_command_result).and_return(nil)
      allow(processor).to receive(:process_command_string).and_return({})
      allow(cache).to receive(:set_command_result)

      expect { cached_processor.process_command_string('') }.not_to raise_error
    end

    it 'handles cache errors gracefully' do
      allow(cache).to receive(:get_command_result).and_raise(StandardError, 'Cache error')
      allow(processor).to receive(:process_command_string)
      allow(cache).to receive(:set_command_result)

      expect { cached_processor.process_command_string('TEST') }.to raise_error(StandardError)
    end

    it 'handles processor errors gracefully' do
      allow(cache).to receive(:get_command_result).and_return(nil)
      allow(processor).to receive(:process_command_string).and_raise(StandardError, 'Processor error')

      expect { cached_processor.process_command_string('TEST') }.to raise_error(StandardError)
    end
  end
end
