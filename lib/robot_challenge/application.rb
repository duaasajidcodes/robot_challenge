# frozen_string_literal: true

require_relative 'robot'
require_relative 'table'
require_relative 'command_processor'
require_relative 'input_source'
require_relative 'output_formatter'
require_relative 'config'

module RobotChallenge
  class Application
    attr_accessor :output_formatter
    attr_reader :robot, :table, :processor, :input_source, :output_destination
    attr_writer :output_handler

    def initialize(table_width: nil, table_height: nil, input_source: $stdin, output_destination: $stdout, config: nil,
                   output_formatter: nil, processor: nil, robot: nil, table: nil, logger: nil,
                   command_parser: nil, command_dispatcher: nil)
      @config = config || Config.for_environment
      table_width ||= @config.table_width
      table_height ||= @config.table_height
      @table = table || Table.new(table_width, table_height)
      @robot = robot || processor&.robot || Robot.new(@table)
      @input_source = InputSourceFactory.create(input_source)
      @output_destination = output_destination
      @output_formatter = output_formatter || OutputFormatterFactory.from_environment
      @logger = logger || LoggerFactory.from_environment
      @processor = processor || create_processor(output_handler, command_parser, command_dispatcher)
    end

    def input_source=(source)
      @input_source = InputSourceFactory.create(source)
    end

    def set_input_source(source)
      @input_source = InputSourceFactory.create(source)
    end

    def set_output_handler(handler)
      @output_handler = handler
      processor.output_handler = handler if processor.respond_to?(:output_handler=)
    end

    def set_output_formatter(formatter)
      @output_formatter = formatter
      # Update the processor's output handler to use the new formatter
      processor.output_handler = method(:default_output_handler) if processor.respond_to?(:output_handler=)
      # Update the dispatcher's formatter
      return unless processor.dispatcher.respond_to?(:output_formatter=)

      processor.dispatcher.output_formatter = formatter
    end

    def run
      display_welcome_message

      # Check if input source is interactive
      if input_source.respond_to?(:tty?) && input_source.tty?
        run_interactive_mode
      else
        run_batch_mode
      end
    end

    def run_batch_mode
      input_source.each_line do |line|
        process_command(line.strip)
      end
    end

    def process_command(command_string)
      return if command_string.nil? || command_string.strip.empty?

      processor.process_command_string(command_string)
    end

    def process_commands(commands)
      commands.each { |command| process_command(command) }
    end

    def register_command(command_name, command_class)
      processor.register_command(command_name, command_class)
    end

    def available_commands
      processor.available_commands
    end

    private

    def display_welcome_message
      output_handler.call('Welcome to Robot Challenge!')
      output_handler.call('Commands: PLACE X,Y,DIRECTION, MOVE, LEFT, RIGHT, REPORT')
      output_handler.call('Type your commands:')
    end

    def run_interactive_mode
      loop do
        output_handler.call('> ')
        command = input_source.gets&.strip
        break if command.nil? || command.empty?

        process_command(command)
      end
    end

    def create_processor(output_handler, command_parser, command_dispatcher)
      CommandProcessor.new(
        robot,
        output_handler: output_handler,
        parser: command_parser,
        dispatcher: command_dispatcher,
        logger: @logger
      )
    end

    def output_handler
      @output_handler ||= method(:default_output_handler)
    end

    def default_output_handler(message)
      formatted_message = output_formatter.format(message)
      output_destination.puts(formatted_message)
    end
  end
end
