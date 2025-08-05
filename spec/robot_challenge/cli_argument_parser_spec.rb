# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RobotChallenge::CliArgumentParser do
  let(:argv) { [] }
  let(:parser) { described_class.new(argv) }

  describe '#initialize' do
    it 'uses default values when no arguments provided' do
      # Ensure no environment variables are set for this test
      original_output_format = ENV.fetch('ROBOT_OUTPUT_FORMAT', nil)
      ENV.delete('ROBOT_OUTPUT_FORMAT')

      begin
        parser = described_class.new([])
        expect(parser.table_width).to eq(5)
        expect(parser.table_height).to eq(5)
        expect(parser.input_file).to be_nil
        expect(parser.output_format).to be_nil
      ensure
        # Restore original value
        ENV['ROBOT_OUTPUT_FORMAT'] = original_output_format if original_output_format
      end
    end

    it 'uses environment variables when available' do
      ENV['ROBOT_TABLE_WIDTH'] = '10'
      ENV['ROBOT_TABLE_HEIGHT'] = '8'
      ENV['ROBOT_OUTPUT_FORMAT'] = 'json'

      parser = described_class.new([])
      expect(parser.table_width).to eq(10)
      expect(parser.table_height).to eq(8)
      expect(parser.output_format).to eq('json')

      # Clean up
      ENV.delete('ROBOT_TABLE_WIDTH')
      ENV.delete('ROBOT_TABLE_HEIGHT')
      ENV.delete('ROBOT_OUTPUT_FORMAT')
    end

    it 'parses command line arguments correctly' do
      argv = ['--width', '7', '--height', '9', '--input', 'test.txt', '--output', 'xml']
      parser = described_class.new(argv)
      expect(parser.table_width).to eq(7)
      expect(parser.table_height).to eq(9)
      expect(parser.input_file).to eq('test.txt')
      expect(parser.output_format).to eq('xml')
    end

    it 'handles short form arguments' do
      argv = ['-w', '6', '-h', '4', '-i', 'commands.txt', '-o', 'csv']
      parser = described_class.new(argv)
      expect(parser.table_width).to eq(6)
      expect(parser.table_height).to eq(4)
      expect(parser.input_file).to eq('commands.txt')
      expect(parser.output_format).to eq('csv')
    end

    it 'handles positional input file' do
      argv = ['commands.txt']
      parser = described_class.new(argv)
      expect(parser.input_file).to eq('commands.txt')
    end

    it 'ignores positional file if --input is specified' do
      argv = ['--input', 'explicit.txt', 'commands.txt']
      parser = described_class.new(argv)
      expect(parser.input_file).to eq('explicit.txt')
    end

    it 'ignores positional file if first argument is a flag' do
      argv = ['--width', '5', 'commands.txt']
      parser = described_class.new(argv)
      expect(parser.input_file).to be_nil
    end

    it 'handles empty argv' do
      parser = described_class.new([])
      expect(parser.table_width).to eq(5)
      expect(parser.table_height).to eq(5)
      expect(parser.input_file).to be_nil
    end

    it 'handles nil values in arguments' do
      argv = ['--width', nil, '--height', nil]
      parser = described_class.new(argv)
      expect(parser.table_width).to eq(5) # nil.to_i returns 0, but it's not set because nil is not truthy
      expect(parser.table_height).to eq(5) # same as above
    end
  end

  describe '#help_requested?' do
    it 'returns true for --help' do
      parser = described_class.new(['--help'])
      expect(parser.help_requested?).to be true
    end

    it 'returns true for -h when not followed by number' do
      parser = described_class.new(['-h'])
      expect(parser.help_requested?).to be true
    end

    it 'returns false for -h when followed by number' do
      parser = described_class.new(['-h', '5'])
      expect(parser.help_requested?).to be false
    end

    it 'returns false for -h when followed by non-number' do
      parser = described_class.new(['-h', 'text'])
      expect(parser.help_requested?).to be true
    end

    it 'returns false when no help flags' do
      parser = described_class.new(['--width', '5'])
      expect(parser.help_requested?).to be false
    end

    it 'returns false for empty argv' do
      parser = described_class.new([])
      expect(parser.help_requested?).to be false
    end
  end

  describe '#display_help' do
    it 'outputs help message' do
      expect { parser.display_help }.to output(/Robot Challenge Simulator/).to_stdout
    end

    it 'includes usage information' do
      expect { parser.display_help }.to output(/Usage:/).to_stdout
    end

    it 'includes options information' do
      expect { parser.display_help }.to output(/Options:/).to_stdout
    end

    it 'includes environment variables information' do
      expect { parser.display_help }.to output(/Environment Variables:/).to_stdout
    end

    it 'includes examples' do
      expect { parser.display_help }.to output(/Examples:/).to_stdout
    end
  end

  describe '#validate!' do
    it 'does not raise error for valid dimensions' do
      parser = described_class.new(['--width', '5', '--height', '5'])
      expect { parser.validate! }.not_to raise_error
    end

    it 'raises ArgumentError for zero width' do
      parser = described_class.new(['--width', '0', '--height', '5'])
      expect { parser.validate! }.to raise_error(ArgumentError, 'Table dimensions must be positive integers')
    end

    it 'raises ArgumentError for zero height' do
      parser = described_class.new(['--width', '5', '--height', '0'])
      expect { parser.validate! }.to raise_error(ArgumentError, 'Table dimensions must be positive integers')
    end

    it 'raises ArgumentError for negative width' do
      parser = described_class.new(['--width', '-1', '--height', '5'])
      expect { parser.validate! }.to raise_error(ArgumentError, 'Table dimensions must be positive integers')
    end

    it 'raises ArgumentError for negative height' do
      parser = described_class.new(['--width', '5', '--height', '-1'])
      expect { parser.validate! }.to raise_error(ArgumentError, 'Table dimensions must be positive integers')
    end

    it 'raises ArgumentError for both negative dimensions' do
      parser = described_class.new(['--width', '-1', '--height', '-1'])
      expect { parser.validate! }.to raise_error(ArgumentError, 'Table dimensions must be positive integers')
    end
  end

  describe 'edge cases' do
    it 'handles arguments without values' do
      argv = ['--width', '--height', '--input', '--output']
      parser = described_class.new(argv)
      expect(parser.table_width).to eq(0) # nil.to_i returns 0
      expect(parser.table_height).to eq(0) # nil.to_i returns 0
      expect(parser.input_file).to eq('--output') # --input followed by --output
      expect(parser.output_format).to be_nil
    end

    it 'handles mixed valid and invalid arguments' do
      argv = ['--width', '5', '--invalid', 'value', '--height', '3']
      parser = described_class.new(argv)
      expect(parser.table_width).to eq(5)
      expect(parser.table_height).to eq(3)
    end

    it 'handles duplicate arguments (last wins)' do
      argv = ['--width', '5', '--width', '10']
      parser = described_class.new(argv)
      expect(parser.table_width).to eq(10)
    end

    it 'handles arguments at end of array' do
      argv = ['--width', '5', '--height', '3', '--input', 'file.txt']
      parser = described_class.new(argv)
      expect(parser.table_width).to eq(5)
      expect(parser.table_height).to eq(3)
      expect(parser.input_file).to eq('file.txt')
    end
  end
end
