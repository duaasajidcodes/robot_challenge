# frozen_string_literal: true

module RobotChallenge
  # Responsible for parsing command line arguments
  # Separates CLI argument parsing from application logic (SRP)
  class CliArgumentParser
    attr_reader :table_width, :table_height, :input_file, :output_format

    def initialize(argv = ARGV)
      @argv = argv
      parse_arguments
    end

    def help_requested?
      @argv.include?('--help') || @argv.include?('-h')
    end

    def display_help
      puts <<~HELP
        Robot Challenge Simulator

        Usage: #{$PROGRAM_NAME} [options] [input_file]

        Options:
          --width, -w WIDTH    Set table width (default: 5)
          --height, -h HEIGHT  Set table height (default: 5)
          --input, -i FILE     Read commands from file
          --output, -o FORMAT  Set output format (text, json, xml, csv, quiet)
          --help               Show this help message

        Environment Variables:
          ROBOT_TABLE_WIDTH    Set table width (default: 5)
          ROBOT_TABLE_HEIGHT   Set table height (default: 5)
          ROBOT_OUTPUT_FORMAT  Set output format (text, json, xml, csv, quiet)

        Examples:
          #{$PROGRAM_NAME}                    # Run with default 5x5 table
          #{$PROGRAM_NAME} -w 10 -h 8        # Run with 10x8 table
          ROBOT_TABLE_WIDTH=10 #{$PROGRAM_NAME} # Run with 10x5 table
          #{$PROGRAM_NAME} < commands.txt    # Run with input from stdin
          #{$PROGRAM_NAME} commands.txt      # Run with input from file
          #{$PROGRAM_NAME} -i commands.txt   # Run with input from file
          #{$PROGRAM_NAME} -o json           # Run with JSON output
          #{$PROGRAM_NAME} -o xml            # Run with XML output
      HELP
    end

    def validate!
      if table_width < 1 || table_height < 1
        raise ArgumentError, 'Table dimensions must be positive integers'
      end
    end

    private

    def parse_arguments
      # Initialize with environment variable defaults
      @table_width = ENV.fetch('ROBOT_TABLE_WIDTH', 5).to_i
      @table_height = ENV.fetch('ROBOT_TABLE_HEIGHT', 5).to_i
      @input_file = nil
      @output_format = ENV.fetch('ROBOT_OUTPUT_FORMAT', nil)

      # Parse command line arguments
      @argv.each_with_index do |arg, index|
        case arg
        when '--width', '-w'
          @table_width = @argv[index + 1].to_i if @argv[index + 1]
        when '--height', '-h'
          @table_height = @argv[index + 1].to_i if @argv[index + 1]
        when '--input', '-i'
          @input_file = @argv[index + 1] if @argv[index + 1]
        when '--output', '-o'
          @output_format = @argv[index + 1] if @argv[index + 1]
        end
      end

      # Check for input file as positional argument if not specified with --input
      @input_file = @argv.first if @input_file.nil? && @argv.any? && !@argv.first.start_with?('-')
    end
  end
end 