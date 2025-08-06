# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RobotChallenge::Commands::CommandRegistry do
  let(:registry) { described_class.new }
  let(:mock_command_class) do
    Class.new(RobotChallenge::Commands::Command) do
      def initialize(*); end

      def execute(_robot)
        success_result
      end
    end
  end

  describe '#initialize' do
    it 'registers default commands' do
      expect(registry.registered?('PLACE')).to be true
      expect(registry.registered?('MOVE')).to be true
      expect(registry.registered?('LEFT')).to be true
      expect(registry.registered?('RIGHT')).to be true
      expect(registry.registered?('REPORT')).to be true
    end
  end

  describe '#register' do
    it 'registers a new command class' do
      registry.register('CUSTOM', mock_command_class)
      expect(registry.registered?('CUSTOM')).to be true
    end

    it 'handles case insensitive registration' do
      registry.register('custom', mock_command_class)
      expect(registry.registered?('CUSTOM')).to be true
      expect(registry.registered?('custom')).to be true
    end

    it 'overwrites existing registration' do
      registry.register('CUSTOM', mock_command_class)
      new_command_class = Class.new(RobotChallenge::Commands::Command)
      registry.register('CUSTOM', new_command_class)
      expect(registry.command_names).to include('CUSTOM')
    end
  end

  describe '#registered?' do
    it 'returns true for registered commands' do
      expect(registry.registered?('PLACE')).to be true
      expect(registry.registered?('MOVE')).to be true
    end

    it 'returns false for unregistered commands' do
      expect(registry.registered?('UNKNOWN')).to be false
    end

    it 'is case insensitive' do
      expect(registry.registered?('place')).to be true
      expect(registry.registered?('PLACE')).to be true
    end
  end

  describe '#command_names' do
    it 'returns all registered command names in sorted order' do
      names = registry.command_names
      expect(names).to include('PLACE', 'MOVE', 'LEFT', 'RIGHT', 'REPORT')
      expect(names).to eq(names.sort)
    end

    it 'includes newly registered commands' do
      registry.register('CUSTOM', mock_command_class)
      expect(registry.command_names).to include('CUSTOM')
    end
  end

  describe '#create_command' do
    context 'for PLACE command' do
      it 'creates PlaceCommand with parameters' do
        command = registry.create_command('PLACE', x: 1, y: 2, direction: 'NORTH')
        expect(command).to be_a(RobotChallenge::Commands::PlaceCommand)
        expect(command.x).to eq(1)
        expect(command.y).to eq(2)
        expect(command.direction_name).to eq('NORTH')
      end

      it 'handles case insensitive command name' do
        command = registry.create_command('place', x: 0, y: 0, direction: 'SOUTH')
        expect(command).to be_a(RobotChallenge::Commands::PlaceCommand)
      end
    end

    context 'for simple commands' do
      it 'creates MoveCommand' do
        command = registry.create_command('MOVE')
        expect(command).to be_a(RobotChallenge::Commands::MoveCommand)
      end

      it 'creates LeftCommand' do
        command = registry.create_command('LEFT')
        expect(command).to be_a(RobotChallenge::Commands::LeftCommand)
      end

      it 'creates RightCommand' do
        command = registry.create_command('RIGHT')
        expect(command).to be_a(RobotChallenge::Commands::RightCommand)
      end

      it 'creates ReportCommand' do
        command = registry.create_command('REPORT')
        expect(command).to be_a(RobotChallenge::Commands::ReportCommand)
      end

      it 'handles case insensitive command names' do
        command = registry.create_command('move')
        expect(command).to be_a(RobotChallenge::Commands::MoveCommand)
      end
    end

    context 'for unregistered commands' do
      it 'returns nil' do
        expect(registry.create_command('UNKNOWN')).to be_nil
      end
    end

    context 'with invalid parameters' do
      it 'creates command with invalid parameters' do
        command = registry.create_command('PLACE', x: 'invalid', y: 'invalid', direction: 'INVALID')
        expect(command).to be_a(RobotChallenge::Commands::PlaceCommand)
        expect(command.valid?).to be false
      end

      it 'handles missing parameters gracefully' do
        command = registry.create_command('PLACE', x: 1)
        expect(command).to be_a(RobotChallenge::Commands::PlaceCommand)
      end

      it 'handles extra parameters gracefully' do
        command = registry.create_command('PLACE', x: 1, y: 2, direction: 'NORTH', extra: 'param')
        expect(command).to be_a(RobotChallenge::Commands::PlaceCommand)
      end
    end

    context 'error handling' do
      it 'handles command creation errors gracefully' do
        # Create a command class that raises an error during initialization
        error_command_class = Class.new(RobotChallenge::Commands::Command) do
          def initialize(*)
            raise ArgumentError, 'Invalid parameters'
          end
        end

        registry.register('ERROR', error_command_class)
        expect(registry.create_command('ERROR')).to be_nil
      end

      it 'handles errors gracefully when logger is nil' do
        # Ensure logger is nil
        registry.instance_variable_set(:@logger, nil)

        error_command_class = Class.new(RobotChallenge::Commands::Command) do
          def initialize(*)
            raise StandardError, 'Creation failed'
          end
        end

        registry.register('ERROR', error_command_class)
        # Should not raise an error even when logger is nil
        expect { registry.create_command('ERROR') }.not_to raise_error
        expect(registry.create_command('ERROR')).to be_nil
      end
    end
  end

  describe '#resolve_name' do
    it 'resolves case insensitive command names' do
      expect(registry.send(:resolve_name, 'place')).to eq('PLACE')
      expect(registry.send(:resolve_name, 'MOVE')).to eq('MOVE')
      expect(registry.send(:resolve_name, 'left')).to eq('LEFT')
    end

    it 'returns original name if not found' do
      expect(registry.send(:resolve_name, 'UNKNOWN')).to eq('UNKNOWN')
    end
  end

  describe 'integration tests' do
    let(:custom_command_class) do
      Class.new(RobotChallenge::Commands::Command) do
        attr_reader :param1, :param2

        def initialize(param1 = nil, param2 = nil)
          @param1 = param1
          @param2 = param2
        end

        def execute(_robot)
          success_result
        end
      end
    end

    before do
      registry.register('CUSTOM', custom_command_class)
    end

    it 'creates custom command without parameters' do
      command = registry.create_command('CUSTOM')
      expect(command).to be_a(custom_command_class)
      expect(command.param1).to be_nil
      expect(command.param2).to be_nil
    end

    it 'creates custom command with parameters' do
      command = registry.create_command('CUSTOM', param1: 'value1', param2: 'value2')
      expect(command).to be_a(custom_command_class)
      expect(command.param1).to eq({ param1: 'value1', param2: 'value2' })
      expect(command.param2).to be_nil
    end
  end
end
