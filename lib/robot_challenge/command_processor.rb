# frozen_string_literal: true

module RobotChallenge
  # Coordinates command parsing and dispatching
  # Follows Single Responsibility Principle by delegating to specialized services
  class CommandProcessor
    attr_accessor :output_handler
    attr_reader :robot, :parser, :dispatcher

    # Backward compatibility: expose command_factory through parser
    def command_factory
      @parser.command_factory
    end

    def initialize(robot, output_handler: nil, parser: nil, dispatcher: nil, logger: nil)
      @robot = robot
      @output_handler = output_handler || method(:default_output_handler)
      @parser = parser || CommandParserService.new
      @dispatcher = dispatcher || CommandDispatcher.new(robot)
      @logger = logger || LoggerFactory.from_environment
    end

    # Process a command string
    def process_command_string(command_string)
      @logger.debug("Processing command: #{command_string}")
      command = @parser.parse(command_string)
      process_command(command)
    end

    # Process a command object
    def process_command(command)
      @logger.debug("Executing command: #{command.class}")
      @dispatcher.dispatch(command) do |formatted_message|
        handle_output(formatted_message)
      end
    end

    # Process a sequence of command strings
    def process_command_strings(command_strings)
      commands = @parser.parse_commands(command_strings)
      @dispatcher.dispatch_commands(commands) do |formatted_message|
        handle_output(formatted_message)
      end
    end

    # Get available commands
    def available_commands
      @parser.available_commands
    end

    # Register a new command type
    def register_command(name, command_class)
      @parser.register_command(name, command_class)
    end

    private

    def handle_output(formatted_message)
      @output_handler.call(formatted_message) if formatted_message
    end

    def default_output_handler(message)
      puts message
    end
  end
end
