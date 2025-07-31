# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Robot Challenge Integration' do
  describe 'end-to-end scenarios' do
    let(:table) { RobotChallenge::Table.new }
    let(:robot) { RobotChallenge::Robot.new(table) }
    let(:output_messages) { [] }
    let(:output_handler) { ->(message) { output_messages << message } }
    let(:processor) { RobotChallenge::CommandProcessor.new(robot, output_handler) }

    context 'requirement examples' do
      it 'passes example 1: PLACE 0,0,NORTH; MOVE; REPORT' do
        commands = [
          'PLACE 0,0,NORTH',
          'MOVE',
          'REPORT'
        ].map { |cmd| cmd.gsub('\\', '') }

        processor.process_commands(commands)

        expect(output_messages).to eq(['0,1,NORTH'])
      end

      it 'passes example 2: PLACE 0,0,NORTH; LEFT; REPORT' do
        commands = [
          'PLACE 0,0,NORTH',
          'LEFT',
          'REPORT'
        ].map { |cmd| cmd.gsub('\\', '') }

        processor.process_commands(commands)

        expect(output_messages).to eq(['0,0,WEST'])
      end

      it 'passes example 3: PLACE 1,2,EAST; MOVE; MOVE; LEFT; MOVE; REPORT' do
        commands = [
          'PLACE 1,2,EAST',
          'MOVE',
          'MOVE',
          'LEFT',
          'MOVE',
          'REPORT'
        ].map { |cmd| cmd.gsub('\\', '') }

        processor.process_commands(commands)

        expect(output_messages).to eq(['3,3,NORTH'])
      end
    end

    context 'boundary testing' do
      it 'prevents robot from falling off all edges' do
        # Test north boundary
        processor.process_commands(['PLACE 2,4,NORTH', 'MOVE', 'REPORT'])
        expect(output_messages.last).to eq('2,4,NORTH')
        output_messages.clear

        # Reset and test east boundary
        processor.process_commands(['PLACE 4,2,EAST', 'MOVE', 'REPORT'])
        expect(output_messages.last).to eq('4,2,EAST')
        output_messages.clear

        # Reset and test south boundary
        processor.process_commands(['PLACE 2,0,SOUTH', 'MOVE', 'REPORT'])
        expect(output_messages.last).to eq('2,0,SOUTH')
        output_messages.clear

        # Reset and test west boundary
        processor.process_commands(['PLACE 0,2,WEST', 'MOVE', 'REPORT'])
        expect(output_messages.last).to eq('0,2,WEST')
      end

      it 'handles corner scenarios' do
        # Southwest corner
        processor.process_commands(['PLACE 0,0,SOUTH', 'MOVE', 'LEFT', 'MOVE', 'REPORT'])
        expect(output_messages.last).to eq('0,0,EAST')
        output_messages.clear

        # Northwest corner
        processor.process_commands(['PLACE 0,4,NORTH', 'MOVE', 'RIGHT', 'MOVE', 'REPORT'])
        expect(output_messages.last).to eq('1,4,EAST')
        output_messages.clear

        # Northeast corner
        processor.process_commands(['PLACE 4,4,NORTH', 'MOVE', 'RIGHT', 'MOVE', 'REPORT'])
        expect(output_messages.last).to eq('4,4,EAST')
        output_messages.clear

        # Southeast corner
        processor.process_commands(['PLACE 4,0,SOUTH', 'MOVE', 'LEFT', 'MOVE', 'REPORT'])
        expect(output_messages.last).to eq('4,0,EAST')
      end
    end

    context 'complex navigation scenarios' do
      it 'navigates entire perimeter clockwise' do
        commands = [
          'PLACE 0,0,NORTH',
          'MOVE', 'MOVE', 'MOVE', 'MOVE', # North edge
          'RIGHT',                        # Face east
          'MOVE', 'MOVE', 'MOVE', 'MOVE', # East edge
          'RIGHT',                        # Face south
          'MOVE', 'MOVE', 'MOVE', 'MOVE', # South edge
          'RIGHT',                        # Face west
          'MOVE', 'MOVE', 'MOVE', 'MOVE', # Back to start
          'REPORT'
        ]

        processor.process_commands(commands)
        expect(output_messages.last).to eq('0,0,WEST')
      end

      it 'handles spiral pattern' do
        commands = [
          'PLACE 2,2,NORTH',
          'MOVE', 'RIGHT',               # 2,3,EAST
          'MOVE', 'MOVE', 'RIGHT',       # 4,3,SOUTH
          'MOVE', 'MOVE', 'RIGHT',       # 4,1,WEST
          'MOVE', 'MOVE', 'MOVE', 'RIGHT', # 1,1,NORTH
          'MOVE', 'RIGHT',               # 1,2,EAST
          'MOVE', 'REPORT'               # 2,2,EAST
        ]

        processor.process_commands(commands)
        expect(output_messages.last).to eq('2,2,EAST')
      end
    end

    context 'error recovery scenarios' do
      it 'recovers from invalid initial commands' do
        commands = [
          'MOVE',                    # Invalid - robot not placed
          'LEFT',                    # Invalid - robot not placed
          'REPORT',                  # Invalid - robot not placed
          'PLACE invalid,position',  # Invalid - malformed
          'PLACE 10,10,NORTH',      # Invalid - outside bounds
          'PLACE 1,1,NORTH',        # Valid - finally places robot
          'REPORT'
        ]

        processor.process_commands(commands)
        expect(output_messages).to eq(['1,1,NORTH'])
      end

      it 'handles mixed valid and invalid commands' do
        commands = [
          'PLACE 2,2,NORTH',
          'MOVE',
          'INVALID_COMMAND',
          'LEFT',
          'MOVE_WITH_ARGS extra',
          'REPORT',
          'PLACE abc,def,INVALID',
          'RIGHT',
          'REPORT'
        ]

        processor.process_commands(commands)
        expect(output_messages).to eq(['2,3,WEST', '2,3,NORTH'])
      end
    end

    context 'performance and stress testing' do
      it 'handles large number of movements efficiently' do
        commands = ['PLACE 2,2,NORTH']
        # Add 1000 rotations (should end up facing NORTH again)
        1000.times { commands << 'LEFT' }
        commands << 'REPORT'

        start_time = Time.now
        processor.process_commands(commands)
        end_time = Time.now

        expect(output_messages.last).to eq('2,2,NORTH')
        expect(end_time - start_time).to be < 1.0 # Should complete quickly
      end

      it 'handles rapid placement changes' do
        commands = []
        # Place robot at every valid position
        (0...5).each do |y|
          (0...5).each do |x|
            commands << "PLACE #{x},#{y},NORTH"
          end
        end
        commands << 'REPORT'

        processor.process_commands(commands)
        expect(output_messages.last).to eq('4,4,NORTH') # Last placement
      end
    end

    context 'state consistency' do
      it 'maintains consistent state through complex operations' do
        commands = [
          'PLACE 0,0,NORTH',
          'MOVE', 'MOVE', 'MOVE', 'MOVE', # Move to north edge
          'RIGHT', 'RIGHT',               # Face south
          'MOVE', 'MOVE',                 # Move south
          'LEFT',                         # Face east
          'MOVE', 'MOVE', 'MOVE', 'MOVE', # Move to east edge
          'REPORT'
        ]

        processor.process_commands(commands)
        expect(output_messages.last).to eq('4,2,EAST')
      end

      it 'handles multiple PLACE commands correctly' do
        commands = [
          'PLACE 0,0,NORTH',
          'MOVE',
          'PLACE 4,4,SOUTH',  # Replace position
          'MOVE',
          'PLACE 2,2,EAST',   # Replace again
          'REPORT'
        ]

        processor.process_commands(commands)
        expect(output_messages.last).to eq('2,2,EAST')
      end
    end
  end

  describe 'file-based testing' do
    let(:output_messages) { [] }
    let(:output_handler) { ->(message) { output_messages << message } }

    def process_file(filename)
      table = RobotChallenge::Table.new
      robot = RobotChallenge::Robot.new(table)
      processor = RobotChallenge::CommandProcessor.new(robot, output_handler)

      # Stream processing - no memory accumulation
      File.open("/Users/duaasajid/Desktop/robot_challenge/test_data/#{filename}", 'r') do |file|
        file.each_line do |line|
          command_string = line.chomp
          next if command_string.empty?

          command = RobotChallenge::CommandParser.parse(command_string)
          should_exit = processor.process_command(command)
          break if should_exit
        end
      end
    end

    it 'processes example_1.txt correctly' do
      process_file('example_1.txt')
      expect(output_messages).to eq(['0,1,NORTH'])
    end

    it 'processes example_2.txt correctly' do
      process_file('example_2.txt')
      expect(output_messages).to eq(['0,0,WEST'])
    end

    it 'processes example_3.txt correctly' do
      process_file('example_3.txt')
      expect(output_messages).to eq(['3,3,NORTH'])
    end

    it 'processes edge_cases.txt robustly' do
      expect { process_file('edge_cases.txt') }.not_to raise_error
      # Should have at least one valid report
      expect(output_messages).not_to be_empty
      expect(output_messages.last).to match(/\d+,\d+,(NORTH|EAST|SOUTH|WEST)/)
    end
  end

  describe 'architectural validation' do
    it 'demonstrates proper separation of concerns' do
      # Parser handles command parsing
      parsed = RobotChallenge::CommandParser.parse('PLACE 1,2,NORTH')
      expect(parsed).to be_a(Hash)

      # Robot handles state and movement logic
      expect(robot.respond_to?(:place)).to be true
      expect(robot.respond_to?(:move)).to be true

      # Table handles boundary validation
      expect(table.respond_to?(:valid_position?)).to be true

      # Processor orchestrates command execution
      expect(processor.respond_to?(:process_command)).to be true
    end

    it 'supports dependency injection' do
      # Custom table size
      custom_table = RobotChallenge::Table.new(10, 10)
      custom_robot = RobotChallenge::Robot.new(custom_table)

      # Custom output handler
      messages = []
      custom_handler = ->(msg) { messages << "LOG: #{msg}" }
      custom_processor = RobotChallenge::CommandProcessor.new(custom_robot, custom_handler)

      custom_processor.process_commands(['PLACE 5,5,NORTH', 'REPORT'])
      expect(messages).to eq(['LOG: 5,5,NORTH'])
    end

    it 'maintains immutability of value objects' do
      position = RobotChallenge::Position.new(1, 1)
      direction = RobotChallenge::Direction.new('NORTH')

      # Operations return new objects
      new_position = position.move(1, 0)
      new_direction = direction.turn_left

      expect(new_position).not_to be(position)
      expect(new_direction).not_to be(direction)
      expect(position.x).to eq(1) # Original unchanged
      expect(direction.name).to eq('NORTH') # Original unchanged
    end
  end

  describe 'extensibility demonstration' do
    it 'supports custom table dimensions' do
      large_table = RobotChallenge::Table.new(100, 100)
      large_robot = RobotChallenge::Robot.new(large_table)

      large_robot.place(RobotChallenge::Position.new(50, 50), RobotChallenge::Direction.new('NORTH'))
      large_robot.move

      expect(large_robot.report).to eq('50,51,NORTH')
    end

    it 'supports custom output handling' do
      json_messages = []
      json_handler = lambda do |message|
        parts = message.split(',')
        json_messages << {
          x: parts[0].to_i,
          y: parts[1].to_i,
          direction: parts[2]
        }
      end

      json_processor = RobotChallenge::CommandProcessor.new(robot, json_handler)
      json_processor.process_commands(['PLACE 3,4,SOUTH', 'REPORT'])

      expect(json_messages).to eq([{ x: 3, y: 4, direction: 'SOUTH' }])
    end
  end
end
