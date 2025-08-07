# frozen_string_literal: true

module RobotChallenge
  class SimpleLogger
    include Logger

    def initialize(output = $stdout, level: :info)
      @output = output
      @level = level.to_sym
    end

    def info(message)
      log(:info, message)
    end

    def debug(message)
      log(:debug, message)
    end

    def warn(message)
      log(:warn, message)
    end

    def error(message)
      log(:error, message)
    end

    private

    def log(level, message)
      return unless should_log?(level)

      timestamp = Time.now.strftime('%Y-%m-%d %H:%M:%S')
      @output.puts "[#{timestamp}] #{level.upcase}: #{message}"
    end

    def should_log?(level)
      levels = { debug: 0, info: 1, warn: 2, error: 3 }
      levels[level] >= levels[@level]
    end
  end

  class NullLogger
    include Logger

    def info(_message); end
    def debug(_message); end
    def warn(_message); end
    def error(_message); end
  end

  class LoggerFactory
    def self.create(type = nil, **)
      case type&.to_s&.downcase
      when 'null', 'none'
        NullLogger.new
      when 'simple', 'stdout'
        SimpleLogger.new(**)
      else
        # Default based on environment
        if ENV['RACK_ENV'] == 'test' || ENV['ROBOT_ENV'] == 'test'
          NullLogger.new
        else
          SimpleLogger.new(**)
        end
      end
    end

    def self.from_environment
      level = ENV.fetch('ROBOT_LOG_LEVEL', 'info')
      create(ENV.fetch('ROBOT_LOGGER', 'simple'), level: level)
    end
  end
end
