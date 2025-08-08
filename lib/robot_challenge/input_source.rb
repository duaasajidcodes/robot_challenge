# frozen_string_literal: true

require 'stringio'

module RobotChallenge
  class InputSource
    def each_line(&)
      raise NotImplementedError, "#{self.class} must implement #each_line"
    end

    def gets
      raise NotImplementedError, "#{self.class} must implement #gets"
    end

    def tty?
      false
    end

    def close
      # Default implementation - override if needed
    end
  end

  class StdinInputSource < InputSource
    def initialize(io = $stdin)
      @io = io
    end

    def each_line(&)
      @io.each_line(&)
    end

    def gets
      @io.gets
    end

    def tty?
      @io.tty?
    end
  end

  class FileInputSource < InputSource
    def initialize(file_path)
      @file_path = file_path
      @file = nil
      @lines = nil
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

    def gets
      if @lines.nil?
        @lines = File.readlines(@file_path)
        @current_line = 0
      end

      return nil if @current_line >= @lines.length

      line = @lines[@current_line]
      @current_line += 1
      line
    end
  end

  class StringInputSource < InputSource
    def initialize(string)
      @string = string
      @lines = string.lines
      @current_line = 0
    end

    def each_line(&)
      @string.each_line(&)
    end

    def gets
      return nil if @current_line >= @lines.length

      line = @lines[@current_line]
      @current_line += 1
      line
    end
  end

  class ArrayInputSource < InputSource
    def initialize(array)
      @array = array
      @current_index = 0
    end

    def each_line(&)
      @array.each(&)
    end

    def gets
      return nil if @current_index >= @array.length

      line = @array[@current_index]
      @current_index += 1
      line.to_s
    end
  end

  class NetworkInputSource < InputSource
    def initialize(socket)
      @socket = socket
    end

    def each_line(&)
      @socket.each_line(&)
    end

    def gets
      @socket.gets
    end

    def close
      @socket.close
    end
  end

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
