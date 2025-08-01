# frozen_string_literal: true

module RobotChallenge
  module Commands
    # Registry for managing available commands
    class CommandRegistry
      def initialize
        @commands = {}
        register_default_commands
      end

      # Register a command class with a name
      def register(name, command_class)
        @commands[name.to_s.upcase] = command_class
      end

      # Check if a command is registered
      def registered?(name)
        @commands.key?(name.to_s.upcase)
      end

      # Get all registered command names
      def command_names
        @commands.keys.sort
      end

      # Create a command instance from parsed parameters
      def create_command(name, **params)
        command_class = @commands[name.to_s.upcase]
        return nil unless command_class

        create_command_with_default_constructor(command_class, name, **params)
      rescue StandardError
        # Return nil for invalid command creation
        nil
      end

      private

      def create_command_with_default_constructor(command_class, name, **params)
        case name.to_s.upcase
        when 'PLACE'
          command_class.new(params[:x], params[:y], params[:direction])
        else
          # For commands with no parameters, try default constructor
          if params.empty?
            command_class.new
          else
            # For commands with parameters, try constructor with params
            command_class.new(**params)
          end
        end
      end

      def register_default_commands
        register('PLACE', Commands::PlaceCommand)
        register('MOVE', Commands::MoveCommand)
        register('LEFT', Commands::LeftCommand)
        register('RIGHT', Commands::RightCommand)
        register('REPORT', Commands::ReportCommand)
      end
    end
  end
end
