# frozen_string_literal: true

module RobotChallenge
  # Configuration management for the Robot Challenge application
  class Config
    attr_reader :table_width, :table_height, :test_mode, :debug_mode,
                :output_format, :quiet_mode, :max_commands, :timeout_seconds,
                :test_data_dir, :log_level

    def initialize(env_file: nil)
      load_environment_file(env_file) if env_file
      load_from_environment
    end

    # Load configuration from environment variables
    def load_from_environment
      @table_width = ENV.fetch('ROBOT_TABLE_WIDTH', 5).to_i
      @table_height = ENV.fetch('ROBOT_TABLE_HEIGHT', 5).to_i
      @test_mode = ENV.fetch('ROBOT_TEST_MODE', 'false').downcase == 'true'
      @debug_mode = ENV.fetch('ROBOT_DEBUG_MODE', 'false').downcase == 'true'
      @output_format = ENV.fetch('ROBOT_OUTPUT_FORMAT', 'text')
      @quiet_mode = ENV.fetch('ROBOT_QUIET_MODE', 'false').downcase == 'true'
      @max_commands = ENV.fetch('ROBOT_MAX_COMMANDS', 100_000).to_i
      @timeout_seconds = ENV.fetch('ROBOT_TIMEOUT_SECONDS', 60).to_i
      @test_data_dir = ENV.fetch('ROBOT_TEST_DATA_DIR', 'test_data')
      @log_level = ENV.fetch('ROBOT_LOG_LEVEL', 'info').to_sym
    end

    # Load configuration from a .env file
    def load_environment_file(file_path)
      return unless File.exist?(file_path)

      File.readlines(file_path).each do |line|
        line = line.strip
        next if line.empty? || line.start_with?('#')

        key, value = line.split('=', 2)
        next unless key && value

        # Remove quotes if present
        value = value.gsub(/^["']|["']$/, '')

        # Set environment variable
        ENV[key.strip] = value.strip
      end
    end

    # Get table dimensions as a hash
    def table_dimensions
      { width: @table_width, height: @table_height }
    end

    # Check if running in test mode
    def test_mode?
      @test_mode
    end

    # Check if running in debug mode
    def debug_mode?
      @debug_mode
    end

    # Check if running in quiet mode
    def quiet_mode?
      @quiet_mode
    end

    # Get configuration as a hash
    def to_h
      {
        table_width: @table_width,
        table_height: @table_height,
        test_mode: @test_mode,
        debug_mode: @debug_mode,
        output_format: @output_format,
        quiet_mode: @quiet_mode,
        max_commands: @max_commands,
        timeout_seconds: @timeout_seconds,
        test_data_dir: @test_data_dir,
        log_level: @log_level
      }
    end

    # Create a configuration for a specific environment
    def self.for_environment(env = nil)
      env ||= ENV.fetch('ROBOT_ENV', 'development')
      env_file = ".env.#{env}"

      new(env_file: env_file)
    end
  end
end
