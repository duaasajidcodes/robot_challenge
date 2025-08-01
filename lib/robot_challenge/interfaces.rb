# frozen_string_literal: true

module RobotChallenge
  # Interface for command parsing
  module CommandParser
    def parse(command_string)
      raise NotImplementedError, "#{self.class} must implement #parse"
    end

    def parse_commands(command_strings)
      raise NotImplementedError, "#{self.class} must implement #parse_commands"
    end

    def available_commands
      raise NotImplementedError, "#{self.class} must implement #available_commands"
    end

    def register_command(name, command_class)
      raise NotImplementedError, "#{self.class} must implement #register_command"
    end
  end

  # Interface for command dispatching
  module CommandDispatcherInterface
    def dispatch(command, &block)
      raise NotImplementedError, "#{self.class} must implement #dispatch"
    end

    def dispatch_commands(commands, &block)
      raise NotImplementedError, "#{self.class} must implement #dispatch_commands"
    end
  end

  # Interface for output handling
  module OutputHandler
    def call(message)
      raise NotImplementedError, "#{self.class} must implement #call"
    end
  end

  # Interface for robot operations
  module RobotOperations
    def place(position, direction)
      raise NotImplementedError, "#{self.class} must implement #place"
    end

    def move
      raise NotImplementedError, "#{self.class} must implement #move"
    end

    def turn_left
      raise NotImplementedError, "#{self.class} must implement #turn_left"
    end

    def turn_right
      raise NotImplementedError, "#{self.class} must implement #turn_right"
    end

    def report
      raise NotImplementedError, "#{self.class} must implement #report"
    end

    def placed?
      raise NotImplementedError, "#{self.class} must implement #placed?"
    end
  end

  # Interface for table operations
  module TableOperations
    def valid_position?(position)
      raise NotImplementedError, "#{self.class} must implement #valid_position?"
    end

    def width
      raise NotImplementedError, "#{self.class} must implement #width"
    end

    def height
      raise NotImplementedError, "#{self.class} must implement #height"
    end
  end

  # Interface for logging
  module Logger
    def info(message)
      raise NotImplementedError, "#{self.class} must implement #info"
    end

    def debug(message)
      raise NotImplementedError, "#{self.class} must implement #debug"
    end

    def warn(message)
      raise NotImplementedError, "#{self.class} must implement #warn"
    end

    def error(message)
      raise NotImplementedError, "#{self.class} must implement #error"
    end
  end
end
