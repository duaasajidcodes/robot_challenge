# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Input Format Resilience' do
  let(:app) { create_test_application }

  describe 'PLACE command format variations' do
    it 'handles standard comma-separated format' do
      output = capture_output do
        app.process_commands(['PLACE 1,2,NORTH', 'REPORT'])
      end
      expect(output).to include('1,2,NORTH')
    end

    it 'handles space-separated format' do
      output = capture_output do
        app.process_commands(['PLACE 1 2 NORTH', 'REPORT'])
      end
      expect(output).to include('1,2,NORTH')
    end

    it 'handles mixed whitespace format' do
      output = capture_output do
        app.process_commands(['  PLACE  1 , 2 , NORTH  ', 'REPORT'])
      end
      expect(output).to include('1,2,NORTH')
    end

    it 'handles case insensitive format' do
      output = capture_output do
        app.process_commands(['place 1,2,north', 'REPORT'])
      end
      expect(output).to include('1,2,NORTH')
    end

    it 'handles mixed case format' do
      output = capture_output do
        app.process_commands(['Place 1,2,North', 'REPORT'])
      end
      expect(output).to include('1,2,NORTH')
    end
  end

  describe 'Simple command format variations' do
    before do
      app.process_command('PLACE 0,0,NORTH')
    end

    it 'handles standard format' do
      output = capture_output do
        app.process_commands(%w[MOVE REPORT])
      end
      expect(output).to include('0,1,NORTH')
    end

    it 'handles case insensitive format' do
      output = capture_output do
        app.process_commands(%w[move report])
      end
      expect(output).to include('0,1,NORTH')
    end

    it 'handles mixed case format' do
      output = capture_output do
        app.process_commands(%w[Move Report])
      end
      expect(output).to include('0,1,NORTH')
    end

    it 'handles extra whitespace' do
      output = capture_output do
        app.process_commands(['  MOVE  ', '  REPORT  '])
      end
      expect(output).to include('0,1,NORTH')
    end
  end

  describe 'Invalid input handling' do
    it 'ignores invalid commands gracefully' do
      output = capture_output do
        app.process_commands(['INVALID', 'PLACE 1,2,NORTH', 'REPORT'])
      end
      expect(output).to include('1,2,NORTH')
    end

    it 'ignores invalid PLACE commands gracefully' do
      output = capture_output do
        app.process_commands(['PLACE 1,2,INVALID', 'PLACE 1,2,NORTH', 'REPORT'])
      end
      expect(output).to include('1,2,NORTH')
    end

    it 'ignores incomplete PLACE commands gracefully' do
      output = capture_output do
        app.process_commands(['PLACE 1,2', 'PLACE 1,2,NORTH', 'REPORT'])
      end
      expect(output).to include('1,2,NORTH')
    end

    it 'ignores empty lines gracefully' do
      output = capture_output do
        app.process_commands(['', 'PLACE 1,2,NORTH', '', 'REPORT'])
      end
      expect(output).to include('1,2,NORTH')
    end

    it 'ignores whitespace-only lines gracefully' do
      output = capture_output do
        app.process_commands(['   ', 'PLACE 1,2,NORTH', '   ', 'REPORT'])
      end
      expect(output).to include('1,2,NORTH')
    end
  end

  describe 'Complex format resilience' do
    it 'handles mixed valid and invalid commands' do
      commands = [
        'INVALID_COMMAND',
        'PLACE 1,2,INVALID_DIRECTION',
        'PLACE 1,2',
        'PLACE',
        'PLACE 0,0,NORTH',
        'MOVE',
        'LEFT',
        'REPORT'
      ]

      output = capture_output do
        app.process_commands(commands)
      end
      expect(output).to include('0,1,WEST')
    end

    it 'handles various whitespace patterns' do
      commands = [
        '  PLACE  1 , 2 , NORTH  ',
        '  MOVE  ',
        '  LEFT  ',
        'REPORT'
      ]

      output = capture_output do
        app.process_commands(commands)
      end
      expect(output).to include('1,3,WEST')
    end
  end

  private

  def capture_output
    output = []
    app.set_output_handler(->(message) { output << message })
    yield
    output.join("\n")
  end
end
