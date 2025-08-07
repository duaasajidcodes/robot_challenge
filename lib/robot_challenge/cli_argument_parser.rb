# frozen_string_literal: true

module RobotChallenge
  class CliArgumentParser
    attr_reader :table_width, :table_height, :input_file, :output_format

    def initialize(argv = ARGV)
      @argv = argv
      parse_arguments
    end

    def help_requested?
      @argv.include?('--help') || (@argv.include?('-h') && help_flag_not_height?)
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
      return unless table_width < 1 || table_height < 1

      raise ArgumentError, 'Table dimensions must be positive integers'
    end

    private

    def parse_arguments
      initialize_from_environment
      parse_command_line_arguments
      handle_positional_input_file
    end

    def initialize_from_environment
      @table_width = ENV.fetch('ROBOT_TABLE_WIDTH', 5).to_i
      @table_height = ENV.fetch('ROBOT_TABLE_HEIGHT', 5).to_i
      @input_file = nil
      @output_format = ENV.fetch('ROBOT_OUTPUT_FORMAT', nil)
    end

    def parse_command_line_arguments
      @argv.each_with_index do |arg, index|
        parse_argument(arg, index)
      end
    end

    def parse_argument(arg, index)
      case arg
      when '--width', '-w'
        parse_width(index)
      when '--height', '-h'
        parse_height(index)
      when '--input', '-i'
        parse_input_file(index)
      when '--output', '-o'
        parse_output_format(index)
      end
    end

    def handle_positional_input_file
      return if @input_file || @argv.empty? || @argv.first.start_with?('-')

      @input_file = @argv.first
    end

    def help_flag_not_height?
      h_index = @argv.index('-h')
      return true if h_index.nil?

      # If -h is followed by a number, it's likely --height
      next_arg = @argv[h_index + 1]
      next_arg.nil? || !next_arg.match?(/\A\d+\z/)
    end

    def parse_width(index)
      @table_width = @argv[index + 1].to_i if @argv[index + 1]
    end

    def parse_height(index)
      @table_height = @argv[index + 1].to_i if @argv[index + 1]
    end

    def parse_input_file(index)
      @input_file = @argv[index + 1] if @argv[index + 1]
    end

    def parse_output_format(index)
      @output_format = @argv[index + 1] if @argv[index + 1]
    end
  end
end
