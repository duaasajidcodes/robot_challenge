# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

RSpec.describe 'Robot Challenge Performance and Edge Cases' do
  let(:table) { RobotChallenge::Table.new }
  let(:robot) { RobotChallenge::Robot.new(table) }
  let(:output_messages) { [] }
  let(:output_handler) { ->(message) { output_messages << message } }
  let(:processor) { RobotChallenge::CommandProcessor.new(robot, output_handler) }

  describe 'streaming performance characteristics' do
    it 'handles 10,000 commands efficiently with constant memory' do
      Tempfile.create(['large_test', '.txt']) do |temp_file|
        temp_file.puts 'PLACE 2,2,NORTH'
        
        # Generate 10,000 movement commands
        10_000.times do |i|
          case i % 4
          when 0 then temp_file.puts 'MOVE'
          when 1 then temp_file.puts 'RIGHT'
          when 2 then temp_file.puts 'MOVE'
          when 3 then temp_file.puts 'LEFT'
          end
        end
        temp_file.puts 'REPORT'
        temp_file.rewind

        initial_memory = memory_usage_mb
        start_time = Time.now
        processor.process_command_stream(temp_file)
        duration = Time.now - start_time
        final_memory = memory_usage_mb

        expect(duration).to be < 5.0 # Should complete in under 5 seconds
        expect(final_memory - initial_memory).to be < 50 # Should use < 50MB additional memory
        expect(output_messages).not_to be_empty
      end
    end

    it 'maintains constant memory usage regardless of file size' do
      memory_growths = []

      [1_000, 5_000, 10_000].each do |command_count|
        Tempfile.create(["test_#{command_count}", '.txt']) do |temp_file|
          temp_file.puts 'PLACE 1,1,NORTH'
          command_count.times { |i| temp_file.puts %w[MOVE LEFT RIGHT][i % 3] }
          temp_file.puts 'REPORT'
          temp_file.rewind

          robot.reset
          output_messages.clear

          initial_memory = memory_usage_mb
          processor.process_command_stream(temp_file)
          final_memory = memory_usage_mb

          memory_growth = final_memory - initial_memory
          memory_growths << memory_growth
        end
      end

      # Memory growth should be relatively constant, not proportional to file size
      expect(memory_growths.max - memory_growths.min).to be < 25
      expect(memory_growths).to all(be < 50)
    end
  end

  describe 'boundary edge cases' do
    it 'handles extreme coordinates' do
      # Test with large table
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

      Tempfile.create(['zero_test', '.txt']) do |temp_file|
        temp_file.puts 'PLACE 0,0,NORTH'  # Should fail
        temp_file.puts 'MOVE'             # Should be ignored
        temp_file.puts 'REPORT'           # Should be ignored
        temp_file.rewind

        zero_processor.process_command_stream(temp_file)
      end

      expect(output_messages).to be_empty
      expect(zero_robot).not_to be_placed
    end

    it 'handles single-cell table' do
      tiny_table = RobotChallenge::Table.new(1, 1)
      tiny_robot = RobotChallenge::Robot.new(tiny_table)
      tiny_processor = RobotChallenge::CommandProcessor.new(tiny_robot, output_handler)

      Tempfile.create(['tiny_test', '.txt']) do |temp_file|
        temp_file.puts 'PLACE 0,0,NORTH'
        temp_file.puts 'MOVE'     # Should not move
        temp_file.puts 'RIGHT'    # Should turn
        temp_file.puts 'MOVE'     # Should not move
        temp_file.puts 'REPORT'
        temp_file.rewind

        tiny_processor.process_command_stream(temp_file)
      end

      expect(output_messages).to eq(['0,0,EAST'])
    end
  end

  describe 'input validation edge cases' do
    it 'handles various whitespace patterns' do
      Tempfile.create(['whitespace_test', '.txt']) do |temp_file|
        temp_file.puts "PLACE\t0,0,NORTH"      # Tab characters
        temp_file.puts " MOVE "                 # Leading/trailing spaces
        temp_file.puts "REPORT"                 # Normal command
        temp_file.puts "   LEFT   "             # Multiple spaces
        temp_file.rewind

        expect { processor.process_command_stream(temp_file) }.not_to raise_error
        expect(output_messages).to eq(['0,1,WEST'])
      end
    end

    it 'handles unicode and special characters gracefully' do
      Tempfile.create(['unicode_test', '.txt']) do |temp_file|
        temp_file.puts 'PLACE 0,0,NORTH'
        temp_file.puts 'MÖVE'              # Invalid with unicode
        temp_file.puts 'MOVE'              # Valid
        temp_file.puts 'REPØRT'            # Invalid with unicode
        temp_file.puts 'REPORT'            # Valid
        temp_file.rewind

        processor.process_command_stream(temp_file)
        expect(output_messages).to eq(['0,1,NORTH'])
      end
    end

    it 'handles extremely long invalid commands' do
      Tempfile.create(['long_test', '.txt']) do |temp_file|
        temp_file.puts 'PLACE 1,1,NORTH'
        temp_file.puts 'INVALID' + 'X' * 1000  # Very long invalid command
        temp_file.puts 'REPORT'
        temp_file.rewind
        
        expect { processor.process_command_stream(temp_file) }.not_to raise_error
        expect(output_messages).to eq(['1,1,NORTH'])
      end
    end
  end

  describe 'concurrent behavior simulation' do
    it 'maintains state consistency with rapid command changes' do
      Tempfile.create(['rapid_test', '.txt']) do |temp_file|
        # Simulate rapid fire commands
        100.times do |i|
          temp_file.puts "PLACE #{i % 5},#{i % 5},NORTH"
          temp_file.puts 'MOVE'
          temp_file.puts 'RIGHT'
          temp_file.puts 'MOVE'
          temp_file.puts 'LEFT'
        end
        temp_file.puts 'REPORT'
        temp_file.rewind

        processor.process_command_stream(temp_file)
        
        # Should end in a valid state
        expect(output_messages.last).to match(/\d+,\d+,(NORTH|EAST|SOUTH|WEST)/)
      end
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
      Tempfile.create(['error_test', '.txt']) do |temp_file|
        temp_file.puts 'PLACE 1,1,NORTH'
        temp_file.puts 'MOVE'
        temp_file.puts ''                     # Empty command
        temp_file.puts 'PLACE'               # Incomplete command
        temp_file.puts 'MOVE EXTRA ARGS'     # Extra arguments
        temp_file.puts 'REPORT'
        temp_file.puts 'INVALID COMMAND TYPE'
        temp_file.puts 'RIGHT'
        temp_file.puts 'REPORT'
        temp_file.rewind

        expect { processor.process_command_stream(temp_file) }.not_to raise_error
        expect(output_messages).to eq(['1,2,NORTH', '1,2,EAST'])
      end
    end
  end

  private

  def memory_usage_mb
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
