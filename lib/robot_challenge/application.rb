# frozen_string_literal: true

module RobotChallenge
  # Main application class that orchestrates the robot simulation
  class Application
    attr_reader :robot, :processor, :input_source, :output_destination

    def initialize(table_width: nil, table_height: nil, input_source: $stdin, output_destination: $stdout, config: nil)
      # Load configuration
      @config = config || Config.for_environment

      # Support environment variables for table dimensions
      table_width ||= @config.table_width
      table_height ||= @config.table_height

      @table = Table.new(table_width, table_height)
      @robot = Robot.new(@table)
      @input_source = input_source
      @output_destination = output_destination
      @processor = CommandProcessor.new(@robot, output_handler: method(:output_handler))
    end

    # Set a custom output handler for testing
    def set_output_handler(handler)
      @processor = CommandProcessor.new(@robot, output_handler: handler)
    end

    # Run the application
    def run
      display_welcome_message

      if input_source.tty?
        run_interactive_mode
      else
        run_batch_mode
      end

      display_goodbye_message
    rescue Interrupt
      output_destination.puts "\nGoodbye!"
    rescue StandardError => e
      output_destination.puts "An error occurred: #{e.message}"
      exit(1)
    end

    # Process a single command string
    def process_command(command_string)
      processor.process_command_string(command_string)
    end

    # Process multiple command strings
    def process_commands(command_strings)
      processor.process_command_strings(command_strings)
    end

    # Register a new command type
    def register_command(name, command_class)
      processor.register_command(name, command_class)
    end

    # Get available commands
    def available_commands
      processor.available_commands
    end

    private

    def run_interactive_mode
      output_destination.puts 'Interactive mode - enter commands (Ctrl-C to exit):'
      output_destination.print '> '

      input_source.each_line do |line|
        command_string = line.chomp
        processor.process_command_string(command_string)
        output_destination.print '> '
      end
    end

    def run_batch_mode
      # Use streaming to process large files efficiently
      # This prevents loading entire file into memory
      input_source.each_line do |line|
        command_string = line.chomp
        processor.process_command_string(command_string)
      end
    end

    def output_handler(message)
      output_destination.puts message
    end

    def display_welcome_message
      return unless input_source.tty?

      output_destination.puts <<~WELCOME
        Robot Challenge Simulator
        ========================

        Commands:
          PLACE X,Y,F  - Place robot at position (X,Y) facing direction F
          MOVE         - Move robot one step forward
          LEFT         - Turn robot 90° counter-clockwise
          RIGHT        - Turn robot 90° clockwise
          REPORT       - Show current position and direction

        Table size: #{@table}
        Valid directions: #{Direction.valid_directions.join(', ')}

      WELCOME
    end

    def display_goodbye_message
      return unless input_source.tty?

      output_destination.puts "\nThank you for using Robot Challenge Simulator!"
    end
  end
end
