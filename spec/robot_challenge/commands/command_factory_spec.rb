# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RobotChallenge::Commands::CommandFactory do
  let(:factory) { described_class.new }

  describe '#create_from_string' do
    context 'with PLACE command' do
      it 'creates PlaceCommand from valid string' do
        command = factory.create_from_string('PLACE 1,2,NORTH')
        expect(command).to be_a(RobotChallenge::Commands::PlaceCommand)
        expect(command.x).to eq(1)
        expect(command.y).to eq(2)
        expect(command.direction_name).to eq('NORTH')
      end

      it 'handles different case' do
        command = factory.create_from_string('place 1,2,north')
        expect(command).to be_a(RobotChallenge::Commands::PlaceCommand)
      end

      it 'handles extra whitespace' do
        command = factory.create_from_string('  PLACE  1,2,NORTH  ')
        expect(command).to be_a(RobotChallenge::Commands::PlaceCommand)
      end

      it 'returns nil for invalid PLACE format' do
        command = factory.create_from_string('PLACE 1,2')
        expect(command).to be_nil
      end
    end

    context 'with simple commands' do
      it 'creates MoveCommand' do
        command = factory.create_from_string('MOVE')
        expect(command).to be_a(RobotChallenge::Commands::MoveCommand)
      end

      it 'creates LeftCommand' do
        command = factory.create_from_string('LEFT')
        expect(command).to be_a(RobotChallenge::Commands::LeftCommand)
      end

      it 'creates RightCommand' do
        command = factory.create_from_string('RIGHT')
        expect(command).to be_a(RobotChallenge::Commands::RightCommand)
      end

      it 'creates ReportCommand' do
        command = factory.create_from_string('REPORT')
        expect(command).to be_a(RobotChallenge::Commands::ReportCommand)
      end
    end

    context 'with invalid input' do
      it 'returns nil for empty string' do
        command = factory.create_from_string('')
        expect(command).to be_nil
      end

      it 'returns nil for nil input' do
        command = factory.create_from_string(nil)
        expect(command).to be_nil
      end

      it 'returns nil for unregistered command' do
        command = factory.create_from_string('UNKNOWN')
        expect(command).to be_nil
      end
    end
  end

  describe '#available_commands' do
    it 'returns list of available commands' do
      commands = factory.available_commands
      expect(commands).to include('LEFT', 'MOVE', 'PLACE', 'REPORT', 'RIGHT')
    end
  end

  describe '#register_command' do
    let(:custom_command_class) { Class.new(RobotChallenge::Commands::Command) }

    it 'registers new command with registry' do
      factory.register_command('CUSTOM', custom_command_class)
      expect(factory.available_commands).to include('CUSTOM')
    end

    it 'allows creating registered custom commands' do
      custom_command_class = Class.new(RobotChallenge::Commands::Command) do
        def initialize
          # Default constructor
        end
      end

      factory.register_command('CUSTOM', custom_command_class)
      factory.register_parser(RobotChallenge::Commands::SimpleCommandParser.new('CUSTOM'))

      command = factory.create_from_string('CUSTOM')
      expect(command).to be_a(custom_command_class)
    end
  end

  describe 'with custom registry' do
    let(:custom_registry) { RobotChallenge::Commands::CommandRegistry.new }
    let(:factory) { described_class.new(custom_registry) }

    it 'uses provided registry' do
      custom_command_class = Class.new(RobotChallenge::Commands::Command) do
        def initialize
          # Default constructor
        end
      end

      custom_registry.register('CUSTOM', custom_command_class)
      factory.register_parser(RobotChallenge::Commands::SimpleCommandParser.new('CUSTOM'))

      command = factory.create_from_string('CUSTOM')
      expect(command).to be_a(custom_command_class)
    end
  end
end
