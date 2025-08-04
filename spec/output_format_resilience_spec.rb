# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Output Format Resilience' do
  let(:robot) { create_test_robot }
  let(:table) { robot.table }

  describe 'OutputFormatterFactory' do
    describe '#create' do
      it 'creates TextOutputFormatter by default' do
        formatter = RobotChallenge::OutputFormatterFactory.create
        expect(formatter).to be_a(RobotChallenge::TextOutputFormatter)
      end

      it 'creates TextOutputFormatter for text format' do
        formatter = RobotChallenge::OutputFormatterFactory.create('text')
        expect(formatter).to be_a(RobotChallenge::TextOutputFormatter)
      end

      it 'creates JsonOutputFormatter for json format' do
        formatter = RobotChallenge::OutputFormatterFactory.create('json')
        expect(formatter).to be_a(RobotChallenge::JsonOutputFormatter)
      end

      it 'creates XmlOutputFormatter for xml format' do
        formatter = RobotChallenge::OutputFormatterFactory.create('xml')
        expect(formatter).to be_a(RobotChallenge::XmlOutputFormatter)
      end

      it 'creates CsvOutputFormatter for csv format' do
        formatter = RobotChallenge::OutputFormatterFactory.create('csv')
        expect(formatter).to be_a(RobotChallenge::CsvOutputFormatter)
      end

      it 'creates QuietOutputFormatter for quiet format' do
        formatter = RobotChallenge::OutputFormatterFactory.create('quiet')
        expect(formatter).to be_a(RobotChallenge::QuietOutputFormatter)
      end

      it 'creates QuietOutputFormatter for none format' do
        formatter = RobotChallenge::OutputFormatterFactory.create('none')
        expect(formatter).to be_a(RobotChallenge::QuietOutputFormatter)
      end

      it 'creates TextOutputFormatter for unknown format' do
        formatter = RobotChallenge::OutputFormatterFactory.create('unknown')
        expect(formatter).to be_a(RobotChallenge::TextOutputFormatter)
      end
    end

    describe '#from_environment' do
      it 'uses environment variable for format' do
        ENV['ROBOT_OUTPUT_FORMAT'] = 'json'
        formatter = RobotChallenge::OutputFormatterFactory.from_environment
        expect(formatter).to be_a(RobotChallenge::JsonOutputFormatter)
        ENV.delete('ROBOT_OUTPUT_FORMAT')
      end

      it 'defaults to text when no environment variable' do
        ENV.delete('ROBOT_OUTPUT_FORMAT')
        formatter = RobotChallenge::OutputFormatterFactory.from_environment
        expect(formatter).to be_a(RobotChallenge::TextOutputFormatter)
      end
    end
  end

  describe 'Output Formatters' do
    before do
      robot.place(RobotChallenge::Position.new(1, 2), RobotChallenge::Direction.new('NORTH'))
    end

    describe 'TextOutputFormatter' do
      let(:formatter) { RobotChallenge::TextOutputFormatter.new }

      it 'formats robot report as text' do
        output = formatter.format_report(robot)
        expect(output).to eq('1,2,NORTH')
      end

      it 'ignores errors silently' do
        output = formatter.format_error('Test error', :test_error)
        expect(output).to be_nil
      end

      it 'ignores success messages' do
        output = formatter.format_success('Test success')
        expect(output).to be_nil
      end

      it 'formats welcome message' do
        output = formatter.format_welcome_message(table, %w[NORTH SOUTH])
        expect(output).to include('Robot Challenge Simulator')
        expect(output).to include('PLACE X,Y,F')
        expect(output).to include('MOVE')
        expect(output).to include('NORTH, SOUTH')
      end

      it 'formats goodbye message' do
        output = formatter.format_goodbye_message
        expect(output).to include('Thank you for using Robot Challenge Simulator')
      end
    end

    describe 'JsonOutputFormatter' do
      let(:formatter) { RobotChallenge::JsonOutputFormatter.new }

      it 'formats robot report as JSON with correct status and type' do
        output = formatter.format_report(robot)
        parsed = JSON.parse(output)
        expect(parsed['status']).to eq('success')
        expect(parsed['type']).to eq('report')
      end

      it 'formats robot report as JSON with correct position data' do
        output = formatter.format_report(robot)
        parsed = JSON.parse(output)
        expect(parsed['data']['position']['x']).to eq(1)
        expect(parsed['data']['position']['y']).to eq(2)
      end

      it 'formats robot report as JSON with correct direction and format' do
        output = formatter.format_report(robot)
        parsed = JSON.parse(output)
        expect(parsed['data']['direction']).to eq('NORTH')
        expect(parsed['data']['formatted']).to eq('1,2,NORTH')
      end

      it 'formats errors as JSON' do
        output = formatter.format_error('Test error', :test_error)
        parsed = JSON.parse(output)
        expect(parsed['status']).to eq('error')
        expect(parsed['type']).to eq('test_error')
        expect(parsed['message']).to eq('Test error')
      end

      it 'formats success as JSON' do
        output = formatter.format_success('Test success')
        parsed = JSON.parse(output)
        expect(parsed['status']).to eq('success')
        expect(parsed['message']).to eq('Test success')
      end

      it 'formats welcome message as JSON' do
        output = formatter.format_welcome_message(table, %w[NORTH SOUTH])
        parsed = JSON.parse(output)
        expect(parsed['status']).to eq('info')
        expect(parsed['type']).to eq('welcome')
        expect(parsed['data']['application']).to eq('Robot Challenge Simulator')
      end
    end

    describe 'XmlOutputFormatter' do
      let(:formatter) { RobotChallenge::XmlOutputFormatter.new }

      it 'formats robot report as XML with correct structure' do
        output = formatter.format_report(robot)
        expect(output).to include('<?xml version="1.0" encoding="UTF-8"?>')
        expect(output).to include('<robot_report>')
        expect(output).to include('<status>success</status>')
      end

      it 'formats robot report as XML with correct position data' do
        output = formatter.format_report(robot)
        expect(output).to include('<x>1</x>')
        expect(output).to include('<y>2</y>')
        expect(output).to include('<direction>NORTH</direction>')
      end

      it 'formats errors as XML' do
        output = formatter.format_error('Test error', :test_error)
        expect(output).to include('<?xml version="1.0" encoding="UTF-8"?>')
        expect(output).to include('<robot_error>')
        expect(output).to include('<status>error</status>')
        expect(output).to include('<type>test_error</type>')
        expect(output).to include('<message>Test error</message>')
      end

      it 'formats success as XML' do
        output = formatter.format_success('Test success')
        expect(output).to include('<?xml version="1.0" encoding="UTF-8"?>')
        expect(output).to include('<robot_response>')
        expect(output).to include('<status>success</status>')
        expect(output).to include('<message>Test success</message>')
      end
    end

    describe 'CsvOutputFormatter' do
      let(:formatter) { RobotChallenge::CsvOutputFormatter.new }

      it 'formats robot report as CSV' do
        output = formatter.format_report(robot)
        expect(output).to include('x,y,direction,formatted')
        expect(output).to include('1,2,NORTH,1,2,NORTH')
      end

      it 'formats errors as CSV' do
        output = formatter.format_error('Test error', :test_error)
        expect(output).to include('status,type,message')
        expect(output).to include('error,test_error,Test error')
      end

      it 'formats success as CSV' do
        output = formatter.format_success('Test success')
        expect(output).to include('status,message')
        expect(output).to include('success,Test success')
      end
    end

    describe 'QuietOutputFormatter' do
      let(:formatter) { RobotChallenge::QuietOutputFormatter.new }

      it 'returns nil for all formats' do
        expect(formatter.format_report(robot)).to be_nil
        expect(formatter.format_error('Test error')).to be_nil
        expect(formatter.format_success('Test success')).to be_nil
        expect(formatter.format_welcome_message(table, [])).to be_nil
        expect(formatter.format_goodbye_message).to be_nil
      end
    end
  end

  describe 'Application with different output formats' do
    it 'works with text output format' do
      app = create_test_application
      app.set_output_formatter(RobotChallenge::TextOutputFormatter.new)

      output = capture_output(app) do
        app.process_commands(['PLACE 0,0,NORTH', 'MOVE', 'REPORT'])
      end
      expect(output).to include('0,1,NORTH')
    end

    it 'works with JSON output format' do
      app = create_test_application
      app.set_output_formatter(RobotChallenge::JsonOutputFormatter.new)

      output = capture_output(app) do
        app.process_commands(['PLACE 0,0,NORTH', 'MOVE', 'REPORT'])
      end
      expect(output).to include('"status":"success"')
      expect(output).to include('"type":"report"')
      expect(output).to include('"direction":"NORTH"')
    end

    it 'works with XML output format' do
      app = create_test_application
      app.set_output_formatter(RobotChallenge::XmlOutputFormatter.new)

      output = capture_output(app) do
        app.process_commands(['PLACE 0,0,NORTH', 'MOVE', 'REPORT'])
      end
      expect(output).to include('<?xml version="1.0" encoding="UTF-8"?>')
      expect(output).to include('<robot_report>')
      expect(output).to include('<direction>NORTH</direction>')
    end

    it 'works with CSV output format' do
      app = create_test_application
      app.set_output_formatter(RobotChallenge::CsvOutputFormatter.new)

      output = capture_output(app) do
        app.process_commands(['PLACE 0,0,NORTH', 'MOVE', 'REPORT'])
      end
      expect(output).to include('x,y,direction,formatted')
      expect(output).to include('0,1,NORTH')
    end

    it 'works with quiet output format' do
      app = create_test_application
      app.set_output_formatter(RobotChallenge::QuietOutputFormatter.new)

      output = capture_output(app) do
        app.process_commands(['PLACE 0,0,NORTH', 'MOVE', 'REPORT'])
      end
      expect(output).to be_empty
    end
  end

  describe 'Custom output formatter' do
    # Custom formatter that adds timestamps
    class TimestampOutputFormatter < RobotChallenge::OutputFormatter
      def format_report(robot)
        timestamp = Time.now.strftime('%Y-%m-%d %H:%M:%S')
        "[#{timestamp}] #{robot.report}"
      end

      def format_error(message, _error_type = :general_error)
        timestamp = Time.now.strftime('%Y-%m-%d %H:%M:%S')
        "[#{timestamp}] ERROR: #{message}"
      end

      def format_success(message = nil)
        timestamp = Time.now.strftime('%Y-%m-%d %H:%M:%S')
        "[#{timestamp}] SUCCESS: #{message}"
      end

      def format_welcome_message(_table, _valid_directions)
        timestamp = Time.now.strftime('%Y-%m-%d %H:%M:%S')
        "[#{timestamp}] Welcome to Robot Challenge Simulator"
      end

      def format_goodbye_message
        timestamp = Time.now.strftime('%Y-%m-%d %H:%M:%S')
        "[#{timestamp}] Goodbye!"
      end
    end

    it 'allows custom output formatter implementation' do
      app = create_test_application
      app.set_output_formatter(TimestampOutputFormatter.new)

      output = capture_output(app) do
        app.process_commands(['PLACE 0,0,NORTH', 'MOVE', 'REPORT'])
      end
      expect(output).to match(/\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\] 0,1,NORTH/)
    end
  end

  private

  def capture_output(app)
    output = []
    # Create a custom output handler that captures messages
    output_handler = ->(message) { output << message if message }
    app.set_output_handler(output_handler)
    yield
    output.join("\n")
  end
end
