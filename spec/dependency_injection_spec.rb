# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RobotChallenge::DependencyContainer do
  include TestHelpers

  describe 'Interface Compliance' do
    it 'Robot implements RobotOperations interface' do
      robot = create_test_robot
      expect(robot).to be_a(RobotChallenge::RobotOperations)
    end

    it 'Table implements TableOperations interface' do
      table = RobotChallenge::Table.new(5, 5)
      expect(table).to be_a(RobotChallenge::TableOperations)
    end

    it 'CommandParserService implements CommandParser interface' do
      parser = RobotChallenge::CommandParserService.new
      expect(parser).to be_a(RobotChallenge::CommandParser)
    end

    it 'CommandDispatcher implements CommandDispatcherInterface' do
      robot = create_test_robot
      dispatcher = RobotChallenge::CommandDispatcher.new(robot)
      expect(dispatcher).to be_a(RobotChallenge::CommandDispatcherInterface)
    end

    it 'SimpleLogger implements Logger interface' do
      logger = RobotChallenge::SimpleLogger.new
      expect(logger).to be_a(RobotChallenge::Logger)
    end
  end

  describe 'Dependency Container' do
    let(:container) { described_class.new }

    it 'registers and resolves dependencies' do
      mock_logger = double('MockLogger')
      container.register(:logger, mock_logger)
      expect(container.resolve(:logger)).to eq(mock_logger)
    end

    it 'uses factories to create dependencies' do
      logger = container.resolve(:logger)
      expect(logger).to be_a(RobotChallenge::Logger)
    end
  end

  describe 'Mock Dependencies for Testing' do
    it 'allows mocking robot operations' do
      mock_robot = double('MockRobot')
      allow(mock_robot).to receive_messages(place: mock_robot, placed?: true, move: mock_robot, turn_left: mock_robot,
                                            turn_right: mock_robot, report: '1,2,NORTH')

      processor = create_test_processor(mock_robot)
      expect { processor.process_command_string('PLACE 1,2,NORTH') }.not_to raise_error
    end

    it 'allows mocking command parser' do
      mock_parser = double('MockParser')
      mock_command = double('MockCommand')
      allow(mock_parser).to receive_messages(parse: mock_command, available_commands: ['MOVE'])
      allow(mock_parser).to receive(:register_command)
      allow(mock_command).to receive(:execute).and_return({ status: :success })

      robot = create_test_robot
      processor = RobotChallenge::CommandProcessor.new(robot, parser: mock_parser)
      expect { processor.process_command_string('MOVE') }.not_to raise_error
    end

    it 'allows mocking command dispatcher' do
      mock_dispatcher = double('MockDispatcher')
      allow(mock_dispatcher).to receive(:dispatch)
      allow(mock_dispatcher).to receive(:dispatch_commands)

      robot = create_test_robot
      processor = RobotChallenge::CommandProcessor.new(robot, dispatcher: mock_dispatcher)
      expect(processor.dispatcher).to eq(mock_dispatcher)
    end

    it 'allows mocking logger' do
      mock_logger = double('MockLogger')
      allow(mock_logger).to receive(:debug)
      allow(mock_logger).to receive(:info)
      allow(mock_logger).to receive(:warn)
      allow(mock_logger).to receive(:error)

      robot = create_test_robot
      processor = RobotChallenge::CommandProcessor.new(robot, logger: mock_logger)
      expect(processor.instance_variable_get(:@logger)).to eq(mock_logger)
    end
  end

  describe 'Application with Injected Dependencies' do
    it 'accepts custom robot implementation' do
      custom_robot = create_test_robot
      app = RobotChallenge::Application.new(robot: custom_robot)
      expect(app.robot).to eq(custom_robot)
    end

    it 'accepts custom table implementation' do
      custom_table = RobotChallenge::Table.new(5, 5)
      app = RobotChallenge::Application.new(table: custom_table)
      expect(app.instance_variable_get(:@table)).to eq(custom_table)
    end

    it 'accepts custom logger implementation' do
      custom_logger = RobotChallenge::NullLogger.new
      app = RobotChallenge::Application.new(logger: custom_logger)
      expect(app.instance_variable_get(:@logger)).to eq(custom_logger)
    end

    it 'accepts custom command parser' do
      mock_parser = double('MockParser')
      allow(mock_parser).to receive_messages(parse: nil, available_commands: [])
      allow(mock_parser).to receive(:register_command)

      app = RobotChallenge::Application.new(command_parser: mock_parser)
      expect(app.processor.parser).to eq(mock_parser)
    end

    it 'accepts custom command dispatcher' do
      mock_dispatcher = double('MockDispatcher')
      allow(mock_dispatcher).to receive(:dispatch)
      allow(mock_dispatcher).to receive(:dispatch_commands)

      app = RobotChallenge::Application.new(command_dispatcher: mock_dispatcher)
      expect(app.processor.dispatcher).to eq(mock_dispatcher)
    end
  end

  describe 'Logger Implementations' do
    it 'SimpleLogger logs messages with timestamps' do
      output = StringIO.new
      logger = RobotChallenge::SimpleLogger.new(output, level: :debug)

      logger.info('Test message')
      output.rewind
      log_line = output.read

      expect(log_line).to match(/\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\] INFO: Test message/)
    end

    it 'NullLogger ignores all messages' do
      logger = RobotChallenge::NullLogger.new
      expect { logger.info('message') }.not_to raise_error
      expect { logger.error('error') }.not_to raise_error
    end

    it 'LoggerFactory creates appropriate logger based on environment' do
      # Test environment should create NullLogger
      ENV['ROBOT_ENV'] = 'test'
      ENV['ROBOT_LOGGER'] = 'null'
      logger = RobotChallenge::LoggerFactory.from_environment
      expect(logger).to be_a(RobotChallenge::NullLogger)

      # Clean up
      ENV.delete('ROBOT_ENV')
      ENV.delete('ROBOT_LOGGER')
    end
  end

  describe 'Integration with Dependency Container' do
    it 'allows overriding specific dependencies' do
      custom_logger = RobotChallenge::NullLogger.new
      app = RobotChallenge::Application.new(logger: custom_logger)
      expect(app.instance_variable_get(:@logger)).to eq(custom_logger)
    end
  end
end
