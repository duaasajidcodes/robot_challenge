# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RobotChallenge::Application do
  let(:input) { StringIO.new }
  let(:output) { StringIO.new }
  let(:app) { described_class.new(input_source: input, output_destination: output) }

  describe '#initialize' do
    it 'creates application with default table size' do
      expect(app.robot.table.width).to eq(5)
      expect(app.robot.table.height).to eq(5)
    end

    it 'creates application with custom table size' do
      custom_app = described_class.new(table_width: 10, table_height: 8)
      expect(custom_app.robot.table.width).to eq(10)
      expect(custom_app.robot.table.height).to eq(8)
    end
  end

  describe '#process_command' do
    it 'processes single command' do
      expect(app.process_command('PLACE 1,1,NORTH')).to be false
    end
  end

  describe '#process_commands' do
    it 'processes multiple commands' do
      commands = ['PLACE 0,0,NORTH', 'MOVE', 'REPORT']
      app.process_commands(commands)

      expect(output.string).to include('0,1,NORTH')
    end
  end

  describe '#register_command' do
    let(:custom_command) { Class.new(RobotChallenge::Commands::Command) }

    it 'registers new command type' do
      initial_count = app.available_commands.length
      app.register_command('CUSTOM', custom_command)

      expect(app.available_commands.length).to eq(initial_count + 1)
      expect(app.available_commands).to include('CUSTOM')
    end
  end

  describe '#available_commands' do
    it 'returns list of available commands' do
      commands = app.available_commands
      expect(commands).to include('PLACE', 'MOVE', 'LEFT', 'RIGHT', 'REPORT')
    end
  end

  describe 'batch mode processing' do
    it 'processes commands from input source' do
      input.string = "PLACE 1,2,EAST\nMOVE\nREPORT\n"
      input.rewind

      allow(input).to receive(:tty?).and_return(false)

      app.run

      expect(output.string).to include('2,2,EAST')
    end
  end

  describe 'extensibility integration' do
    it 'seamlessly integrates custom commands' do
      # Create custom command
      greeting_command = Class.new(RobotChallenge::Commands::Command) do
        def execute(robot)
          message = robot.placed? ? 'Hello from robot!' : 'Robot says: Place me first!'
          output_result(message)
        end
      end

      # Register and use
      app.register_command('GREET', greeting_command)
      app.processor.command_factory.register_parser(RobotChallenge::Commands::SimpleCommandParser.new('GREET'))

      app.process_command('GREET')
      app.process_command('PLACE 1,1,NORTH')
      app.process_command('GREET')

      output_lines = output.string.split("\n")
      expect(output_lines).to include('Robot says: Place me first!')
      expect(output_lines).to include('Hello from robot!')
    end
  end
end
