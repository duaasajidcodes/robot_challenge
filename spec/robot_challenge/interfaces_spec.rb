# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RobotChallenge::CommandParser do
  describe 'CommandParser interface' do
    let(:parser_class) do
      Class.new do
        include RobotChallenge::CommandParser
      end
    end

    let(:parser) { parser_class.new }

    describe '#parse' do
      it 'raises NotImplementedError' do
        expect { parser.parse('PLACE 1,1,NORTH') }.to raise_error(
          NotImplementedError, "#{parser_class} must implement #parse"
        )
      end
    end

    describe '#parse_commands' do
      it 'raises NotImplementedError' do
        expect { parser.parse_commands(['PLACE 1,1,NORTH', 'MOVE']) }.to raise_error(
          NotImplementedError, "#{parser_class} must implement #parse_commands"
        )
      end
    end

    describe '#available_commands' do
      it 'raises NotImplementedError' do
        expect { parser.available_commands }.to raise_error(
          NotImplementedError, "#{parser_class} must implement #available_commands"
        )
      end
    end

    describe '#register_command' do
      it 'raises NotImplementedError' do
        expect { parser.register_command('TEST', Class.new) }.to raise_error(
          NotImplementedError, "#{parser_class} must implement #register_command"
        )
      end
    end
  end

  describe 'CommandDispatcherInterface' do
    let(:dispatcher_class) do
      Class.new do
        include RobotChallenge::CommandDispatcherInterface
      end
    end

    let(:dispatcher) { dispatcher_class.new }

    describe '#dispatch' do
      it 'raises NotImplementedError' do
        expect { dispatcher.dispatch('PLACE 1,1,NORTH') }.to raise_error(
          NotImplementedError, "#{dispatcher_class} must implement #dispatch"
        )
      end

      it 'raises NotImplementedError with block' do
        expect { dispatcher.dispatch('PLACE 1,1,NORTH') { |result| } }.to raise_error(
          NotImplementedError, "#{dispatcher_class} must implement #dispatch"
        )
      end
    end

    describe '#dispatch_commands' do
      it 'raises NotImplementedError' do
        expect { dispatcher.dispatch_commands(['PLACE 1,1,NORTH', 'MOVE']) }.to raise_error(
          NotImplementedError, "#{dispatcher_class} must implement #dispatch_commands"
        )
      end

      it 'raises NotImplementedError with block' do
        expect { dispatcher.dispatch_commands(['PLACE 1,1,NORTH', 'MOVE']) { |result| } }.to raise_error(
          NotImplementedError, "#{dispatcher_class} must implement #dispatch_commands"
        )
      end
    end
  end

  describe 'OutputHandler interface' do
    let(:handler_class) do
      Class.new do
        include RobotChallenge::OutputHandler
      end
    end

    let(:handler) { handler_class.new }

    describe '#call' do
      it 'raises NotImplementedError' do
        expect { handler.call('test message') }.to raise_error(
          NotImplementedError, "#{handler_class} must implement #call"
        )
      end
    end
  end

  describe 'RobotOperations interface' do
    let(:robot_class) do
      Class.new do
        include RobotChallenge::RobotOperations
      end
    end

    let(:robot) { robot_class.new }

    describe '#place' do
      it 'raises NotImplementedError' do
        position = RobotChallenge::Position.new(1, 1)
        direction = RobotChallenge::Direction.new('NORTH')
        expect { robot.place(position, direction) }.to raise_error(
          NotImplementedError, "#{robot_class} must implement #place"
        )
      end
    end

    describe '#move' do
      it 'raises NotImplementedError' do
        expect { robot.move }.to raise_error(
          NotImplementedError, "#{robot_class} must implement #move"
        )
      end
    end

    describe '#turn_left' do
      it 'raises NotImplementedError' do
        expect { robot.turn_left }.to raise_error(
          NotImplementedError, "#{robot_class} must implement #turn_left"
        )
      end
    end

    describe '#turn_right' do
      it 'raises NotImplementedError' do
        expect { robot.turn_right }.to raise_error(
          NotImplementedError, "#{robot_class} must implement #turn_right"
        )
      end
    end

    describe '#report' do
      it 'raises NotImplementedError' do
        expect { robot.report }.to raise_error(
          NotImplementedError, "#{robot_class} must implement #report"
        )
      end
    end

    describe '#placed?' do
      it 'raises NotImplementedError' do
        expect { robot.placed? }.to raise_error(
          NotImplementedError, "#{robot_class} must implement #placed?"
        )
      end
    end
  end

  describe 'TableOperations interface' do
    let(:table_class) do
      Class.new do
        include RobotChallenge::TableOperations
      end
    end

    let(:table) { table_class.new }

    describe '#valid_position?' do
      it 'raises NotImplementedError' do
        position = RobotChallenge::Position.new(1, 1)
        expect { table.valid_position?(position) }.to raise_error(
          NotImplementedError, "#{table_class} must implement #valid_position?"
        )
      end
    end

    describe '#width' do
      it 'raises NotImplementedError' do
        expect { table.width }.to raise_error(
          NotImplementedError, "#{table_class} must implement #width"
        )
      end
    end

    describe '#height' do
      it 'raises NotImplementedError' do
        expect { table.height }.to raise_error(
          NotImplementedError, "#{table_class} must implement #height"
        )
      end
    end
  end

  describe 'Logger interface' do
    let(:logger_class) do
      Class.new do
        include RobotChallenge::Logger
      end
    end

    let(:logger) { logger_class.new }

    describe '#info' do
      it 'raises NotImplementedError' do
        expect { logger.info('test message') }.to raise_error(
          NotImplementedError, "#{logger_class} must implement #info"
        )
      end
    end

    describe '#debug' do
      it 'raises NotImplementedError' do
        expect { logger.debug('test message') }.to raise_error(
          NotImplementedError, "#{logger_class} must implement #debug"
        )
      end
    end

    describe '#warn' do
      it 'raises NotImplementedError' do
        expect { logger.warn('test message') }.to raise_error(
          NotImplementedError, "#{logger_class} must implement #warn"
        )
      end
    end

    describe '#error' do
      it 'raises NotImplementedError' do
        expect { logger.error('test message') }.to raise_error(
          NotImplementedError, "#{logger_class} must implement #error"
        )
      end
    end
  end

  describe 'interface integration' do
    subject(:instance) { multi_interface_class.new }

    let(:multi_interface_class) do
      Class.new do
        include RobotChallenge::CommandParser
        include RobotChallenge::OutputHandler
        include RobotChallenge::Logger

        def parse(command_string)
          "parsed: #{command_string}"
        end

        def parse_commands(command_strings)
          command_strings.map { |cmd| parse(cmd) }
        end

        def available_commands
          %w[PLACE MOVE LEFT RIGHT REPORT]
        end

        def register_command(name, _command_class)
          "registered: #{name}"
        end

        def call(message)
          "handled: #{message}"
        end

        def info(message)
          "info: #{message}"
        end

        def debug(message)
          "debug: #{message}"
        end

        def warn(message)
          "warn: #{message}"
        end

        def error(message)
          "error: #{message}"
        end
      end
    end

    describe 'command parser interface' do
      it 'parses a single command' do
        expect(instance.parse('PLACE 1,1,NORTH')).to eq('parsed: PLACE 1,1,NORTH')
      end

      it 'parses multiple commands' do
        expect(instance.parse_commands(%w[MOVE LEFT])).to eq(['parsed: MOVE', 'parsed: LEFT'])
      end

      it 'returns available commands' do
        expect(instance.available_commands).to eq(%w[PLACE MOVE LEFT RIGHT REPORT])
      end

      it 'registers a command' do
        expect(instance.register_command('TEST', Class.new)).to eq('registered: TEST')
      end
    end

    describe 'output handler interface' do
      it 'handles messages' do
        expect(instance.call('test message')).to eq('handled: test message')
      end
    end

    describe 'logger interface' do
      it 'logs info' do
        expect(instance.info('foo')).to eq('info: foo')
      end

      it 'logs debug' do
        expect(instance.debug('bar')).to eq('debug: bar')
      end

      it 'logs warnings' do
        expect(instance.warn('baz')).to eq('warn: baz')
      end

      it 'logs errors' do
        expect(instance.error('oops')).to eq('error: oops')
      end
    end
  end
end
