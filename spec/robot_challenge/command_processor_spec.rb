# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RobotChallenge::CommandProcessor do
  let(:table) { RobotChallenge::Table.new }
  let(:robot) { RobotChallenge::Robot.new(table) }
  let(:output_handler) { double('output_handler') }
  let(:processor) { described_class.new(robot, output_handler: output_handler) }

  describe '#initialize' do
    it 'sets robot and creates default output handler' do
      processor = described_class.new(robot)
      expect(processor.robot).to eq(robot)
      expect(processor.output_handler).to respond_to(:call)
    end

    it 'uses provided output handler' do
      expect(processor.output_handler).to eq(output_handler)
    end

    it 'creates default command factory' do
      expect(processor.command_factory).to be_a(RobotChallenge::Commands::CommandFactory)
    end
  end

  describe '#process_command_string' do
    context 'with valid command string' do
      it 'processes PLACE command' do
        result = processor.process_command_string('PLACE 1,2,NORTH')

        expect(result).to be false # Continue processing
        expect(robot.position.x).to eq(1)
        expect(robot.position.y).to eq(2)
        expect(robot.direction.name).to eq('NORTH')
      end

      it 'processes REPORT command and calls output handler' do
        robot.place(RobotChallenge::Position.new(1, 2), RobotChallenge::Direction.new('EAST'))
        expect(output_handler).to receive(:call).with('1,2,EAST')

        result = processor.process_command_string('REPORT')
        expect(result).to be false
      end
    end

    context 'with invalid command string' do
      it 'returns false and continues processing' do
        result = processor.process_command_string('INVALID')
        expect(result).to be false
      end

      it 'handles empty string gracefully' do
        result = processor.process_command_string('')
        expect(result).to be false
      end

      it 'handles nil input gracefully' do
        result = processor.process_command_string(nil)
        expect(result).to be false
      end
    end
  end

  describe '#process_command' do
    let(:command) { double('command') }

    context 'with nil command' do
      it 'returns false' do
        result = processor.process_command(nil)
        expect(result).to be false
      end
    end

    context 'with regular command' do
      let(:command_result) { { status: :success } }

      before do
        allow(command).to receive(:execute).with(robot).and_return(command_result)
      end

      it 'executes command and returns false' do
        result = processor.process_command(command)
        expect(result).to be false
      end

      context 'with output result' do
        let(:command_result) { { status: :output, message: 'test output' } }

        it 'calls output handler' do
          expect(output_handler).to receive(:call).with('test output')
          processor.process_command(command)
        end
      end

      context 'with error result' do
        let(:command_result) { { status: :error, message: 'error message' } }

        it 'handles error silently' do
          expect(output_handler).not_to receive(:call)
          result = processor.process_command(command)
          expect(result).to be false
        end
      end
    end
  end

  describe '#process_command_strings' do
    it 'processes multiple command strings' do
      robot_position = nil

      allow(output_handler).to receive(:call) do |message|
        robot_position = message
      end

      commands = [
        'PLACE 0,0,NORTH',
        'MOVE',
        'REPORT'
      ]

      processor.process_command_strings(commands)
      expect(robot_position).to eq('0,1,NORTH')
    end
  end

  describe '#available_commands' do
    it 'returns available commands from factory' do
      commands = processor.available_commands
      expect(commands).to include('PLACE', 'MOVE', 'LEFT', 'RIGHT', 'REPORT')
    end
  end

  describe '#register_command' do
    let(:custom_command_class) { Class.new(RobotChallenge::Commands::Command) }

    it 'registers command with factory' do
      processor.register_command('CUSTOM', custom_command_class)
      expect(processor.available_commands).to include('CUSTOM')
    end

    it 'allows processing registered custom commands' do
      custom_command_class = Class.new(RobotChallenge::Commands::Command) do
        def execute(_robot)
          { status: :output, message: 'Custom executed' }
        end
      end

      processor.register_command('CUSTOM', custom_command_class)
      processor.command_factory.register_parser(RobotChallenge::Commands::SimpleCommandParser.new('CUSTOM'))

      expect(output_handler).to receive(:call).with('Custom executed')
      processor.process_command_string('CUSTOM')
    end
  end

  describe 'extensibility demonstration' do
    it 'can add new commands without modifying existing code' do
      # Create a completely new command type
      status_command_class = Class.new(RobotChallenge::Commands::Command) do
        def execute(robot)
          return { status: :error, message: 'Robot not placed' } unless robot.placed?

          status = "Position: #{robot.position}, Direction: #{robot.direction}"
          { status: :output, message: status }
        end
      end

      # Register the new command
      processor.register_command('STATUS', status_command_class)
      processor.command_factory.register_parser(RobotChallenge::Commands::SimpleCommandParser.new('STATUS'))

      # Place robot and test new command
      processor.process_command_string('PLACE 2,3,SOUTH')

      expect(output_handler).to receive(:call).with('Position: 2,3, Direction: SOUTH')
      processor.process_command_string('STATUS')

      # Verify the command is available
      expect(processor.available_commands).to include('STATUS')
    end
  end
end
