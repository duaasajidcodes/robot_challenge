# frozen_string_literal: true

module RobotChallenge
  module Commands
    # Registry for managing available commands
    class CommandRegistry
      attr_reader :commands

      def initialize
        @commands = {}
        @aliases = {}
        register_default_commands
      end

      # Register a new command class
      def register(name, command_class, aliases: [])
        name = name.to_s.upcase
        @commands[name] = command_class
        
        # Register aliases
        aliases.each do |alias_name|
          @aliases[alias_name.to_s.upcase] = name
        end
      end

      # Check if a command is registered
      def registered?(name)
        name = name.to_s.upcase
        @commands.key?(name) || @aliases.key?(name)
      end

      # Get the actual command name (resolving aliases)
      def resolve_name(name)
        name = name.to_s.upcase
        @aliases[name] || name
      end

      # Get all registered command names
      def command_names
        (@commands.keys + @aliases.keys).sort
      end

      # Create a command instance
      def create_command(name, **params)
        resolved_name = resolve_name(name)
        command_class = @commands[resolved_name]
        return nil unless command_class

        case resolved_name
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
      rescue StandardError
        # Return nil for invalid command creation
        nil
      end

      private

      def register_default_commands
        register('PLACE', PlaceCommand)
        register('MOVE', MoveCommand)
        register('LEFT', LeftCommand)
        register('RIGHT', RightCommand)
        register('REPORT', ReportCommand)
      end
    end
  end
end
