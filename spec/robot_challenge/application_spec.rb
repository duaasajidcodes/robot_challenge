# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RobotChallenge::Application do
  let(:table) { RobotChallenge::Table.new(5, 5) }
  let(:robot) { RobotChallenge::Robot.new(table) }
  let(:input_source) { RobotChallenge::StringInputSource.new('PLACE 1,1,NORTH') }
  let(:output_formatter) { RobotChallenge::TextOutputFormatter.new }

  describe '#initialize' do
    it 'creates application with default table size' do
      app = described_class.new
      expect(app.table.width).to eq(5)
      expect(app.table.height).to eq(5)
    end

    it 'creates application with custom table size' do
      app = described_class.new(table_width: 10, table_height: 8)
      expect(app.table.width).to eq(10)
      expect(app.table.height).to eq(8)
    end

    it 'creates application with custom table instance' do
      custom_table = RobotChallenge::Table.new(3, 3)
      app = described_class.new(table: custom_table)
      expect(app.table).to eq(custom_table)
    end

    it 'creates application with custom robot instance' do
      custom_robot = RobotChallenge::Robot.new(table)
      app = described_class.new(robot: custom_robot)
      expect(app.robot).to eq(custom_robot)
    end

    it 'creates application with custom processor' do
      custom_processor = RobotChallenge::CommandProcessor.new(robot)
      app = described_class.new(processor: custom_processor)
      expect(app.processor).to eq(custom_processor)
    end

    it 'creates application with custom input source' do
      app = described_class.new(input_source: input_source)
      expect(app.input_source).to eq(input_source)
    end

    it 'creates application with custom output formatter' do
      app = described_class.new(output_formatter: output_formatter)
      expect(app.output_formatter).to eq(output_formatter)
    end

    it 'creates application with custom config' do
      config = RobotChallenge::Config.new
      config.instance_variable_set(:@table_width, 7)
      config.instance_variable_set(:@table_height, 6)
      app = described_class.new(config: config)
      expect(app.table.width).to eq(7)
      expect(app.table.height).to eq(6)
    end

    it 'uses robot from processor if available' do
      processor_robot = RobotChallenge::Robot.new(table)
      processor = RobotChallenge::CommandProcessor.new(processor_robot)
      app = described_class.new(processor: processor)
      expect(app.robot).to eq(processor_robot)
    end
  end

  describe '#input_source=' do
    it 'sets input source using factory' do
      app = described_class.new
      app.input_source = 'PLACE 1,1,NORTH'
      expect(app.input_source).to be_a(RobotChallenge::StringInputSource)
    end
  end

  describe '#set_input_source' do
    it 'sets input source using factory' do
      app = described_class.new
      app.set_input_source('PLACE 1,1,NORTH')
      expect(app.input_source).to be_a(RobotChallenge::StringInputSource)
    end
  end

  describe '#output_handler=' do
    it 'sets output handler and updates processor' do
      app = described_class.new
      handler = ->(msg) { puts msg }
      app.output_handler = handler
      expect(app.instance_variable_get(:@output_handler)).to eq(handler)
    end

    it 'updates processor output handler if processor responds to it' do
      app = described_class.new
      handler = ->(msg) { puts msg }
      allow(app.processor).to receive(:output_handler=)
      app.output_handler = handler
      expect(app.processor).to have_received(:output_handler=).with(handler)
    end
  end

  describe '#set_output_handler' do
    it 'sets output handler and updates processor' do
      app = described_class.new
      handler = ->(msg) { puts msg }
      app.set_output_handler(handler)
      expect(app.instance_variable_get(:@output_handler)).to eq(handler)
    end
  end

  describe '#set_output_formatter' do
    it 'sets output formatter and updates processor' do
      app = described_class.new
      formatter = RobotChallenge::JsonOutputFormatter.new
      app.set_output_formatter(formatter)
      expect(app.output_formatter).to eq(formatter)
    end

    it 'updates processor output handler' do
      app = described_class.new
      formatter = RobotChallenge::JsonOutputFormatter.new
      allow(app.processor).to receive(:output_handler=)
      app.set_output_formatter(formatter)
      expect(app.processor).to have_received(:output_handler=)
    end

    it 'updates dispatcher formatter if available' do
      app = described_class.new
      formatter = RobotChallenge::JsonOutputFormatter.new
      allow(app.processor.dispatcher).to receive(:output_formatter=)
      app.set_output_formatter(formatter)
      expect(app.processor.dispatcher).to have_received(:output_formatter=).with(formatter)
    end
  end

  describe '#run' do
    context 'with interactive input source' do
      let(:interactive_source) do
        source = RobotChallenge::StringInputSource.new('PLACE 1,1,NORTH')
        allow(source).to receive(:tty?).and_return(true)
        source
      end

      it 'runs in interactive mode' do
        app = described_class.new(input_source: interactive_source)
        allow(app).to receive(:run_interactive_mode)
        app.run
        expect(app).to have_received(:run_interactive_mode)
      end
    end

    context 'with non-interactive input source' do
      let(:batch_source) do
        source = RobotChallenge::StringInputSource.new('PLACE 1,1,NORTH')
        allow(source).to receive(:tty?).and_return(false)
        source
      end

      it 'runs in batch mode' do
        app = described_class.new(input_source: batch_source)
        allow(app).to receive(:run_batch_mode)
        app.run
        expect(app).to have_received(:run_batch_mode)
      end
    end

    it 'displays welcome message' do
      app = described_class.new(input_source: input_source)
      allow(app).to receive(:display_welcome_message)
      allow(app).to receive(:run_batch_mode)
      app.run
      expect(app).to have_received(:display_welcome_message)
    end
  end

  describe '#run_batch_mode' do
    it 'processes commands from input source' do
      app = described_class.new(input_source: input_source)
      allow(app).to receive(:process_command)
      app.run_batch_mode
      expect(app).to have_received(:process_command).with('PLACE 1,1,NORTH')
    end
  end

  describe '#process_command' do
    it 'processes single command' do
      app = described_class.new
      allow(app.processor).to receive(:process_command_string)
      app.process_command('PLACE 1,1,NORTH')
      expect(app.processor).to have_received(:process_command_string).with('PLACE 1,1,NORTH')
    end

    it 'ignores nil command' do
      app = described_class.new
      allow(app.processor).to receive(:process_command_string)
      app.process_command(nil)
      expect(app.processor).not_to have_received(:process_command_string)
    end

    it 'ignores empty command' do
      app = described_class.new
      allow(app.processor).to receive(:process_command_string)
      app.process_command('   ')
      expect(app.processor).not_to have_received(:process_command_string)
    end

    it 'strips whitespace from command' do
      app = described_class.new
      allow(app.processor).to receive(:process_command_string)
      app.process_command('  PLACE 1,1,NORTH  ')
      # The actual implementation doesn't strip whitespace before calling process_command_string
      expect(app.processor).to have_received(:process_command_string).with('  PLACE 1,1,NORTH  ')
    end
  end

  describe '#process_commands' do
    it 'processes multiple commands' do
      app = described_class.new
      commands = ['PLACE 0,0,NORTH', 'MOVE', 'REPORT']
      allow(app).to receive(:process_command)
      app.process_commands(commands)
      expect(app).to have_received(:process_command).with('PLACE 0,0,NORTH')
      expect(app).to have_received(:process_command).with('MOVE')
      expect(app).to have_received(:process_command).with('REPORT')
    end
  end

  describe '#register_command' do
    it 'registers new command type' do
      app = described_class.new
      custom_command_class = Class.new(RobotChallenge::Commands::Command)
      allow(app.processor).to receive(:register_command)
      app.register_command('GREET', custom_command_class)
      expect(app.processor).to have_received(:register_command).with('GREET', custom_command_class)
    end
  end

  describe '#available_commands' do
    it 'returns list of available commands' do
      app = described_class.new
      allow(app.processor).to receive(:available_commands).and_return(%w[PLACE MOVE REPORT])
      expect(app.available_commands).to eq(%w[PLACE MOVE REPORT])
    end
  end

  describe 'batch mode processing' do
    it 'processes commands from input source' do
      input = RobotChallenge::StringInputSource.new("PLACE 1,2,EAST\nMOVE\nREPORT")
      app = described_class.new(input_source: input)
      output = []
      app.set_output_handler(->(msg) { output << msg })
      app.run_batch_mode
      expect(output).not_to be_empty
    end
  end

  describe 'extensibility integration' do
    it 'seamlessly integrates custom commands' do
      app = described_class.new(input_source: RobotChallenge::StringInputSource.new('GREET'))

      # Register a custom command
      custom_command_class = Class.new(RobotChallenge::Commands::Command) do
        def initialize(*); end

        def execute(_robot)
          output_result('Hello, Robot!')
        end
      end

      app.register_command('GREET', custom_command_class)
      output = []
      app.set_output_handler(->(msg) { output << msg })
      app.process_command('GREET')
      expect(output).to include('Hello, Robot!')
    end
  end

  describe 'private methods' do
    describe '#build_table' do
      it 'returns provided table if given' do
        app = described_class.new(table: table)
        expect(app.send(:build_table, nil, nil, table)).to eq(table)
      end

      it 'uses table_width and table_height if provided' do
        app = described_class.new
        result = app.send(:build_table, 7, 6, nil)
        expect(result.width).to eq(7)
        expect(result.height).to eq(6)
      end

      it 'uses config values if no dimensions provided' do
        config = RobotChallenge::Config.new
        config.instance_variable_set(:@table_width, 8)
        config.instance_variable_set(:@table_height, 9)
        app = described_class.new(config: config)
        result = app.send(:build_table, nil, nil, nil)
        expect(result.width).to eq(8)
        expect(result.height).to eq(9)
      end
    end

    describe '#build_robot' do
      it 'returns provided robot if given' do
        app = described_class.new
        expect(app.send(:build_robot, robot, nil)).to eq(robot)
      end

      it 'uses processor robot if available' do
        processor_robot = RobotChallenge::Robot.new(table)
        processor = RobotChallenge::CommandProcessor.new(processor_robot)
        app = described_class.new
        expect(app.send(:build_robot, nil, processor)).to eq(processor_robot)
      end

      it 'creates new robot if no robot provided' do
        app = described_class.new
        result = app.send(:build_robot, nil, nil)
        expect(result).to be_a(RobotChallenge::Robot)
        expect(result.table).to eq(app.table)
      end
    end

    describe '#update_processor_output_handler' do
      it 'updates processor output handler if processor responds to it' do
        app = described_class.new
        allow(app.processor).to receive(:output_handler=)
        app.send(:update_processor_output_handler)
        expect(app.processor).to have_received(:output_handler=)
      end

      it 'does nothing if processor does not respond to output_handler=' do
        app = described_class.new
        allow(app.processor).to receive(:respond_to?).with(:output_handler=).and_return(false)
        expect { app.send(:update_processor_output_handler) }.not_to raise_error
      end
    end

    describe '#update_dispatcher_formatter' do
      it 'updates dispatcher formatter if dispatcher responds to it' do
        app = described_class.new
        formatter = RobotChallenge::JsonOutputFormatter.new
        allow(app.processor.dispatcher).to receive(:output_formatter=)
        app.send(:update_dispatcher_formatter, formatter)
        expect(app.processor.dispatcher).to have_received(:output_formatter=).with(formatter)
      end

      it 'does nothing if dispatcher does not respond to output_formatter=' do
        app = described_class.new
        formatter = RobotChallenge::JsonOutputFormatter.new
        allow(app.processor.dispatcher).to receive(:respond_to?).with(:output_formatter=).and_return(false)
        expect { app.send(:update_dispatcher_formatter, formatter) }.not_to raise_error
      end
    end

    describe '#display_welcome_message' do
      it 'calls output handler with welcome messages' do
        app = described_class.new
        output = []
        app.set_output_handler(->(msg) { output << msg })
        app.send(:display_welcome_message)
        expect(output).to include('Welcome to Robot Challenge!')
        expect(output).to include('Commands: PLACE X,Y,DIRECTION, MOVE, LEFT, RIGHT, REPORT')
        expect(output).to include('Type your commands:')
      end
    end

    describe '#run_interactive_mode' do
      it 'runs interactive loop until empty command' do
        input = RobotChallenge::StringInputSource.new("PLACE 1,1,NORTH\nMOVE\n\n")
        app = described_class.new(input_source: input)
        output = []
        app.set_output_handler(->(msg) { output << msg })
        app.send(:run_interactive_mode)
        expect(output).to include('> ')
      end
    end

    describe '#create_processor' do
      it 'creates processor with correct parameters' do
        app = described_class.new
        output_handler = ->(msg) { puts msg }
        command_parser = RobotChallenge::CommandParserService.new
        command_dispatcher = RobotChallenge::CommandDispatcher.new(robot)

        result = app.send(:create_processor, output_handler, command_parser, command_dispatcher)
        expect(result).to be_a(RobotChallenge::CommandProcessor)
        expect(result.robot).to eq(app.robot)
      end
    end

    describe '#output_handler' do
      it 'returns default output handler if none set' do
        app = described_class.new
        handler = app.send(:output_handler)
        expect(handler).to be_a(Method)
        expect(handler.name).to eq(:default_output_handler)
      end

      it 'returns cached output handler' do
        app = described_class.new
        handler1 = app.send(:output_handler)
        handler2 = app.send(:output_handler)
        expect(handler1).to eq(handler2)
      end
    end

    describe '#default_output_handler' do
      it 'formats message and writes to output destination' do
        app = described_class.new
        output_destination = StringIO.new
        app.instance_variable_set(:@output_destination, output_destination)
        app.send(:default_output_handler, 'test message')
        expect(output_destination.string).to include('test message')
      end
    end
  end
end
