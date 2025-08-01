# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Input Source Resilience' do
  describe 'InputSourceFactory' do
    describe '#create' do
      it 'creates StdinInputSource from IO object' do
        source = RobotChallenge::InputSourceFactory.create($stdin)
        expect(source).to be_a(RobotChallenge::StdinInputSource)
      end

      it 'creates FileInputSource from file path' do
        source = RobotChallenge::InputSourceFactory.create('test_data/example_1.txt')
        expect(source).to be_a(RobotChallenge::FileInputSource)
      end

      it 'creates StringInputSource from string' do
        source = RobotChallenge::InputSourceFactory.create('PLACE 0,0,NORTH')
        expect(source).to be_a(RobotChallenge::StringInputSource)
      end

      it 'creates ArrayInputSource from array' do
        source = RobotChallenge::InputSourceFactory.create(['PLACE 0,0,NORTH', 'MOVE'])
        expect(source).to be_a(RobotChallenge::ArrayInputSource)
      end

      it 'returns existing InputSource as-is' do
        original = RobotChallenge::StringInputSource.new('test')
        source = RobotChallenge::InputSourceFactory.create(original)
        expect(source).to eq(original)
      end

      it 'raises error for unsupported type' do
        expect do
          RobotChallenge::InputSourceFactory.create(123)
        end.to raise_error(ArgumentError, /Unsupported input source type/)
      end
    end

    describe 'factory methods' do
      it 'creates from file path' do
        source = RobotChallenge::InputSourceFactory.from_file_path('test_data/example_1.txt')
        expect(source).to be_a(RobotChallenge::FileInputSource)
      end

      it 'creates from string' do
        source = RobotChallenge::InputSourceFactory.from_string('PLACE 0,0,NORTH')
        expect(source).to be_a(RobotChallenge::StringInputSource)
      end

      it 'creates from array' do
        source = RobotChallenge::InputSourceFactory.from_array(['PLACE 0,0,NORTH'])
        expect(source).to be_a(RobotChallenge::ArrayInputSource)
      end

      it 'creates from stdin' do
        source = RobotChallenge::InputSourceFactory.from_stdin($stdin)
        expect(source).to be_a(RobotChallenge::StdinInputSource)
      end
    end
  end

  describe 'Input Sources' do
    describe 'StdinInputSource' do
      it 'reads from IO object' do
        io = StringIO.new("PLACE 0,0,NORTH\nMOVE\nREPORT")
        source = RobotChallenge::StdinInputSource.new(io)

        lines = []
        source.each_line { |line| lines << line.chomp }

        expect(lines).to eq(['PLACE 0,0,NORTH', 'MOVE', 'REPORT'])
      end

      it 'detects TTY correctly' do
        source = RobotChallenge::StdinInputSource.new($stdin)
        expect(source.tty?).to eq($stdin.tty?)
      end
    end

    describe 'FileInputSource' do
      it 'reads from file' do
        source = RobotChallenge::FileInputSource.new('test_data/example_1.txt')

        lines = []
        source.each_line { |line| lines << line.chomp }

        expect(lines).to include('PLACE 0,0,NORTH')
        expect(lines).to include('MOVE')
        expect(lines).to include('REPORT')
      end

      it 'raises error for non-existent file' do
        source = RobotChallenge::FileInputSource.new('non_existent_file.txt')
        expect { source.each_line { |line| } }.to raise_error(ArgumentError, /File not found/)
      end
    end

    describe 'StringInputSource' do
      it 'reads from string' do
        source = RobotChallenge::StringInputSource.new("PLACE 0,0,NORTH\nMOVE\nREPORT")

        lines = []
        source.each_line { |line| lines << line.chomp }

        expect(lines).to eq(['PLACE 0,0,NORTH', 'MOVE', 'REPORT'])
      end
    end

    describe 'ArrayInputSource' do
      it 'reads from array' do
        source = RobotChallenge::ArrayInputSource.new(['PLACE 0,0,NORTH', 'MOVE', 'REPORT'])

        lines = []
        source.each_line { |line| lines << line }

        expect(lines).to eq(['PLACE 0,0,NORTH', 'MOVE', 'REPORT'])
      end
    end
  end

  describe 'Application with different input sources' do
    it 'works with file input source' do
      app = create_test_application
      app.set_input_source(RobotChallenge::InputSourceFactory.from_file_path('test_data/example_1.txt'))

      output = capture_output(app) { app.run }
      expect(output).to include('0,1,NORTH')
    end

    it 'works with string input source' do
      app = create_test_application
      app.set_input_source(RobotChallenge::InputSourceFactory.from_string("PLACE 0,0,NORTH\nMOVE\nREPORT"))

      output = capture_output(app) { app.run }
      expect(output).to include('0,1,NORTH')
    end

    it 'works with array input source' do
      app = create_test_application
      app.set_input_source(RobotChallenge::InputSourceFactory.from_array(['PLACE 0,0,NORTH', 'MOVE', 'REPORT']))

      output = capture_output(app) { app.run }
      expect(output).to include('0,1,NORTH')
    end

    it 'works with stdin input source' do
      app = create_test_application
      app.set_input_source(RobotChallenge::InputSourceFactory.from_stdin(StringIO.new("PLACE 0,0,NORTH\nMOVE\nREPORT")))

      output = capture_output(app) { app.run }
      expect(output).to include('0,1,NORTH')
    end
  end

  describe 'Custom input source' do
    it 'allows custom input source implementation' do
      # Custom input source that provides commands in a specific order
      class CustomInputSource < RobotChallenge::InputSource
        def initialize(commands)
          @commands = commands
        end

        def each_line(&block)
          @commands.each(&block)
        end
      end

      app = create_test_application
      app.set_input_source(CustomInputSource.new(['PLACE 0,0,NORTH', 'MOVE', 'REPORT']))

      output = capture_output(app) { app.run }
      expect(output).to include('0,1,NORTH')
    end
  end

  private

  def capture_output(app)
    output = []
    app.set_output_handler(->(message) { output << message })
    yield
    output.join("\n")
  end
end
