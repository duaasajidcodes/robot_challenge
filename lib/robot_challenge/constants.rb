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
      goodbye: 'Thank you for using Robot Challenge Simulator!',
      exit_message: 'Goodbye! Thanks for using Robot Challenge!'
    }.freeze

    # Command descriptions
    COMMAND_DESCRIPTIONS = {
      place: 'PLACE X,Y,F - Place robot at position (X,Y) facing direction F',
      move: 'MOVE - Move robot one step forward',
      left: 'LEFT - Turn robot 90° counter-clockwise',
      right: 'RIGHT - Turn robot 90° clockwise',
      report: 'REPORT - Show current position and direction',
      exit: 'EXIT - Exit the application'
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

    # Menu options
    MENU_OPTIONS = {
      basic_commands: 'Basic Robot Commands',
      output_formats: 'Test Output Formats',
      input_sources: 'Test Input Sources',
      table_sizes: 'Test Different Table Sizes',
      cache_demo: 'Redis Cache Demo',
      examples: 'Run Example Scenarios',
      exit: 'Exit'
    }.freeze

    # Example scenarios
    EXAMPLE_SCENARIOS = {
      basic_movement: {
        name: 'Basic Movement',
        commands: ['PLACE 0,0,NORTH', 'MOVE', 'REPORT'],
        description: 'Place robot at origin, move north, report position'
      },
      rotation: {
        name: 'Rotation Test',
        commands: ['PLACE 0,0,NORTH', 'LEFT', 'REPORT'],
        description: 'Place robot, turn left, report direction'
      },
      complex_sequence: {
        name: 'Complex Sequence',
        commands: ['PLACE 1,2,EAST', 'MOVE', 'MOVE', 'LEFT', 'MOVE', 'REPORT'],
        description: 'Place robot, move twice, turn left, move, report'
      },
      edge_cases: {
        name: 'Edge Cases',
        commands: ['MOVE', 'LEFT', 'REPORT', 'PLACE 0,0,NORTH', 'MOVE', 'MOVE', 'MOVE', 'MOVE', 'MOVE', 'MOVE',
                   'REPORT'],
        description: 'Test invalid commands and boundary conditions'
      }
    }.freeze
  end
end
