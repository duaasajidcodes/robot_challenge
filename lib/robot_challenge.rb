# frozen_string_literal: true

require_relative 'robot_challenge/version'
require_relative 'robot_challenge/config'
require_relative 'robot_challenge/input_source'
require_relative 'robot_challenge/output_formatter'
require_relative 'robot_challenge/position'
require_relative 'robot_challenge/direction'
require_relative 'robot_challenge/robot'
require_relative 'robot_challenge/table'
require_relative 'robot_challenge/commands/command'
require_relative 'robot_challenge/commands/place_command'
require_relative 'robot_challenge/commands/move_command'
require_relative 'robot_challenge/commands/left_command'
require_relative 'robot_challenge/commands/right_command'
require_relative 'robot_challenge/commands/report_command'
require_relative 'robot_challenge/commands/command_registry'
require_relative 'robot_challenge/commands/command_factory'
require_relative 'robot_challenge/command_processor'
require_relative 'robot_challenge/application'

module RobotChallenge
  class Error < StandardError; end
  class InvalidCommandError < Error; end
  class InvalidPositionError < Error; end
  class InvalidDirectionError < Error; end
  class RobotNotPlacedError < Error; end
end
