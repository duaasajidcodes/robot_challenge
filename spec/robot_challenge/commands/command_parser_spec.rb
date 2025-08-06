# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RobotChallenge::Commands::CommandParser do
  describe 'CommandParser (base class)' do
    let(:parser) { described_class.new }

    describe '#parse' do
      it 'raises NotImplementedError when parse is not implemented' do
        expect { parser.parse('test') }.to raise_error(NotImplementedError, 'Subclasses must implement parse method')
      end
    end

    describe '#command_name' do
      it 'raises NotImplementedError when command_name is not implemented' do
        expect do
          parser.command_name
        end.to raise_error(NotImplementedError, 'Subclasses must implement command_name method')
      end
    end

    describe '#normalize_command' do
      it 'normalizes command string to uppercase without spaces' do
        expect(parser.send(:normalize_command, '  test  ')).to eq('TEST')
      end

      it 'returns empty string for nil input to normalize_command' do
        expect(parser.send(:normalize_command, nil)).to eq('')
      end

      it 'returns empty string for empty input to normalize_command' do
        expect(parser.send(:normalize_command, '')).to eq('')
      end
    end

    describe '#extract_parameters' do
      it 'extracts parameters from command string' do
        expect(parser.send(:extract_parameters, 'COMMAND param1 param2')).to eq('param1 param2')
      end

      it 'returns command itself when no parameters' do
        expect(parser.send(:extract_parameters, 'COMMAND')).to eq('COMMAND')
      end

      it 'returns empty string when input is nil for extract_parameters' do
        expect(parser.send(:extract_parameters, nil)).to eq('')
      end

      it 'returns empty string when input is empty for extract_parameters' do
        expect(parser.send(:extract_parameters, '')).to eq('')
      end
    end
  end

  describe RobotChallenge::Commands::SimpleCommandParser do
    let(:parser) { described_class.new('MOVE') }

    describe '#initialize' do
      it 'uppercases string command name' do
        parser = described_class.new('move')
        expect(parser.command_name).to eq('MOVE')
      end

      it 'uppercases symbol command name' do
        parser = described_class.new(:move)
        expect(parser.command_name).to eq('MOVE')
      end
    end

    describe '#command_name' do
      it 'returns the normalized command name' do
        expect(parser.command_name).to eq('MOVE')
      end
    end

    describe '#parse' do
      it 'parses exact match as empty hash' do
        expect(parser.parse('MOVE')).to eq({})
      end

      it 'parses case-insensitive match as empty hash' do
        expect(parser.parse('move')).to eq({})
      end

      it 'parses match with whitespace as empty hash' do
        expect(parser.parse('  MOVE  ')).to eq({})
      end

      it 'returns nil for unrelated command in SimpleCommandParser' do
        expect(parser.parse('LEFT')).to be_nil
      end

      it 'returns nil for partial match in SimpleCommandParser' do
        expect(parser.parse('MOVEMENT')).to be_nil
      end

      it 'returns nil for empty input in SimpleCommandParser' do
        expect(parser.parse('')).to be_nil
      end

      it 'returns nil for nil input in SimpleCommandParser' do
        expect(parser.parse(nil)).to be_nil
      end
    end
  end

  describe RobotChallenge::Commands::PlaceCommandParser do
    let(:parser) { described_class.new }

    describe '#command_name' do
      it 'returns PLACE as the command name' do
        expect(parser.command_name).to eq('PLACE')
      end
    end

    describe '#parse' do
      context 'with valid PLACE commands' do
        it 'parses comma-separated PLACE command' do
          result = parser.parse('PLACE 0,0,NORTH')
          expect(result).to eq({ x: 0, y: 0, direction: 'NORTH' })
        end

        it 'parses space-separated PLACE command' do
          result = parser.parse('PLACE 1 2 EAST')
          expect(result).to eq({ x: 1, y: 2, direction: 'EAST' })
        end

        it 'parses mixed format PLACE command' do
          result = parser.parse('PLACE 3, 4 SOUTH')
          expect(result).to eq({ x: 3, y: 4, direction: 'SOUTH' })
        end

        it 'parses PLACE command with parentheses' do
          result = parser.parse('PLACE (5,6,WEST)')
          expect(result).to eq({ x: 5, y: 6, direction: 'WEST' })
        end

        it 'parses lowercase direction in PLACE command' do
          result = parser.parse('PLACE 0,0,north')
          expect(result).to eq({ x: 0, y: 0, direction: 'NORTH' })
        end

        it 'parses PLACE command with extra whitespace' do
          result = parser.parse('PLACE  7 , 8 , WEST  ')
          expect(result).to eq({ x: 7, y: 8, direction: 'WEST' })
        end
      end

      context 'with invalid PLACE commands' do
        it 'returns nil for unrelated command in PLACE parser' do
          expect(parser.parse('MOVE')).to be_nil
        end

        it 'returns nil for PLACE with no parameters' do
          expect(parser.parse('PLACE')).to be_nil
        end

        it 'returns nil for PLACE with too few parameters' do
          expect(parser.parse('PLACE 0,0')).to be_nil
        end

        it 'returns nil for PLACE with too many parameters' do
          expect(parser.parse('PLACE 0,0,NORTH,EXTRA')).to be_nil
        end

        it 'returns nil for PLACE with negative coordinates' do
          expect(parser.parse('PLACE -1,0,NORTH')).to be_nil
        end

        it 'returns nil for PLACE with invalid direction' do
          expect(parser.parse('PLACE 0,0,INVALID')).to be_nil
        end

        it 'returns PLACE with invalid coordinates converted to 0' do
          result = parser.parse('PLACE a,b,NORTH')
          expect(result).to eq({ x: 0, y: 0, direction: 'NORTH' })
        end

        it 'returns nil for empty input in PLACE command' do
          expect(parser.parse('')).to be_nil
        end

        it 'returns nil for nil input in PLACE command' do
          expect(parser.parse(nil)).to be_nil
        end

        it 'returns nil when parse_parameters raises an error' do
          allow(parser).to receive(:parse_parameters).and_raise(StandardError, 'Parse error')
          expect(parser.parse('PLACE 0,0,NORTH')).to be_nil
        end
      end
    end

    describe '#parse_parameters' do
      it 'parses comma-separated PLACE parameters' do
        result = parser.send(:parse_parameters, '0,0,NORTH')
        expect(result).to eq({ x: 0, y: 0, direction: 'NORTH' })
      end

      it 'parses space-separated PLACE parameters' do
        result = parser.send(:parse_parameters, '1 2 EAST')
        expect(result).to eq({ x: 1, y: 2, direction: 'EAST' })
      end

      it 'parses PLACE parameters with mixed separators' do
        result = parser.send(:parse_parameters, '3, 4 SOUTH')
        expect(result).to eq({ x: 3, y: 4, direction: 'SOUTH' })
      end

      it 'removes parentheses from PLACE parameters' do
        result = parser.send(:parse_parameters, '(5,6,WEST)')
        expect(result).to eq({ x: 5, y: 6, direction: 'WEST' })
      end

      it 'returns nil for insufficient PLACE parameters' do
        expect(parser.send(:parse_parameters, '0,0')).to be_nil
      end

      it 'returns nil for too many PLACE parameters' do
        expect(parser.send(:parse_parameters, '0,0,NORTH,EXTRA')).to be_nil
      end
    end

    describe '#validate_and_create_params' do
      it 'creates PLACE parameters with basic coordinates' do
        result = parser.send(:validate_and_create_params, '1', '1', 'NORTH')
        expect(result).to eq({ x: 1, y: 1, direction: 'NORTH' })
      end

      it 'converts PLACE coordinates to integers' do
        result = parser.send(:validate_and_create_params, '1', '2', 'EAST')
        expect(result).to eq({ x: 1, y: 2, direction: 'EAST' })
      end

      it 'normalizes direction to uppercase in PLACE command' do
        result = parser.send(:validate_and_create_params, '0', '0', 'north')
        expect(result).to eq({ x: 0, y: 0, direction: 'NORTH' })
      end

      it 'returns nil for negative x in PLACE params' do
        expect(parser.send(:validate_and_create_params, '-1', '0', 'NORTH')).to be_nil
      end

      it 'returns nil for negative y in PLACE params' do
        expect(parser.send(:validate_and_create_params, '0', '-1', 'NORTH')).to be_nil
      end

      it 'returns nil for invalid direction in PLACE params' do
        expect(parser.send(:validate_and_create_params, '0', '0', 'INVALID')).to be_nil
      end

      it 'validates PLACE zero coordinates as acceptable' do
        result = parser.send(:validate_and_create_params, '0', '0', 'SOUTH')
        expect(result).to eq({ x: 0, y: 0, direction: 'SOUTH' })
      end

      it 'validates all directions in PLACE command' do
        %w[NORTH EAST SOUTH WEST].each do |direction|
          result = parser.send(:validate_and_create_params, '1', '1', direction)
          expect(result).to eq({ x: 1, y: 1, direction: direction })
        end
      end
    end
  end

  describe RobotChallenge::Commands::FlexibleCommandParser do
    let(:parser) { described_class.new('MOVE') }

    describe '#initialize' do
      it 'sets command name to uppercase in FlexibleCommandParser' do
        parser = described_class.new('move')
        expect(parser.command_name).to eq('MOVE')
      end

      it 'handles symbol input in FlexibleCommandParser' do
        parser = described_class.new(:move)
        expect(parser.command_name).to eq('MOVE')
      end
    end

    describe '#command_name' do
      it 'returns the command name in FlexibleCommandParser' do
        expect(parser.command_name).to eq('MOVE')
      end
    end

    describe '#parse' do
      it 'parses exact match as empty hash in FlexibleCommandParser' do
        expect(parser.parse('MOVE')).to eq({})
      end

      it 'parses case-insensitive match in FlexibleCommandParser' do
        expect(parser.parse('move')).to eq({})
      end

      it 'parses whitespace padded input in FlexibleCommandParser' do
        expect(parser.parse('  MOVE  ')).to eq({})
      end

      it 'returns nil for unrelated input in FlexibleCommandParser' do
        expect(parser.parse('LEFT')).to be_nil
      end

      it 'returns nil for partial match in FlexibleCommandParser' do
        expect(parser.parse('MOVEMENT')).to be_nil
      end

      it 'returns nil for empty input in FlexibleCommandParser' do
        expect(parser.parse('')).to be_nil
      end

      it 'returns nil for nil input in FlexibleCommandParser' do
        expect(parser.parse(nil)).to be_nil
      end
    end
  end
end
