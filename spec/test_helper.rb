# frozen_string_literal: true

# Test helper for Robot Challenge
# This file sets up the test environment and loads test configuration

# Load the test environment configuration
require_relative '../lib/robot_challenge'

# Set test environment
ENV['ROBOT_ENV'] = 'test'

# Load test configuration
test_config = RobotChallenge::Config.for_environment('test')

# Configure test settings
RSpec.configure do |config|
  config.before do
    # Load test environment variables
    test_config.load_from_environment
  end

  config.after do
    # Clean up any test-specific environment variables
    %w[ROBOT_TEST_MODE ROBOT_DEBUG_MODE ROBOT_QUIET_MODE].each do |var|
      ENV.delete(var)
    end
  end
end

# Helper methods for testing
module TestHelpers
  def create_test_application(config_overrides = {})
    test_config = RobotChallenge::Config.for_environment('test')

    # Apply any overrides
    config_overrides.each do |key, value|
      test_config.instance_variable_set("@#{key}", value)
    end

    RobotChallenge::Application.new(config: test_config)
  end

  def create_test_robot(table_width: 5, table_height: 5)
    table = RobotChallenge::Table.new(table_width, table_height)
    RobotChallenge::Robot.new(table)
  end

  def create_test_processor(robot = nil, output_handler = nil)
    robot ||= create_test_robot
    RobotChallenge::CommandProcessor.new(robot, output_handler: output_handler)
  end
end

# Include test helpers in RSpec
RSpec.configure do |config|
  config.include TestHelpers
end
