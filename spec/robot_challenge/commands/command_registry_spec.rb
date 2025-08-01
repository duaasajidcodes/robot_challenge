# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RobotChallenge::Commands::CommandRegistry do
  let(:registry) { described_class.new }

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
    let(:custom_command_class) { Class.new(RobotChallenge::Commands::Command) }

    it 'registers a new command class' do
      registry.register('CUSTOM', custom_command_class)
      expect(registry.registered?('CUSTOM')).to be true
    end

    it 'handles case insensitive registration' do
      registry.register('custom', custom_command_class)
      expect(registry.registered?('CUSTOM')).to be true
      expect(registry.registered?('custom')).to be true
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
      expect(names).to include('LEFT', 'MOVE', 'PLACE', 'REPORT', 'RIGHT')
      expect(names).to eq(names.sort)
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
    end

    context 'for unregistered commands' do
      it 'returns nil' do
        command = registry.create_command('UNKNOWN')
        expect(command).to be_nil
      end
    end

    context 'with invalid parameters' do
      it 'creates command with invalid parameters' do
        # Test with invalid PLACE parameters - the command is still created
        # but will fail validation when executed
        command = registry.create_command('PLACE', x: 'invalid', y: 'invalid', direction: 'INVALID')
        expect(command).to be_a(RobotChallenge::Commands::PlaceCommand)
        expect(command.x).to eq('invalid')
        expect(command.y).to eq('invalid')
        expect(command.direction_name).to eq('INVALID')
      end
    end
  end
end
