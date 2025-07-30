# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RobotChallenge::CommandProcessor do
  let(:table) { RobotChallenge::Table.new }
  let(:robot) { RobotChallenge::Robot.new(table) }
  let(:output_messages) { [] }
  let(:output_handler) { ->(message) { output_messages << message } }
  let(:processor) { described_class.new(robot, output_handler) }

  describe '#initialize' do
    it 'accepts robot and output handler' do
      expect(processor.robot).to eq(robot)
      expect(processor.output_handler).to eq(output_handler)
    end

    it 'uses default output handler when none provided' do
      default_processor = described_class.new(robot)
      expect(default_processor.output_handler).to be_a(Method)
    end
  end

  describe '#process_command' do
    context 'with nil command' do
      it 'returns false and does nothing' do
        result = processor.process_command(nil)
        expect(result).to be false
        expect(robot).not_to be_placed
      end
    end

    context 'with place command' do
      let(:place_command) { { command: :place, x: 1, y: 2, direction: 'NORTH' } }

      it 'places robot at specified position and direction' do
        result = processor.process_command(place_command)

        expect(result).to be false # Continue processing
        expect(robot).to be_placed
        expect(robot.position.x).to eq(1)
        expect(robot.position.y).to eq(2)
        expect(robot.direction.name).to eq('NORTH')
      end

      it 'handles invalid position gracefully' do
        invalid_command = { command: :place, x: 10, y: 10, direction: 'NORTH' }
        result = processor.process_command(invalid_command)

        expect(result).to be false
        expect(robot).not_to be_placed
      end

      it 'handles invalid direction gracefully' do
        expect do
          processor.process_command({ command: :place, x: 1, y: 2, direction: 'INVALID' })
        end.not_to raise_error
        expect(robot).not_to be_placed
      end
    end

    context 'with move command' do
      let(:move_command) { { command: :move } }

      it 'moves placed robot' do
        robot.place(RobotChallenge::Position.new(1, 1), RobotChallenge::Direction.new('NORTH'))

        result = processor.process_command(move_command)

        expect(result).to be false
        expect(robot.position.y).to eq(2)
      end

      it 'handles move on unplaced robot gracefully' do
        result = processor.process_command(move_command)

        expect(result).to be false
        expect(robot).not_to be_placed
      end
    end

    context 'with left command' do
      let(:left_command) { { command: :left } }

      it 'turns placed robot left' do
        robot.place(RobotChallenge::Position.new(1, 1), RobotChallenge::Direction.new('NORTH'))

        result = processor.process_command(left_command)

        expect(result).to be false
        expect(robot.direction.name).to eq('WEST')
      end

      it 'handles left turn on unplaced robot gracefully' do
        result = processor.process_command(left_command)

        expect(result).to be false
        expect(robot).not_to be_placed
      end
    end

    context 'with right command' do
      let(:right_command) { { command: :right } }

      it 'turns placed robot right' do
        robot.place(RobotChallenge::Position.new(1, 1), RobotChallenge::Direction.new('NORTH'))

        result = processor.process_command(right_command)

        expect(result).to be false
        expect(robot.direction.name).to eq('EAST')
      end

      it 'handles right turn on unplaced robot gracefully' do
        result = processor.process_command(right_command)

        expect(result).to be false
        expect(robot).not_to be_placed
      end
    end

    context 'with report command' do
      let(:report_command) { { command: :report } }

      it 'generates report for placed robot' do
        robot.place(RobotChallenge::Position.new(2, 3), RobotChallenge::Direction.new('EAST'))

        result = processor.process_command(report_command)

        expect(result).to be false
        expect(output_messages).to eq(['2,3,EAST'])
      end

      it 'handles report on unplaced robot gracefully' do
        result = processor.process_command(report_command)

        expect(result).to be false
        expect(output_messages).to be_empty
      end
    end

    context 'with exit command' do
      let(:exit_command) { { command: :exit } }

      it 'returns true to signal exit' do
        result = processor.process_command(exit_command)
        expect(result).to be true
      end
    end

    context 'with quit command' do
      let(:quit_command) { { command: :quit } }

      it 'returns true to signal exit' do
        result = processor.process_command(quit_command)
        expect(result).to be true
      end
    end

    context 'with unknown command' do
      let(:unknown_command) { { command: :unknown } }

      it 'returns false and does nothing' do
        result = processor.process_command(unknown_command)
        expect(result).to be false
        expect(robot).not_to be_placed
      end
    end
  end

  describe '#process_commands' do
    it 'processes multiple command strings in sequence' do
      commands = [
        'PLACE 0,0,NORTH',
        'MOVE',
        'RIGHT',
        'MOVE',
        'REPORT'
      ]

      processor.process_commands(commands)

      expect(robot.report).to eq('1,1,EAST')
      expect(output_messages).to eq(['1,1,EAST'])
    end

    it 'stops processing on exit command' do
      commands = [
        'PLACE 0,0,NORTH',
        'MOVE',
        'EXIT',
        'REPORT'
      ]

      processor.process_commands(commands)

      expect(output_messages).to be_empty # REPORT never executed
    end

    it 'handles invalid commands gracefully' do
      commands = [
        'INVALID',
        'PLACE 0,0,NORTH',
        'INVALID_MOVE',
        'REPORT'
      ]

      processor.process_commands(commands)

      expect(output_messages).to eq(['0,0,NORTH'])
    end

    it 'handles empty command list' do
      expect { processor.process_commands([]) }.not_to raise_error
    end

    it 'ignores commands before first valid PLACE' do
      commands = [
        'MOVE',
        'LEFT',
        'REPORT',
        'PLACE 1,1,SOUTH',
        'REPORT'
      ]

      processor.process_commands(commands)

      expect(output_messages).to eq(['1,1,SOUTH'])
    end
  end

  describe 'integration scenarios' do
    it 'handles example 1 from requirements' do
      commands = [
        'PLACE 0,0,NORTH',
        'MOVE',
        'REPORT'
      ]

      processor.process_commands(commands)

      expect(output_messages).to eq(['0,1,NORTH'])
    end

    it 'handles example 2 from requirements' do
      commands = [
        'PLACE 0,0,NORTH',
        'LEFT',
        'REPORT'
      ]

      processor.process_commands(commands)

      expect(output_messages).to eq(['0,0,WEST'])
    end

    it 'handles example 3 from requirements' do
      commands = [
        'PLACE 1,2,EAST',
        'MOVE',
        'MOVE',
        'LEFT',
        'MOVE',
        'REPORT'
      ]

      processor.process_commands(commands)

      expect(output_messages).to eq(['3,3,NORTH'])
    end

    it 'handles boundary collision scenarios' do
      commands = [
        'PLACE 0,0,SOUTH',
        'MOVE', # Should be ignored
        'MOVE', # Should be ignored
        'REPORT'
      ]

      processor.process_commands(commands)

      expect(output_messages).to eq(['0,0,SOUTH'])
    end

    it 'handles multiple reports' do
      commands = [
        'PLACE 2,2,NORTH',
        'REPORT',
        'MOVE',
        'REPORT',
        'RIGHT',
        'REPORT'
      ]

      processor.process_commands(commands)

      expect(output_messages).to eq(['2,2,NORTH', '2,3,NORTH', '2,3,EAST'])
    end

    it 'handles re-placement during execution' do
      commands = [
        'PLACE 0,0,NORTH',
        'MOVE',
        'PLACE 4,4,SOUTH',
        'REPORT'
      ]

      processor.process_commands(commands)

      expect(output_messages).to eq(['4,4,SOUTH'])
    end

    it 'handles malformed input gracefully' do
      commands = [
        'PLACE abc,def,INVALID',
        'PLACE 1,1,NORTH',
        'MOVE EXTRA',
        'REPORT'
      ]

      processor.process_commands(commands)

      expect(output_messages).to eq(['1,1,NORTH'])
    end
  end

  describe 'error handling' do
    it 'silently handles robot errors without crashing' do
      # Force an error by trying to place at invalid position
      command = { command: :place, x: 10, y: 10, direction: 'NORTH' }

      expect { processor.process_command(command) }.not_to raise_error
      expect(robot).not_to be_placed
    end

    it 'continues processing after errors' do
      commands = [
        'PLACE 10,10,NORTH', # Invalid position
        'MOVE', # Invalid on unplaced robot
        'PLACE 1,1,NORTH', # Valid
        'REPORT'
      ]

      processor.process_commands(commands)

      expect(output_messages).to eq(['1,1,NORTH'])
    end
  end
end
