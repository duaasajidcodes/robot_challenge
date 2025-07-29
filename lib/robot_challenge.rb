# frozen_string_literal: true

require_relative 'robot_challenge/version'
require_relative 'robot_challenge/position'
require_relative 'robot_challenge/direction'
require_relative 'robot_challenge/robot'
require_relative 'robot_challenge/table'
require_relative 'robot_challenge/command_parser'
require_relative 'robot_challenge/command_processor'
require_relative 'robot_challenge/application'

module RobotChallenge
  class Error < StandardError; end
  class InvalidCommandError < Error; end
  class InvalidPositionError < Error; end
  class InvalidDirectionError < Error; end
  class RobotNotPlacedError < Error; end
end
