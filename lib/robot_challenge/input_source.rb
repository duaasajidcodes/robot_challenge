# frozen_string_literal: true

module RobotChallenge
  # Abstract base class for input sources
  class InputSource
    def each_line(&block)
      raise NotImplementedError, "#{self.class} must implement #each_line"
    end

    def tty?
      false
    end

    def close
      # Default implementation - override if needed
    end
  end

  # Input source for standard input
  class StdinInputSource < InputSource
    def initialize(io = $stdin)
      @io = io
    end

    def each_line(&block)
      @io.each_line(&block)
    end

    def tty?
      @io.tty?
    end
  end

  # Input source for file input
  class FileInputSource < InputSource
    def initialize(file_path)
      @file_path = file_path
    end

    def each_line(&block)
      File.open(@file_path, 'r') do |file|
        file.each_line(&block)
      end
    rescue Errno::ENOENT
      raise ArgumentError, "File not found: #{@file_path}"
    rescue Errno::EACCES
      raise ArgumentError, "Permission denied: #{@file_path}"
    end
  end

  # Input source for string input (useful for testing)
  class StringInputSource < InputSource
    def initialize(string)
      @string = string
    end

    def each_line(&block)
      @string.each_line(&block)
    end
  end

  # Input source for array input (useful for testing)
  class ArrayInputSource < InputSource
    def initialize(array)
      @array = array
    end

    def each_line(&block)
      @array.each(&block)
    end
  end

  # Input source for network/socket input (extensible for future)
  class NetworkInputSource < InputSource
    def initialize(socket)
      @socket = socket
    end

    def each_line(&block)
      @socket.each_line(&block)
    end

    def close
      @socket.close
    end
  end

  # Input source factory for creating input sources
  class InputSourceFactory
    def self.create(source)
      case source
      when String
        # If it's a file path
        if File.exist?(source)
          FileInputSource.new(source)
        else
          # Treat as string input
          StringInputSource.new(source)
        end
      when Array
        ArrayInputSource.new(source)
      when IO, StringIO
        StdinInputSource.new(source)
      when InputSource
        source
      else
        raise ArgumentError, "Unsupported input source type: #{source.class}"
      end
    end

    def self.from_file_path(file_path)
      FileInputSource.new(file_path)
    end

    def self.from_string(string)
      StringInputSource.new(string)
    end

    def self.from_array(array)
      ArrayInputSource.new(array)
    end

    def self.from_stdin(io = $stdin)
      StdinInputSource.new(io)
    end
  end
end
