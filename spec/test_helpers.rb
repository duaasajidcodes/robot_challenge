# frozen_string_literal: true

require 'tempfile'
require 'stringio'

# Common test helpers to reduce repetition (DRY principle)
module TestHelpers
  # Create a test robot with a specific position
  def create_test_robot_with_position(pos_x, pos_y, direction_name)
    table = RobotChallenge::Table.new(5, 5)
    robot = RobotChallenge::Robot.new(table)
    position = RobotChallenge::Position.new(pos_x, pos_y)
    direction = RobotChallenge::Direction.new(direction_name)
    robot.place(position, direction)
    robot
  end

  # Create a test table with custom dimensions
  def create_test_table(width, height)
    RobotChallenge::Table.new(width, height)
  end

  # Create a test position
  def create_test_position(x_coord, y_coord)
    RobotChallenge::Position.new(x_coord, y_coord)
  end

  # Create a test direction
  def create_test_direction(direction_name)
    RobotChallenge::Direction.new(direction_name)
  end

  # Create a test command factory
  def create_test_command_factory
    RobotChallenge::Commands::CommandFactory.new
  end

  # Create a test command registry
  def create_test_command_registry
    RobotChallenge::Commands::CommandRegistry.new
  end

  # Create a test command processor
  def create_test_command_processor(robot = nil)
    robot ||= create_test_robot_with_position(0, 0, 'NORTH')
    RobotChallenge::CommandProcessor.new(robot)
  end

  # Create a test application
  def create_test_application
    RobotChallenge::Application.new
  end

  # Create a test input source
  def create_input_source(source_type, data = nil)
    case source_type
    when :file
      temp_file = Tempfile.new(['test', '.txt'])
      temp_file.write(data || "PLACE 0,0,NORTH\nMOVE\nREPORT")
      temp_file.close
      RobotChallenge::InputSourceFactory.create(temp_file.path)
    when :string
      RobotChallenge::InputSourceFactory.create(data || "PLACE 0,0,NORTH\nMOVE\nREPORT")
    when :array
      RobotChallenge::InputSourceFactory.create(data || ['PLACE 0,0,NORTH', 'MOVE', 'REPORT'])
    when :stdin
      RobotChallenge::InputSourceFactory.create(StringIO.new(data || "PLACE 0,0,NORTH\nMOVE\nREPORT"))
    else
      raise ArgumentError, "Unknown source type: #{source_type}"
    end
  end

  # Create a test output formatter
  def create_test_output_formatter(format_type = :text)
    RobotChallenge::OutputFormatterFactory.create(format_type)
  end

  # Create a test logger
  def create_test_logger(logger_type = :simple)
    case logger_type
    when :simple
      RobotChallenge::SimpleLogger.new
    when :null
      RobotChallenge::NullLogger.new
    else
      raise ArgumentError, "Unknown logger type: #{logger_type}"
    end
  end

  # Create a test cache
  def create_test_cache
    RobotChallenge::Cache::RedisCache.new
  end

  # Create a test dependency container
  def create_test_dependency_container
    RobotChallenge::DependencyContainer.new
  end

  # Helper method to run commands and capture output
  def run_commands_and_capture_output(commands, application = nil)
    application ||= create_test_application
    output = StringIO.new
    application.instance_variable_set(:@output_destination, output)

    if commands.is_a?(String)
      commands.lines.each { |line| application.process_command(line.strip) }
    elsif commands.is_a?(Array)
      commands.each { |command| application.process_command(command) }
    end

    output.string
  end

  # Helper method to create a custom command class
  def create_custom_command_class(name, &block)
    Class.new(RobotChallenge::Commands::Command) do
      define_method(:execute) do |_robot|
        instance_eval(&block) if block_given?
        RobotChallenge::Commands::Command.new.success_result
      end

      define_singleton_method(:name) { name }
    end
  end
end

# Include all test helpers
RSpec.configure do |config|
  config.include TestHelpers
end
