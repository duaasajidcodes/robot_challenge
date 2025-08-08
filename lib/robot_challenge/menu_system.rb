# frozen_string_literal: true

module RobotChallenge
  class MenuSystem
    attr_reader :application

    def initialize(application)
      @application = application
    end

    def run
      loop do
        display_main_menu
        choice = user_choice
        break if choice == '7'

        handle_menu_choice(choice)
      end
    end

    private

    def display_main_menu
      MenuDisplay.new.show_main_menu
    end

    def user_choice
      gets&.strip || '7'
    end

    def handle_menu_choice(choice)
      MenuHandler.new(application).handle(choice)
    end
  end

  class MenuDisplay
    def show_main_menu
      puts "\n#{'=' * 50}"
      puts '🤖 ROBOT CHALLENGE SIMULATOR MENU'
      puts '=' * 50
      show_menu_options
      puts '=' * 50
      print 'Enter your choice (1-7): '
    end

    private

    def show_menu_options
      Constants::MENU_OPTIONS.each_with_index do |(_key, option), index|
        puts "#{index + 1}. #{option}"
      end
    end
  end

  class MenuHandler
    attr_reader :application

    def initialize(application)
      @application = application
    end

    def handle(choice)
      case choice
      when '1'
        BasicCommandsMenu.new(application).run
      when '2'
        OutputFormatsMenu.new(application).run
      when '3'
        InputSourcesMenu.new(application).run
      when '4'
        TableSizesMenu.new(application).run
      when '5'
        CacheDemoMenu.new(application).run
      when '6'
        ExamplesMenu.new(application).run
      else
        puts 'Invalid choice. Please try again.'
      end
    end
  end

  class BasicCommandsMenu
    attr_reader :application

    def initialize(application)
      @application = application
    end

    def run
      display_header
      run_command_loop
    end

    private

    def display_header
      puts "\n#{'-' * 40}"
      puts 'BASIC ROBOT COMMANDS'
      puts '-' * 40
      puts "Enter commands one by one (or 'back' to return):"
      puts 'Available commands: PLACE X,Y,DIRECTION, MOVE, LEFT, RIGHT, REPORT, EXIT'
    end

    def run_command_loop
      loop do
        print '> '
        command = gets&.strip
        break if command == 'back' || command.nil?

        application.process_command(command)
      end
    end
  end

  class OutputFormatsMenu
    attr_reader :application

    def initialize(application)
      @application = application
    end

    def run
      display_menu
      choice = gets&.strip
      return if choice == '6' || choice.nil?

      format = format_map[choice]
      if format
        test_output_format(format)
      else
        puts 'Invalid choice.'
      end
    end

    private

    def display_menu
      puts "\n#{'-' * 40}"
      puts 'OUTPUT FORMATS TEST'
      puts '-' * 40
      show_format_options
    end

    def show_format_options
      format_options.each_with_index do |option, index|
        puts "#{index + 1}. #{option}"
      end
      puts '6. Back to main menu'
      print 'Choose format (1-6): '
    end

    def format_options
      ['Text format (default)', 'JSON format', 'XML format', 'CSV format', 'Quiet format (no output)']
    end

    def format_map
      {
        '1' => 'text',
        '2' => 'json',
        '3' => 'xml',
        '4' => 'csv',
        '5' => 'quiet'
      }
    end

    def test_output_format(format)
      puts "\nTesting #{format.upcase} output format..."
      puts '=' * 40

      test_app = Application.new(
        output_formatter: OutputFormatterFactory.create(format)
      )

      test_commands.each do |command|
        puts "Command: #{command}"
        test_app.process_command(command)
        puts '-' * 20
      end
    end

    def test_commands
      ['PLACE 1,2,NORTH', 'MOVE', 'LEFT', 'REPORT']
    end
  end

  class InputSourcesMenu
    attr_reader :application

    def initialize(application)
      @application = application
    end

    def run
      display_menu
      choice = gets&.strip
      return if choice == '4' || choice.nil?

      handle_choice(choice)
    end

    private

    def display_menu
      puts "\n#{'-' * 40}"
      puts 'INPUT SOURCES TEST'
      puts '-' * 40
      puts '1. String input'
      puts '2. Array input'
      puts '3. File input (test_data/example_1.txt)'
      puts '4. Back to main menu'
      print 'Choose input source (1-4): '
    end

    def handle_choice(choice)
      case choice
      when '1'
        test_string_input
      when '2'
        test_array_input
      when '3'
        test_file_input
      else
        puts 'Invalid choice.'
      end
    end

    def test_string_input
      puts "\nTesting String Input Source..."
      puts '=' * 40

      commands = "PLACE 0,0,NORTH\nMOVE\nREPORT"
      source = InputSourceFactory.from_string(commands)

      test_app = Application.new(input_source: source)
      test_app.run
    end

    def test_array_input
      puts "\nTesting Array Input Source..."
      puts '=' * 40

      commands = ['PLACE 2,2,EAST', 'MOVE', 'RIGHT', 'MOVE', 'REPORT']
      source = InputSourceFactory.from_array(commands)

      test_app = Application.new(input_source: source)
      test_app.run
    end

    def test_file_input
      puts "\nTesting File Input Source..."
      puts '=' * 40

      if File.exist?('test_data/example_1.txt')
        source = InputSourceFactory.from_file_path('test_data/example_1.txt')
        test_app = Application.new(input_source: source)
        test_app.run
      else
        puts 'File example_1.txt not found. Using built-in test data...'
        
        test_commands = ['PLACE 0,0,NORTH', 'MOVE', 'REPORT']
        source = InputSourceFactory.from_array(test_commands)
        test_app = Application.new(input_source: source)
        test_app.run
      end
    end
  end

  class TableSizesMenu
    attr_reader :application

    def initialize(application)
      @application = application
    end

    def run
      display_menu
      choice = gets&.strip
      return if choice == '5' || choice.nil?

      handle_choice(choice)
    end

    private

    def display_menu
      puts "\n#{'-' * 40}"
      puts 'TABLE SIZES TEST'
      puts '-' * 40
      show_size_options
    end

    def show_size_options
      size_options.each_with_index do |option, index|
        puts "#{index + 1}. #{option}"
      end
      puts '5. Back to main menu'
      print 'Choose table size (1-5): '
    end

    def size_options
      ['5x5 (default)', '10x10', '3x3', '8x6']
    end

    def handle_choice(choice)
      size_map = {
        '1' => [5, 5],
        '2' => [10, 10],
        '3' => [3, 3],
        '4' => [8, 6]
      }

      if size_map[choice]
        width, height = size_map[choice]
        test_table_size(width, height)
      else
        puts 'Invalid choice.'
      end
    end

    def test_table_size(width, height)
      puts "\nTesting #{width}x#{height} table..."
      puts '=' * 40

      test_app = Application.new(
        table_width: width,
        table_height: height
      )

      test_commands(width, height).each do |command|
        puts "Command: #{command}"
        test_app.process_command(command)
        puts '-' * 20
      end
    end

    def test_commands(width, height)
      [
        'PLACE 0,0,NORTH',
        'MOVE',
        'REPORT',
        "PLACE #{width - 1},#{height - 1},SOUTH",
        'MOVE',
        'REPORT'
      ]
    end
  end

  class CacheDemoMenu
    attr_reader :application

    def initialize(application)
      @application = application
    end

    def run
      display_menu
      choice = gets&.strip
      return if choice == 'back'

      run_cache_demo
    end

    private

    def display_menu
      puts "\n#{'-' * 40}"
      puts 'REDIS CACHE DEMO'
      puts '-' * 40
      puts 'This will run the cache demo if Redis is available.'
      puts "Press Enter to continue or 'back' to return..."
    end

    def run_cache_demo
      if File.exist?('bin/cache_demo.rb')
        system('bundle exec ruby bin/cache_demo.rb')
      else
        puts 'Cache demo script not found.'
      end
    end
  end

  class ExamplesMenu
    attr_reader :application

    def initialize(application)
      @application = application
    end

    def run
      display_menu
      choice = gets&.strip&.to_i
      return if exit_choice?(choice)

      handle_choice(choice)
    end

    private

    def display_menu
      puts "\n#{'-' * 40}"
      puts 'EXAMPLE SCENARIOS'
      puts '-' * 40
      show_scenarios
      puts "#{Constants::EXAMPLE_SCENARIOS.length + 1}. Back to main menu"
      print "Choose scenario (1-#{Constants::EXAMPLE_SCENARIOS.length + 1}): "
    end

    def show_scenarios
      Constants::EXAMPLE_SCENARIOS.each_with_index do |(_key, scenario), index|
        puts "#{index + 1}. #{scenario[:name]}"
        puts "   #{scenario[:description]}"
      end
    end

    def exit_choice?(choice)
      choice == Constants::EXAMPLE_SCENARIOS.length + 1 || choice.nil?
    end

    def handle_choice(choice)
      if valid_choice?(choice)
        run_example_scenario(choice - 1)
      else
        puts 'Invalid choice.'
      end
    end

    def valid_choice?(choice)
      choice.between?(1, Constants::EXAMPLE_SCENARIOS.length)
    end

    def run_example_scenario(index)
      scenarios = Constants::EXAMPLE_SCENARIOS.values
      scenario = scenarios[index]

      puts "\nRunning: #{scenario[:name]}"
      puts "Description: #{scenario[:description]}"
      puts '=' * 50

      scenario[:commands].each do |command|
        puts "Command: #{command}"
        application.process_command(command)
        puts '-' * 30
      end
    end
  end
end
