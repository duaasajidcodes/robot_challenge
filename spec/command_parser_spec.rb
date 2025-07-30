# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RobotChallenge::CommandParser do
  describe '.parse' do
    context 'PLACE command' do
      it 'parses valid PLACE command' do
        result = described_class.parse('PLACE 1,2,NORTH')

        expect(result).to eq({
                               command: :place,
                               x: 1,
                               y: 2,
                               direction: 'NORTH'
                             })
      end

      it 'handles lowercase input' do
        result = described_class.parse('place 3,4,south')

        expect(result).to eq({
                               command: :place,
                               x: 3,
                               y: 4,
                               direction: 'SOUTH'
                             })
      end

      it 'handles mixed case input' do
        result = described_class.parse('PlAcE 0,0,WeSt')

        expect(result).to eq({
                               command: :place,
                               x: 0,
                               y: 0,
                               direction: 'WEST'
                             })
      end

      it 'handles extra whitespace' do
        result = described_class.parse('  PLACE   1 , 2 , EAST  ')

        expect(result).to eq({
                               command: :place,
                               x: 1,
                               y: 2,
                               direction: 'EAST'
                             })
      end

      it 'handles negative coordinates' do
        result = described_class.parse('PLACE -1,-2,NORTH')

        expect(result).to eq({
                               command: :place,
                               x: -1,
                               y: -2,
                               direction: 'NORTH'
                             })
      end

      it 'returns nil for PLACE without arguments' do
        result = described_class.parse('PLACE')
        expect(result).to be_nil
      end

      it 'returns nil for PLACE with insufficient arguments' do
        result = described_class.parse('PLACE 1,2')
        expect(result).to be_nil
      end

      it 'returns nil for PLACE with too many arguments' do
        result = described_class.parse('PLACE 1,2,NORTH,EXTRA')
        expect(result).to be_nil
      end

      it 'returns nil for PLACE with invalid coordinates' do
        result = described_class.parse('PLACE abc,def,NORTH')
        expect(result).to be_nil
      end

      it 'returns nil for PLACE with invalid direction' do
        result = described_class.parse('PLACE 1,2,INVALID')
        expect(result).to be_nil
      end

      it 'returns nil for PLACE with missing commas' do
        result = described_class.parse('PLACE 1 2 NORTH')
        expect(result).to be_nil
      end

      it 'handles zero coordinates' do
        result = described_class.parse('PLACE 0,0,NORTH')

        expect(result).to eq({
                               command: :place,
                               x: 0,
                               y: 0,
                               direction: 'NORTH'
                             })
      end
    end

    context 'MOVE command' do
      it 'parses MOVE command' do
        result = described_class.parse('MOVE')
        expect(result).to eq({ command: :move })
      end

      it 'handles lowercase' do
        result = described_class.parse('move')
        expect(result).to eq({ command: :move })
      end

      it 'handles extra whitespace' do
        result = described_class.parse('  MOVE  ')
        expect(result).to eq({ command: :move })
      end
    end

    context 'LEFT command' do
      it 'parses LEFT command' do
        result = described_class.parse('LEFT')
        expect(result).to eq({ command: :left })
      end

      it 'handles lowercase' do
        result = described_class.parse('left')
        expect(result).to eq({ command: :left })
      end
    end

    context 'RIGHT command' do
      it 'parses RIGHT command' do
        result = described_class.parse('RIGHT')
        expect(result).to eq({ command: :right })
      end

      it 'handles lowercase' do
        result = described_class.parse('right')
        expect(result).to eq({ command: :right })
      end
    end

    context 'REPORT command' do
      it 'parses REPORT command' do
        result = described_class.parse('REPORT')
        expect(result).to eq({ command: :report })
      end

      it 'handles lowercase' do
        result = described_class.parse('report')
        expect(result).to eq({ command: :report })
      end
    end

    context 'EXIT command' do
      it 'parses EXIT command' do
        result = described_class.parse('EXIT')
        expect(result).to eq({ command: :exit })
      end

      it 'handles lowercase' do
        result = described_class.parse('exit')
        expect(result).to eq({ command: :exit })
      end
    end

    context 'QUIT command' do
      it 'parses QUIT command' do
        result = described_class.parse('QUIT')
        expect(result).to eq({ command: :quit })
      end

      it 'handles lowercase' do
        result = described_class.parse('quit')
        expect(result).to eq({ command: :quit })
      end
    end

    context 'invalid inputs' do
      it 'returns nil for nil input' do
        result = described_class.parse(nil)
        expect(result).to be_nil
      end

      it 'returns nil for empty string' do
        result = described_class.parse('')
        expect(result).to be_nil
      end

      it 'returns nil for whitespace only' do
        result = described_class.parse('   ')
        expect(result).to be_nil
      end

      it 'returns nil for invalid command' do
        result = described_class.parse('INVALID')
        expect(result).to be_nil
      end

      it 'returns nil for commands with extra arguments' do
        result = described_class.parse('MOVE EXTRA')
        expect(result).to be_nil
      end

      it 'returns nil for malformed commands' do
        result = described_class.parse('PLACE1,2,NORTH')
        expect(result).to be_nil
      end
    end

    context 'edge cases' do
      it 'handles very large coordinates' do
        result = described_class.parse('PLACE 999999,888888,SOUTH')

        expect(result).to eq({
                               command: :place,
                               x: 999_999,
                               y: 888_888,
                               direction: 'SOUTH'
                             })
      end

      it 'handles commands with tabs and mixed whitespace' do
        result = described_class.parse("PLACE\t1,\t2,\tNORTH")

        expect(result).to eq({
                               command: :place,
                               x: 1,
                               y: 2,
                               direction: 'NORTH'
                             })
      end

      it 'handles all valid directions' do
        %w[NORTH EAST SOUTH WEST].each do |direction|
          result = described_class.parse("PLACE 0,0,#{direction}")
          expect(result[:direction]).to eq(direction)
        end
      end
    end
  end
end
