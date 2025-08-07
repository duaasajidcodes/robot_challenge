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
        choice = get_user_choice
        break if choice == '7'

        handle_menu_choice(choice)
      end
    end

    private

    def display_main_menu
      puts "\n#{'=' * 50}"
      puts '🤖 ROBOT CHALLENGE SIMULATOR MENU'
      puts '=' * 50
      puts "1. #{RobotChallenge::Constants::MENU_OPTIONS[:basic_commands]}"
      puts "2. #{RobotChallenge::Constants::MENU_OPTIONS[:output_formats]}"
      puts "3. #{RobotChallenge::Constants::MENU_OPTIONS[:input_sources]}"
      puts "4. #{RobotChallenge::Constants::MENU_OPTIONS[:table_sizes]}"
      puts "5. #{RobotChallenge::Constants::MENU_OPTIONS[:cache_demo]}"
      puts "6. #{RobotChallenge::Constants::MENU_OPTIONS[:examples]}"
      puts "7. #{RobotChallenge::Constants::MENU_OPTIONS[:exit]}"
      puts '=' * 50
      print 'Enter your choice (1-7): '
    end

    def get_user_choice
      gets&.strip || '7'
    end

    def handle_menu_choice(choice)
      case choice
      when '1'
        basic_commands_menu
      when '2'
        output_formats_menu
      when '3'
        input_sources_menu
      when '4'
        table_sizes_menu
      when '5'
        cache_demo_menu
      when '6'
        examples_menu
      else
        puts 'Invalid choice. Please try again.'
      end
    end

    def basic_commands_menu
      puts "\n#{'-' * 40}"
      puts 'BASIC ROBOT COMMANDS'
      puts '-' * 40
      puts "Enter commands one by one (or 'back' to return):"
      puts 'Available commands: PLACE X,Y,DIRECTION, MOVE, LEFT, RIGHT, REPORT, EXIT'

      loop do
        print '> '
        command = gets&.strip
        break if command == 'back' || command.nil?

        application.process_command(command)
      end
    end

    def output_formats_menu
      puts "\n#{'-' * 40}"
      puts 'OUTPUT FORMATS TEST'
      puts '-' * 40
      puts '1. Text format (default)'
      puts '2. JSON format'
      puts '3. XML format'
      puts '4. CSV format'
      puts '5. Quiet format (no output)'
      puts '6. Back to main menu'
      print 'Choose format (1-6): '

      choice = gets&.strip
      return if choice == '6' || choice.nil?

      format_map = {
        '1' => 'text',
        '2' => 'json',
        '3' => 'xml',
        '4' => 'csv',
        '5' => 'quiet'
      }

      format = format_map[choice]
      if format
        test_output_format(format)
      else
        puts 'Invalid choice.'
      end
    end

    def test_output_format(format)
      puts "\nTesting #{format.upcase} output format..."
      puts '=' * 40

      # Create a new application with the specified format
      test_app = Application.new(
        output_formatter: OutputFormatterFactory.create(format)
      )

      # Run a test sequence
      commands = ['PLACE 1,2,NORTH', 'MOVE', 'LEFT', 'REPORT']
      commands.each do |command|
        puts "Command: #{command}"
        test_app.process_command(command)
        puts '-' * 20
      end
    end

    def input_sources_menu
      puts "\n#{'-' * 40}"
      puts 'INPUT SOURCES TEST'
      puts '-' * 40
      puts '1. String input'
      puts '2. Array input'
      puts '3. File input (test_data/example_1.txt)'
      puts '4. Back to main menu'
      print 'Choose input source (1-4): '

      choice = gets&.strip
      return if choice == '4' || choice.nil?

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
        puts 'File test_data/example_1.txt not found.'
      end
    end

    def table_sizes_menu
      puts "\n#{'-' * 40}"
      puts 'TABLE SIZES TEST'
      puts '-' * 40
      puts '1. 5x5 (default)'
      puts '2. 10x10'
      puts '3. 3x3'
      puts '4. 8x6'
      puts '5. Back to main menu'
      print 'Choose table size (1-5): '

      choice = gets&.strip
      return if choice == '5' || choice.nil?

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

      # Create application with custom table size
      test_app = Application.new(
        table_width: width,
        table_height: height
      )

      # Test boundary conditions
      commands = [
        'PLACE 0,0,NORTH',
        'MOVE',
        'REPORT',
        "PLACE #{width - 1},#{height - 1},SOUTH",
        'MOVE',
        'REPORT'
      ]

      commands.each do |command|
        puts "Command: #{command}"
        test_app.process_command(command)
        puts '-' * 20
      end
    end

    def cache_demo_menu
      puts "\n#{'-' * 40}"
      puts 'REDIS CACHE DEMO'
      puts '-' * 40
      puts 'This will run the cache demo if Redis is available.'
      puts "Press Enter to continue or 'back' to return..."

      choice = gets&.strip
      return if choice == 'back'

      if File.exist?('bin/cache_demo.rb')
        system('bundle exec ruby bin/cache_demo.rb')
      else
        puts 'Cache demo script not found.'
      end
    end

    def examples_menu
      puts "\n#{'-' * 40}"
      puts 'EXAMPLE SCENARIOS'
      puts '-' * 40

      RobotChallenge::Constants::EXAMPLE_SCENARIOS.each_with_index do |(_key, scenario), index|
        puts "#{index + 1}. #{scenario[:name]}"
        puts "   #{scenario[:description]}"
      end
      puts "#{Constants::EXAMPLE_SCENARIOS.length + 1}. Back to main menu"

      print "Choose scenario (1-#{Constants::EXAMPLE_SCENARIOS.length + 1}): "
      choice = gets&.strip&.to_i
      return if choice == RobotChallenge::Constants::EXAMPLE_SCENARIOS.length + 1 || choice.nil?

      if choice.between?(1, RobotChallenge::Constants::EXAMPLE_SCENARIOS.length)
        run_example_scenario(choice - 1)
      else
        puts 'Invalid choice.'
      end
    end

    def run_example_scenario(index)
      scenarios = RobotChallenge::Constants::EXAMPLE_SCENARIOS.values
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
