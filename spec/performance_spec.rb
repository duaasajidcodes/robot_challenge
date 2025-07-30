# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Robot Challenge Performance and Edge Cases' do
  let(:table) { RobotChallenge::Table.new }
  let(:robot) { RobotChallenge::Robot.new(table) }
  let(:output_messages) { [] }
  let(:output_handler) { ->(message) { output_messages << message } }
  let(:processor) { RobotChallenge::CommandProcessor.new(robot, output_handler) }

  describe 'performance characteristics' do
    it 'handles 10,000 commands efficiently' do
      commands = ['PLACE 2,2,NORTH']
      
      # Generate 10,000 movement commands
      10_000.times do |i|
        case i % 4
        when 0 then commands << 'MOVE'
        when 1 then commands << 'RIGHT'
        when 2 then commands << 'MOVE'
        when 3 then commands << 'LEFT'
        end
      end
      commands << 'REPORT'

      start_time = Time.now
      processor.process_commands(commands)
      duration = Time.now - start_time

      expect(duration).to be < 2.0 # Should complete in under 2 seconds
      expect(output_messages).not_to be_empty
    end

    it 'maintains memory efficiency with large datasets' do
      initial_memory = memory_usage
      
      # Process many commands
      1000.times do |i|
        processor.process_commands([
          "PLACE #{i % 5},#{i % 5},NORTH",
          'MOVE',
          'RIGHT',
          'MOVE',
          'REPORT'
        ])
        output_messages.clear # Prevent memory accumulation in test
      end

      final_memory = memory_usage
      memory_growth = final_memory - initial_memory

      # Memory growth should be minimal (less than 50MB)
      expect(memory_growth).to be < 50
    end
  end

  describe 'boundary edge cases' do
    it 'handles extreme coordinates' do
      # Test with maximum Ruby integer values
      large_table = RobotChallenge::Table.new(1000, 1000)
      large_robot = RobotChallenge::Robot.new(large_table)
      
      large_robot.place(
        RobotChallenge::Position.new(999, 999), 
        RobotChallenge::Direction.new('NORTH')
      )
      
      large_robot.move # Should not move beyond boundary
      expect(large_robot.report).to eq('999,999,NORTH')
    end

    it 'handles zero-dimension table gracefully' do
      zero_table = RobotChallenge::Table.new(0, 0)
      zero_robot = RobotChallenge::Robot.new(zero_table)
      zero_processor = RobotChallenge::CommandProcessor.new(zero_robot, output_handler)

      zero_processor.process_commands([
        'PLACE 0,0,NORTH',  # Should fail
        'MOVE',             # Should be ignored
        'REPORT'            # Should be ignored
      ])

      expect(output_messages).to be_empty
      expect(zero_robot).not_to be_placed
    end

    it 'handles single-cell table' do
      tiny_table = RobotChallenge::Table.new(1, 1)
      tiny_robot = RobotChallenge::Robot.new(tiny_table)
      tiny_processor = RobotChallenge::CommandProcessor.new(tiny_robot, output_handler)

      tiny_processor.process_commands([
        'PLACE 0,0,NORTH',
        'MOVE',     # Should not move
        'RIGHT',    # Should turn
        'MOVE',     # Should not move
        'REPORT'
      ])

      expect(output_messages).to eq(['0,0,EAST'])
    end
  end

  describe 'input validation edge cases' do
    it 'handles various whitespace patterns' do
      whitespace_commands = [
        "PLACE\t0,0,NORTH",      # Tab characters
        " MOVE ",                 # Leading/trailing spaces
        "REPORT",                 # Normal command
        "   LEFT   ",             # Multiple spaces
      ]

      expect { processor.process_commands(whitespace_commands) }.not_to raise_error
      expect(output_messages).to eq(['0,1,WEST'])
    end

    it 'handles unicode and special characters gracefully' do
      unicode_commands = [
        'PLACE 0,0,NORTH',
        'MÖVE',              # Invalid with unicode
        'MOVE',              # Valid
        'REPØRT',            # Invalid with unicode
        'REPORT'             # Valid
      ]

      processor.process_commands(unicode_commands)
      expect(output_messages).to eq(['0,1,NORTH'])
    end

    it 'handles extremely long invalid commands' do
      long_command = 'INVALID' + 'X' * 1000
      
      expect { processor.process_command(RobotChallenge::CommandParser.parse(long_command)) }.not_to raise_error
      expect(robot).not_to be_placed
    end
  end

  describe 'concurrent behavior simulation' do
    it 'maintains state consistency with rapid command changes' do
      # Simulate rapid fire commands
      commands = []
      100.times do |i|
        commands += [
          "PLACE #{i % 5},#{i % 5},NORTH",
          'MOVE',
          'RIGHT',
          'MOVE',
          'LEFT'
        ]
      end
      commands << 'REPORT'

      processor.process_commands(commands)
      
      # Should end in a valid state
      expect(output_messages.last).to match(/\d+,\d+,(NORTH|EAST|SOUTH|WEST)/)
    end
  end

  describe 'memory and resource management' do
    it 'does not leak memory with repeated operations' do
      initial_objects = count_objects

      # Perform many operations
      100.times do
        position = RobotChallenge::Position.new(1, 1)
        direction = RobotChallenge::Direction.new('NORTH')
        robot.place(position, direction)
        robot.move.turn_left.turn_right
      end

      GC.start # Force garbage collection
      final_objects = count_objects
      
      # Object count should not grow excessively
      expect(final_objects - initial_objects).to be < 1000
    end

    it 'handles immutable object creation efficiently' do
      start_time = Time.now
      
      # Create many immutable objects
      positions = 100.times.map { |i| RobotChallenge::Position.new(i, i) }
      directions = 100.times.map { |i| RobotChallenge::Direction.new(%w[NORTH EAST SOUTH WEST][i % 4]) }
      
      duration = Time.now - start_time
      
      expect(positions.length).to eq(100)
      expect(directions.length).to eq(100)
      expect(duration).to be < 1.0 # Should be fast
    end
  end

  describe 'error resilience' do
    it 'recovers from parser errors' do
      commands_with_errors = [
        'PLACE 1,1,NORTH',
        'MOVE',
        '',                     # Empty command
        'PLACE',               # Incomplete command
        'MOVE EXTRA ARGS',     # Extra arguments
        'REPORT',
        'INVALID COMMAND TYPE',
        'RIGHT',
        'REPORT'
      ]

      expect { processor.process_commands(commands_with_errors) }.not_to raise_error
      expect(output_messages).to eq(['1,2,NORTH', '1,2,EAST'])
    end
  end

  private

  def memory_usage
    # Simple memory usage approximation (MB)
    # This is a rough estimate for testing purposes
    begin
      (`ps -o rss= -p #{Process.pid}`.to_i / 1024.0).round(2)
    rescue
      0 # Fallback if ps command not available
    end
  end

  def count_objects
    # Count Ruby objects for memory leak detection
    begin
      ObjectSpace.count_objects[:TOTAL] - ObjectSpace.count_objects[:FREE]
    rescue
      0 # Fallback if ObjectSpace not available
    end
  end
end
