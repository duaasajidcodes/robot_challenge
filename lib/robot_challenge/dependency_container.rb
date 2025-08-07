# frozen_string_literal: true

module RobotChallenge
  class DependencyContainer
    def initialize
      @dependencies = {}
      @factories = {}
      register_defaults
    end

    def register(name, instance)
      @dependencies[name] = instance
    end

    def register_factory(name, &block)
      @factories[name] = block
    end

    def resolve(name)
      return @dependencies[name] if @dependencies.key?(name)
      return @factories[name].call if @factories.key?(name)

      raise ArgumentError, "Dependency '#{name}' not registered"
    end

    def registered?(name)
      @dependencies.key?(name) || @factories.key?(name)
    end

    def create(klass, **overrides)
      constructor = klass.instance_method(:initialize)
      params = constructor.parameters
      args = build_arguments(params, overrides)
      klass.new(**args)
    end

    private

    def build_arguments(params, overrides)
      args = {}
      params.each do |type, param|
        next if overrides.key?(param)

        if type == :req && !registered?(param)
          raise ArgumentError, "Required parameter '#{param}' not registered in container"
        end

        args[param] = resolve(param) if registered?(param)
      end
      args.merge!(overrides)
    end

    def register_defaults
      register_basic_factories
      register_table_factory
      register_robot_factory
      register_command_factories
      register_processor_factory
    end

    def register_basic_factories
      register_factory(:logger) { LoggerFactory.from_environment }
      register_factory(:output_formatter) { OutputFormatterFactory.from_environment }
      register_factory(:config) { Config.for_environment }
    end

    def register_table_factory
      register_factory(:table) do
        config = resolve(:config)
        Table.new(config.table_width, config.table_height)
      end
    end

    def register_robot_factory
      register_factory(:robot) do
        table = resolve(:table)
        Robot.new(table)
      end
    end

    def register_command_factories
      register_factory(:command_parser) { CommandParserService.new }
      register_factory(:command_dispatcher) do
        robot = resolve(:robot)
        output_formatter = resolve(:output_formatter)
        logger = resolve(:logger)
        CommandDispatcher.new(robot, output_formatter: output_formatter, logger: logger)
      end
    end

    def register_processor_factory
      register_factory(:command_processor) do
        robot = resolve(:robot)
        parser = resolve(:command_parser)
        dispatcher = resolve(:command_dispatcher)
        logger = resolve(:logger)
        CommandProcessor.new(robot, parser: parser, dispatcher: dispatcher, logger: logger)
      end
    end
  end

  @container = nil

  def self.container
    @container ||= DependencyContainer.new
  end

  def self.container=(container)
    @container = container
  end

  def self.resolve(name)
    container.resolve(name)
  end

  def self.create(klass, **overrides)
    container.create(klass, **overrides)
  end
end
