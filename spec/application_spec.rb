# frozen_string_literal: true

require 'spec_helper'
require 'stringio'

RSpec.describe RobotChallenge::Application do
  let(:input) { StringIO.new }
  let(:output) { StringIO.new }
  let(:app) { described_class.new(input_source: input, output_destination: output) }

  describe '#initialize' do
    it 'creates application with default table dimensions' do
      default_app = described_class.new
      expect(default_app.robot.table.width).to eq(5)
      expect(default_app.robot.table.height).to eq(5)
    end

    it 'creates application with custom table dimensions' do
      custom_app = described_class.new(table_width: 10, table_height: 8)
      expect(custom_app.robot.table.width).to eq(10)
      expect(custom_app.robot.table.height).to eq(8)
    end

    it 'sets up input and output sources' do
      expect(app.input_source).to eq(input)
      expect(app.output_destination).to eq(output)
    end

    it 'initializes with unplaced robot' do
      expect(app.robot).not_to be_placed
    end
  end

  describe '#process_command' do
    it 'processes single command string' do
      result = app.process_command('PLACE 1,1,NORTH')
      expect(result).to be false
      expect(app.robot).to be_placed
    end

    it 'returns true for exit commands' do
      result = app.process_command('EXIT')
      expect(result).to be true
    end

    it 'handles invalid commands gracefully' do
      result = app.process_command('INVALID')
      expect(result).to be false
    end
  end

  describe '#process_commands' do
    it 'processes array of command strings' do
      commands = [
        'PLACE 0,0,NORTH',
        'MOVE',
        'REPORT'
      ]

      app.process_commands(commands)

      expect(output.string).to include('0,1,NORTH')
    end

    it 'stops on exit command' do
      commands = [
        'PLACE 0,0,NORTH',
        'EXIT',
        'REPORT'
      ]

      app.process_commands(commands)

      expect(output.string).not_to include('0,0,NORTH')
    end
  end

  describe '#run' do
    context 'batch mode (non-TTY input)' do
      before do
        allow(input).to receive(:tty?).and_return(false)
      end

      it 'processes all commands from input' do
        input.string = "PLACE 0,0,NORTH\nMOVE\nREPORT\n"
        input.rewind

        app.run

        expect(output.string).to include('0,1,NORTH')
        expect(output.string).not_to include('Interactive mode')
      end

      it 'handles empty input' do
        input.string = ''
        input.rewind

        expect { app.run }.not_to raise_error
      end

      it 'stops on EXIT command' do
        input.string = "PLACE 0,0,NORTH\nEXIT\nREPORT\n"
        input.rewind

        app.run

        expect(output.string).not_to include('0,0,NORTH')
      end

      it 'processes example 1 correctly' do
        input.string = "PLACE 0,0,NORTH\nMOVE\nREPORT\n"
        input.rewind

        app.run

        expect(output.string).to include('0,1,NORTH')
      end

      it 'processes example 2 correctly' do
        input.string = "PLACE 0,0,NORTH\nLEFT\nREPORT\n"
        input.rewind

        app.run

        expect(output.string).to include('0,0,WEST')
      end

      it 'processes example 3 correctly' do
        input.string = "PLACE 1,2,EAST\nMOVE\nMOVE\nLEFT\nMOVE\nREPORT\n"
        input.rewind

        app.run

        expect(output.string).to include('3,3,NORTH')
      end

      it 'ignores invalid commands' do
        input.string = "INVALID\nPLACE 1,1,NORTH\nREPORT\n"
        input.rewind

        app.run

        expect(output.string).to include('1,1,NORTH')
      end

      it 'handles commands before first PLACE' do
        input.string = "MOVE\nLEFT\nREPORT\nPLACE 2,2,SOUTH\nREPORT\n"
        input.rewind

        app.run

        output_lines = output.string.lines.map(&:strip).reject(&:empty?)
        expect(output_lines).to eq(['2,2,SOUTH'])
      end
    end

    context 'interactive mode (TTY input)' do
      before do
        allow(input).to receive(:tty?).and_return(true)
      end

      it 'displays welcome message' do
        input.string = "EXIT\n"
        input.rewind

        app.run

        expect(output.string).to include('Robot Challenge Simulator')
        expect(output.string).to include('Commands:')
        expect(output.string).to include('PLACE X,Y,F')
      end

      it 'displays prompts and processes commands' do
        input.string = "PLACE 1,1,NORTH\nREPORT\nEXIT\n"
        input.rewind

        app.run

        expect(output.string).to include('>')
        expect(output.string).to include('1,1,NORTH')
        expect(output.string).to include('Goodbye!')
      end

      it 'handles QUIT command' do
        input.string = "PLACE 0,0,NORTH\nQUIT\n"
        input.rewind

        app.run

        expect(output.string).to include('Goodbye!')
      end
    end

    context 'error handling' do
      it 'handles interrupt gracefully' do
        allow(input).to receive(:each_line).and_raise(Interrupt)

        expect { app.run }.not_to raise_error
        expect(output.string).to include('Goodbye!')
      end

      it 'handles standard errors' do
        allow(input).to receive(:each_line).and_raise(StandardError.new('Test error'))

        expect { app.run }.to raise_error(SystemExit)
        expect(output.string).to include('An error occurred: Test error')
      end
    end
  end

  describe 'integration with test data files' do
    context 'with example test files' do
      it 'processes example_1.txt correctly' do
        allow(input).to receive(:tty?).and_return(false)
        input.string = File.read('/Users/duaasajid/Desktop/robot_challenge/test_data/example_1.txt')
        input.rewind

        app.run

        expect(output.string.strip).to eq('0,1,NORTH')
      end

      it 'processes example_2.txt correctly' do
        allow(input).to receive(:tty?).and_return(false)
        input.string = File.read('/Users/duaasajid/Desktop/robot_challenge/test_data/example_2.txt')
        input.rewind

        app.run

        expect(output.string.strip).to eq('0,0,WEST')
      end

      it 'processes example_3.txt correctly' do
        allow(input).to receive(:tty?).and_return(false)
        input.string = File.read('/Users/duaasajid/Desktop/robot_challenge/test_data/example_3.txt')
        input.rewind

        app.run

        expect(output.string.strip).to eq('3,3,NORTH')
      end
    end
  end

  describe 'custom table dimensions' do
    let(:custom_app) do
      described_class.new(
        table_width: 3,
        table_height: 3,
        input_source: input,
        output_destination: output
      )
    end

    it 'respects custom table boundaries' do
      allow(input).to receive(:tty?).and_return(false)
      input.string = "PLACE 2,2,NORTH\nMOVE\nREPORT\n"
      input.rewind

      custom_app.run

      expect(output.string.strip).to eq('2,2,NORTH') # Can't move beyond boundary
    end

    it 'prevents placement outside custom boundaries' do
      allow(input).to receive(:tty?).and_return(false)
      input.string = "PLACE 5,5,NORTH\nREPORT\nPLACE 1,1,NORTH\nREPORT\n"
      input.rewind

      custom_app.run

      expect(output.string.strip).to eq('1,1,NORTH')
    end
  end

  describe 'edge cases and stress testing' do
    it 'handles very long command sequences' do
      allow(input).to receive(:tty?).and_return(false)

      commands = ['PLACE 2,2,NORTH']
      1000.times { commands << 'LEFT' }
      commands << 'REPORT'

      input.string = "#{commands.join("\n")}\n"
      input.rewind

      app.run

      expect(output.string.strip).to eq('2,2,NORTH') # Full rotation
    end

    it 'handles malformed input robustly' do
      allow(input).to receive(:tty?).and_return(false)
      input.string = "PLACE\n\n  \nPLACE 1,1,NORTH\nREPORT\n"
      input.rewind

      app.run

      expect(output.string.strip).to eq('1,1,NORTH')
    end

    it 'handles mixed case and whitespace' do
      allow(input).to receive(:tty?).and_return(false)
      input.string = "  place   0,0,north  \n  MOVE  \n  report  \n"
      input.rewind

      app.run

      expect(output.string.strip).to eq('0,1,NORTH')
    end
  end
end
