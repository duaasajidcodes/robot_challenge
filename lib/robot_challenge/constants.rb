# frozen_string_literal: true

module RobotChallenge
  module Constants
    # Default table dimensions
    DEFAULT_TABLE_WIDTH = 5
    DEFAULT_TABLE_HEIGHT = 5

    # Valid directions
    VALID_DIRECTIONS = %w[NORTH SOUTH EAST WEST].freeze

    # Command names
    COMMAND_NAMES = %w[PLACE MOVE LEFT RIGHT REPORT].freeze

    # Output format types
    OUTPUT_FORMATS = %w[text json xml csv quiet].freeze

    # Environment names
    ENVIRONMENTS = %w[development test production].freeze

    # Application metadata
    APPLICATION_NAME = 'Robot Challenge Simulator'
    VERSION = '1.0.0'

    # Error messages
    ERROR_MESSAGES = {
      invalid_position: 'Position must be a Position object',
      invalid_direction: 'Direction must be a Direction object',
      robot_not_placed: 'Robot must be placed before %s',
      position_outside_table: 'Position %s is outside table boundaries',
      invalid_table_dimensions: 'Table dimensions must be positive integers',
      unsupported_input_source: 'Unsupported input source type: %s'
    }.freeze

    # Success messages
    SUCCESS_MESSAGES = {
      welcome: 'Welcome to Robot Challenge Simulator',
      goodbye: 'Thank you for using Robot Challenge Simulator!'
    }.freeze

    # Command descriptions
    COMMAND_DESCRIPTIONS = {
      place: 'PLACE X,Y,F - Place robot at position (X,Y) facing direction F',
      move: 'MOVE - Move robot one step forward',
      left: 'LEFT - Turn robot 90° counter-clockwise',
      right: 'RIGHT - Turn robot 90° clockwise',
      report: 'REPORT - Show current position and direction'
    }.freeze

    # File extensions
    FILE_EXTENSIONS = {
      json: '.json',
      xml: '.xml',
      csv: '.csv',
      txt: '.txt'
    }.freeze

    # Regex patterns
    PATTERNS = {
      robot_report: /^\d+,\d+,(NORTH|SOUTH|EAST|WEST)$/,
      place_command: /^PLACE\s+(\d+)\s*,\s*(\d+)\s*,\s*(NORTH|SOUTH|EAST|WEST)$/i,
      simple_command: /^(MOVE|LEFT|RIGHT|REPORT)$/i
    }.freeze

    # Configuration defaults
    CONFIG_DEFAULTS = {
      table_width: DEFAULT_TABLE_WIDTH,
      table_height: DEFAULT_TABLE_HEIGHT,
      output_format: 'text',
      debug_mode: false,
      test_mode: false,
      quiet_mode: false,
      log_level: 'info'
    }.freeze
  end
end
