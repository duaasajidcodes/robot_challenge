# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

RSpec.describe 'Large Dataset Streaming Performance' do
  let(:table) { RobotChallenge::Table.new }
  let(:robot) { RobotChallenge::Robot.new(table) }
  let(:output_messages) { [] }
  let(:output_handler) { ->(message) { output_messages << message } }
  let(:processor) { RobotChallenge::CommandProcessor.new(robot, output_handler) }

  describe 'memory-efficient streaming approach' do
    it 'processes large files without loading entire content into memory' do
      # Create a large temporary file
      Tempfile.create(['large_commands', '.txt']) do |temp_file|
        # Write 100,000 commands to file
        temp_file.puts 'PLACE 2,2,NORTH'
        100_000.times do |i|
          temp_file.puts 'MOVE' if i % 4 == 0
          temp_file.puts 'RIGHT' if i % 4 == 1
          temp_file.puts 'MOVE' if i % 4 == 2
          temp_file.puts 'LEFT' if i % 4 == 3
        end
        temp_file.puts 'REPORT'
        temp_file.rewind

        # Measure memory usage before processing
        initial_memory = memory_usage_mb

        # Process using streaming approach
        start_time = Time.now
        processor.process_command_stream(temp_file)
        end_time = Time.now

        # Measure memory usage after processing
        final_memory = memory_usage_mb
        duration = end_time - start_time
        memory_growth = final_memory - initial_memory

        # Assertions
        expect(duration).to be < 10.0 # Should complete in reasonable time
        expect(memory_growth).to be < 100 # Should use less than 100MB additional memory
        expect(output_messages).not_to be_empty # Should produce output
        expect(output_messages.last).to match(/\d+,\d+,(NORTH|EAST|SOUTH|WEST)/)

        puts "Processed 100,000 commands in #{duration.round(2)}s using #{memory_growth.round(2)}MB additional memory"
      end
    end

    it 'handles extremely large files through Application streaming' do
      output = StringIO.new

      Tempfile.create(['huge_commands', '.txt']) do |temp_file|
        # Write 50,000 commands
        temp_file.puts 'PLACE 1,1,EAST'
        50_000.times do |i|
          temp_file.puts(%w[MOVE LEFT RIGHT][i % 3])
        end
        temp_file.puts 'REPORT'
        temp_file.rewind

        # Use Application with streaming
        app = RobotChallenge::Application.new(
          input_source: temp_file,
          output_destination: output
        )

        start_time = Time.now
        app.run
        duration = Time.now - start_time

        expect(duration).to be < 5.0
        expect(output.string).to include(',')
        expect(output.string).to match(/\d+,\d+,(NORTH|EAST|SOUTH|WEST)/)

        puts "Application processed 50,000 commands in #{duration.round(2)}s"
      end
    end

    it 'demonstrates constant memory usage regardless of file size' do
      memory_measurements = []

      [1_000, 10_000, 50_000].each do |command_count|
        Tempfile.create(["commands_#{command_count}", '.txt']) do |temp_file|
          temp_file.puts 'PLACE 0,0,NORTH'
          command_count.times { temp_file.puts 'MOVE' }
          temp_file.puts 'REPORT'
          temp_file.rewind

          # Reset robot state
          robot.reset
          output_messages.clear

          initial_memory = memory_usage_mb
          processor.process_command_stream(temp_file)
          final_memory = memory_usage_mb

          memory_growth = final_memory - initial_memory
          memory_measurements << memory_growth

          puts "#{command_count} commands: #{memory_growth.round(2)}MB memory growth"
        end
      end

      # Memory growth should be relatively constant, not proportional to file size
      max_growth = memory_measurements.max
      min_growth = memory_measurements.min

      # Memory growth variance should be minimal (less than 50MB difference)
      expect(max_growth - min_growth).to be < 50
      expect(memory_measurements).to all(be < 100) # All should use less than 100MB
    end
  end

  describe 'comparison: streaming vs memory-loading approaches' do
    it 'demonstrates memory efficiency difference' do
      commands = []
      commands << 'PLACE 2,2,NORTH'
      10_000.times { |i| commands << %w[MOVE LEFT RIGHT][i % 3] }
      commands << 'REPORT'

      # Test memory-loading approach (legacy)
      robot.reset
      output_messages.clear
      initial_memory = memory_usage_mb

      # Suppress warning for test
      allow(processor).to receive(:warn)
      processor.process_commands(commands)

      memory_loading_growth = memory_usage_mb - initial_memory

      # Test streaming approach
      Tempfile.create(['streaming_test', '.txt']) do |temp_file|
        commands.each { |cmd| temp_file.puts cmd }
        temp_file.rewind

        robot.reset
        output_messages.clear
        initial_memory = memory_usage_mb

        processor.process_command_stream(temp_file)

        streaming_memory_growth = memory_usage_mb - initial_memory

        puts "Memory loading approach: #{memory_loading_growth.round(2)}MB"
        puts "Streaming approach: #{streaming_memory_growth.round(2)}MB"

        # Streaming should use significantly less memory
        expect(streaming_memory_growth).to be <= memory_loading_growth
      end
    end
  end

  describe 'edge cases with streaming' do
    it 'handles empty files' do
      Tempfile.create(['empty', '.txt']) do |temp_file|
        temp_file.rewind
        expect { processor.process_command_stream(temp_file) }.not_to raise_error
      end
    end

    it 'handles files with only whitespace' do
      Tempfile.create(['whitespace', '.txt']) do |temp_file|
        temp_file.puts '   '
        temp_file.puts ''
        temp_file.puts "\t\t"
        temp_file.rewind

        expect { processor.process_command_stream(temp_file) }.not_to raise_error
        expect(output_messages).to be_empty
      end
    end

    it 'handles files with mixed valid and invalid commands' do
      Tempfile.create(['mixed', '.txt']) do |temp_file|
        temp_file.puts 'PLACE 1,1,NORTH'
        temp_file.puts 'INVALID_COMMAND'
        temp_file.puts 'MOVE'
        temp_file.puts 'ANOTHER_INVALID'
        temp_file.puts 'REPORT'
        temp_file.rewind

        processor.process_command_stream(temp_file)
        expect(output_messages).to eq(['1,2,NORTH'])
      end
    end

    it 'stops processing on EXIT command in large files' do
      Tempfile.create(['exit_test', '.txt']) do |temp_file|
        temp_file.puts 'PLACE 0,0,NORTH'
        temp_file.puts 'MOVE'
        temp_file.puts 'EXIT'
        1000.times { temp_file.puts 'MOVE' } # Should not be processed
        temp_file.puts 'REPORT' # Should not be processed
        temp_file.rewind

        processor.process_command_stream(temp_file)
        expect(output_messages).to be_empty # No REPORT should have been executed
      end
    end
  end

  private

  def memory_usage_mb
    # Get memory usage in MB (works on most Unix systems)

    `ps -o rss= -p #{Process.pid}`.to_i / 1024.0
  rescue StandardError
    0 # Fallback if ps command not available
  end
end
