# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RobotChallenge::Direction do
  describe '#initialize' do
    it 'creates direction with valid direction name' do
      direction = described_class.new('NORTH')
      expect(direction.name).to eq('NORTH')
    end

    it 'normalizes lowercase input' do
      direction = described_class.new('north')
      expect(direction.name).to eq('NORTH')
    end

    it 'normalizes mixed case input' do
      direction = described_class.new('NoRtH')
      expect(direction.name).to eq('NORTH')
    end

    it 'accepts symbol input' do
      direction = described_class.new(:south)
      expect(direction.name).to eq('SOUTH')
    end

    it 'raises error for invalid direction' do
      expect { described_class.new('INVALID') }
        .to raise_error(RobotChallenge::InvalidDirectionError, /Invalid direction: INVALID/)
    end

    it 'raises error for nil input' do
      expect { described_class.new(nil) }
        .to raise_error(RobotChallenge::InvalidDirectionError)
    end

    it 'raises error for empty string' do
      expect { described_class.new('') }
        .to raise_error(RobotChallenge::InvalidDirectionError)
    end
  end

  describe 'equality and hashing' do
    it 'considers directions with same name equal' do
      direction1 = described_class.new('NORTH')
      direction2 = described_class.new('north')
      expect(direction1).to eq(direction2)
    end

    it 'considers directions with different names unequal' do
      direction1 = described_class.new('NORTH')
      direction2 = described_class.new('SOUTH')
      expect(direction1).not_to eq(direction2)
    end

    it 'can be used as hash keys' do
      direction1 = described_class.new('NORTH')
      direction2 = described_class.new('north')
      hash = { direction1 => 'value' }
      expect(hash[direction2]).to eq('value')
    end
  end

  describe '#turn_left' do
    it 'rotates NORTH to WEST' do
      direction = described_class.new('NORTH')
      result = direction.turn_left
      expect(result.name).to eq('WEST')
    end

    it 'rotates WEST to SOUTH' do
      direction = described_class.new('WEST')
      result = direction.turn_left
      expect(result.name).to eq('SOUTH')
    end

    it 'rotates SOUTH to EAST' do
      direction = described_class.new('SOUTH')
      result = direction.turn_left
      expect(result.name).to eq('EAST')
    end

    it 'rotates EAST to NORTH' do
      direction = described_class.new('EAST')
      result = direction.turn_left
      expect(result.name).to eq('NORTH')
    end

    it 'returns new Direction object' do
      direction = described_class.new('NORTH')
      result = direction.turn_left
      expect(result).not_to be(direction)
      expect(direction.name).to eq('NORTH') # Original unchanged
    end
  end

  describe '#turn_right' do
    it 'rotates NORTH to EAST' do
      direction = described_class.new('NORTH')
      result = direction.turn_right
      expect(result.name).to eq('EAST')
    end

    it 'rotates EAST to SOUTH' do
      direction = described_class.new('EAST')
      result = direction.turn_right
      expect(result.name).to eq('SOUTH')
    end

    it 'rotates SOUTH to WEST' do
      direction = described_class.new('SOUTH')
      result = direction.turn_right
      expect(result.name).to eq('WEST')
    end

    it 'rotates WEST to NORTH' do
      direction = described_class.new('WEST')
      result = direction.turn_right
      expect(result.name).to eq('NORTH')
    end

    it 'returns new Direction object' do
      direction = described_class.new('NORTH')
      result = direction.turn_right
      expect(result).not_to be(direction)
      expect(direction.name).to eq('NORTH') # Original unchanged
    end
  end

  describe '#delta' do
    it 'returns correct delta for NORTH' do
      direction = described_class.new('NORTH')
      expect(direction.delta).to eq([0, 1])
    end

    it 'returns correct delta for EAST' do
      direction = described_class.new('EAST')
      expect(direction.delta).to eq([1, 0])
    end

    it 'returns correct delta for SOUTH' do
      direction = described_class.new('SOUTH')
      expect(direction.delta).to eq([0, -1])
    end

    it 'returns correct delta for WEST' do
      direction = described_class.new('WEST')
      expect(direction.delta).to eq([-1, 0])
    end
  end

  describe 'class methods' do
    describe '.north' do
      it 'returns NORTH direction' do
        expect(described_class.north.name).to eq('NORTH')
      end

      it 'returns same instance on multiple calls' do
        expect(described_class.north).to be(described_class.north)
      end
    end

    describe '.east' do
      it 'returns EAST direction' do
        expect(described_class.east.name).to eq('EAST')
      end
    end

    describe '.south' do
      it 'returns SOUTH direction' do
        expect(described_class.south.name).to eq('SOUTH')
      end
    end

    describe '.west' do
      it 'returns WEST direction' do
        expect(described_class.west.name).to eq('WEST')
      end
    end

    describe '.valid_directions' do
      it 'returns array of valid direction names' do
        directions = described_class.valid_directions
        expect(directions).to eq(%w[NORTH EAST SOUTH WEST])
      end

      it 'returns a copy to prevent modification' do
        directions = described_class.valid_directions
        directions << 'INVALID'
        expect(described_class.valid_directions).to eq(%w[NORTH EAST SOUTH WEST])
      end
    end
  end

  describe '#to_s' do
    it 'returns direction name' do
      direction = described_class.new('NORTH')
      expect(direction.to_s).to eq('NORTH')
    end
  end

  describe 'full rotation tests' do
    it 'returns to original direction after 4 left turns' do
      direction = described_class.new('NORTH')
      result = direction.turn_left.turn_left.turn_left.turn_left
      expect(result).to eq(direction)
    end

    it 'returns to original direction after 4 right turns' do
      direction = described_class.new('EAST')
      result = direction.turn_right.turn_right.turn_right.turn_right
      expect(result).to eq(direction)
    end

    it 'left turn followed by right turn returns to original' do
      direction = described_class.new('SOUTH')
      result = direction.turn_left.turn_right
      expect(result).to eq(direction)
    end
  end
end
