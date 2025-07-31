# frozen_string_literal: true

module RobotChallenge
  class CommandProcessor
    attr_reader :robot, :output_handler

    def initialize(robot, output_handler = nil)
      @robot = robot
      @output_handler = output_handler || method(:default_output_handler)
    end

    def process_command(command)
      return false if command.nil?

      case command[:command]
      when :place
        process_place_command(command)
      when :move
        process_move_command
      when :left
        process_left_command
      when :right
        process_right_command
      when :report
        process_report_command
      when :exit, :quit
        return true
      else
        false
      end

      false
    rescue RobotChallenge::Error => e
      handle_error(e)
      false
    end

    def process_commands(command_strings)
      warn 'Warning: process_commands loads all commands into memory. Use streaming approach for large datasets.'
      command_strings.each do |command_string|
        command = CommandParser.parse(command_string)
        should_exit = process_command(command)
        return if should_exit
      end
    end

    def process_command_stream(input_stream)
      input_stream.each_line do |line|
        command_string = line.chomp
        next if command_string.empty?

        command = CommandParser.parse(command_string)
        should_exit = process_command(command)
        return if should_exit
      end
    end

    private

    def process_place_command(command)
      position = Position.new(command[:x], command[:y])
      direction = Direction.new(command[:direction])
      robot.place(position, direction)
    end

    def process_move_command
      robot.move
    end

    def process_left_command
      robot.turn_left
    end

    def process_right_command
      robot.turn_right
    end

    def process_report_command
      report = robot.report
      output_handler.call(report)
    end

    def handle_error(error); end

    def default_output_handler(message)
      puts message
    end
  end
end
