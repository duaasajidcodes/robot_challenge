# frozen_string_literal: true

module RobotChallenge
  # Main application class that orchestrates the robot simulation
  class Application
    attr_reader :robot, :processor, :input_source, :output_destination

    def initialize(table_width: 5, table_height: 5, input_source: $stdin, output_destination: $stdout)
      @table = Table.new(table_width, table_height)
      @robot = Robot.new(@table)
      @input_source = input_source
      @output_destination = output_destination
      @processor = CommandProcessor.new(@robot, method(:output_handler))
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
      command = CommandParser.parse(command_string)
      processor.process_command(command)
    end

    # Process multiple command strings
    def process_commands(command_strings)
      processor.process_commands(command_strings)
    end

    private

    def run_interactive_mode
      output_destination.puts 'Interactive mode - enter commands (type EXIT or QUIT to exit):'
      output_destination.print '> '

      input_source.each_line do |line|
        command_string = line.chomp

        break if exit_command?(command_string)

        should_exit = process_command(command_string)
        break if should_exit

        output_destination.print '> '
      end
    end

    def run_batch_mode
      input_source.each_line do |line|
        command_string = line.chomp
        should_exit = process_command(command_string)
        break if should_exit
      end
    end

    def exit_command?(command_string)
      normalized = command_string.strip.upcase
      %w[EXIT QUIT].include?(normalized)
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
          RIGHT        - Turn robot 90° clockwise#{'  '}
          REPORT       - Show current position and direction
          EXIT/QUIT    - Exit the application

        Table size: #{@table}
        Valid directions: #{Direction.valid_directions.join(', ')}

      WELCOME
    end

    def display_goodbye_message
      return unless input_source.tty?

      output_destination.puts 'Goodbye!'
    end
  end
end
