# frozen_string_literal: true

# Common test helpers to reduce repetition (DRY principle)
module TestHelpers
  # Common test data
  module TestData
    VALID_COMMANDS = [
      'PLACE 0,0,NORTH',
      'MOVE',
      'LEFT',
      'RIGHT',
      'REPORT'
    ].freeze

    INVALID_COMMANDS = [
      'INVALID',
      'PLACE invalid',
      'PLACE 0,0,INVALID',
      '',
      '   ',
      nil
    ].freeze

    MIXED_COMMANDS = [
      'PLACE 0,0,NORTH',
      'MOVE',
      'INVALID',
      'LEFT',
      'REPORT'
    ].freeze

    # Common test scenarios
    SCENARIOS = {
      basic_movement: ['PLACE 0,0,NORTH', 'MOVE', 'REPORT'],
      rotation: ['PLACE 0,0,NORTH', 'LEFT', 'REPORT'],
      boundary_test: ['PLACE 0,0,NORTH', 'MOVE', 'MOVE', 'MOVE', 'MOVE', 'MOVE', 'REPORT'],
      complex_sequence: ['PLACE 1,2,EAST', 'MOVE', 'MOVE', 'LEFT', 'MOVE', 'REPORT']
    }.freeze
  end

  # Common test assertions
  module Assertions
    def assert_robot_position(robot, expected_x, expected_y, expected_direction)
      expect(robot.position.x).to eq(expected_x)
      expect(robot.position.y).to eq(expected_y)
      expect(robot.direction.name).to eq(expected_direction)
    end

    def assert_output_contains(output, expected_content)
      expect(output).to include(expected_content)
    end

    def assert_no_output(output)
      expect(output).to be_empty
    end

    def assert_valid_json(output)
      expect { JSON.parse(output) }.not_to raise_error
    end

    def assert_valid_xml(output)
      expect(output).to include('<?xml version="1.0" encoding="UTF-8"?>')
    end

    def assert_valid_csv(output)
      expect(output).to include(',')
      expect(output).to include("\n")
    end
  end

  # Common test setup
  module Setup
    def create_test_robot_with_position(x, y, direction)
      robot = create_test_robot
      robot.place(RobotChallenge::Position.new(x, y), RobotChallenge::Direction.new(direction))
      robot
    end

    def create_test_application_with_config(config_overrides = {})
      test_config = RobotChallenge::Config.for_environment('test')
      config_overrides.each { |key, value| test_config.instance_variable_set("@#{key}", value) }
      RobotChallenge::Application.new(config: test_config)
    end

    def capture_output(app)
      output = []
      output_handler = ->(message) { output << message if message }
      app.set_output_handler(output_handler)
      yield
      output.join("\n")
    end

    def run_commands_and_capture_output(app, commands)
      capture_output(app) do
        app.process_commands(commands)
      end
    end
  end

  # Common test factories
  module Factories
    def create_formatter(format_type)
      RobotChallenge::OutputFormatterFactory.create(format_type)
    end

    def create_input_source(source_type, data = nil)
      case source_type
      when :file
        RobotChallenge::InputSourceFactory.from_file_path(data || 'test_data/example_1.txt')
      when :string
        RobotChallenge::InputSourceFactory.from_string(data || 'PLACE 0,0,NORTH')
      when :array
        RobotChallenge::InputSourceFactory.from_array(data || ['PLACE 0,0,NORTH', 'MOVE'])
      when :stdin
        RobotChallenge::InputSourceFactory.from_stdin
      else
        raise ArgumentError, "Unknown source type: #{source_type}"
      end
    end

    def create_command_factory_with_custom_commands
      factory = RobotChallenge::Commands::CommandFactory.new
      # Add any custom commands here if needed
      factory
    end
  end
end

# Include all test helpers
RSpec.configure do |config|
  config.include TestHelpers::TestData
  config.include TestHelpers::Assertions
  config.include TestHelpers::Setup
  config.include TestHelpers::Factories
end 