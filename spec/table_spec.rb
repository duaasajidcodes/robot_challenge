# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RobotChallenge::Table do
  let(:table) { described_class.new }

  describe '#initialize' do
    it 'creates table with default 5x5 dimensions' do
      expect(table.width).to eq(5)
      expect(table.height).to eq(5)
    end

    it 'creates table with custom dimensions' do
      custom_table = described_class.new(10, 8)
      expect(custom_table.width).to eq(10)
      expect(custom_table.height).to eq(8)
    end

    it 'handles single unit table' do
      tiny_table = described_class.new(1, 1)
      expect(tiny_table.width).to eq(1)
      expect(tiny_table.height).to eq(1)
    end
  end

  describe '#valid_position?' do
    context 'with default 5x5 table' do
      it 'returns true for valid corner positions' do
        expect(table.valid_position?(RobotChallenge::Position.new(0, 0))).to be true
        expect(table.valid_position?(RobotChallenge::Position.new(4, 4))).to be true
        expect(table.valid_position?(RobotChallenge::Position.new(0, 4))).to be true
        expect(table.valid_position?(RobotChallenge::Position.new(4, 0))).to be true
      end

      it 'returns true for valid center positions' do
        expect(table.valid_position?(RobotChallenge::Position.new(2, 2))).to be true
        expect(table.valid_position?(RobotChallenge::Position.new(1, 3))).to be true
      end

      it 'returns false for positions outside width boundary' do
        expect(table.valid_position?(RobotChallenge::Position.new(5, 0))).to be false
        expect(table.valid_position?(RobotChallenge::Position.new(-1, 0))).to be false
        expect(table.valid_position?(RobotChallenge::Position.new(10, 2))).to be false
      end

      it 'returns false for positions outside height boundary' do
        expect(table.valid_position?(RobotChallenge::Position.new(0, 5))).to be false
        expect(table.valid_position?(RobotChallenge::Position.new(0, -1))).to be false
        expect(table.valid_position?(RobotChallenge::Position.new(2, 10))).to be false
      end

      it 'returns false for positions outside both boundaries' do
        expect(table.valid_position?(RobotChallenge::Position.new(-1, -1))).to be false
        expect(table.valid_position?(RobotChallenge::Position.new(5, 5))).to be false
        expect(table.valid_position?(RobotChallenge::Position.new(10, 10))).to be false
      end
    end

    context 'with custom dimensions' do
      let(:custom_table) { described_class.new(3, 2) }

      it 'validates boundaries correctly for custom table' do
        expect(custom_table.valid_position?(RobotChallenge::Position.new(0, 0))).to be true
        expect(custom_table.valid_position?(RobotChallenge::Position.new(2, 1))).to be true
        expect(custom_table.valid_position?(RobotChallenge::Position.new(3, 0))).to be false
        expect(custom_table.valid_position?(RobotChallenge::Position.new(0, 2))).to be false
      end
    end

    it 'returns false for non-Position objects' do
      expect(table.valid_position?('0,0')).to be false
      expect(table.valid_position?(nil)).to be false
      expect(table.valid_position?([0, 0])).to be false
    end
  end

  describe '#all_positions' do
    it 'returns all valid positions for default table' do
      positions = table.all_positions
      expect(positions.length).to eq(25)
      expect(positions).to include(RobotChallenge::Position.new(0, 0))
      expect(positions).to include(RobotChallenge::Position.new(4, 4))
      expect(positions).to include(RobotChallenge::Position.new(2, 2))
    end

    it 'returns correct positions for custom table' do
      custom_table = described_class.new(2, 3)
      positions = custom_table.all_positions
      expect(positions.length).to eq(6)

      expected_positions = [
        RobotChallenge::Position.new(0, 0), RobotChallenge::Position.new(1, 0),
        RobotChallenge::Position.new(0, 1), RobotChallenge::Position.new(1, 1),
        RobotChallenge::Position.new(0, 2), RobotChallenge::Position.new(1, 2)
      ]

      expect(positions).to match_array(expected_positions)
    end

    it 'returns single position for 1x1 table' do
      tiny_table = described_class.new(1, 1)
      positions = tiny_table.all_positions
      expect(positions).to eq([RobotChallenge::Position.new(0, 0)])
    end
  end

  describe '#to_s' do
    it 'returns descriptive string for default table' do
      expect(table.to_s).to eq('5x5 table')
    end

    it 'returns descriptive string for custom table' do
      custom_table = described_class.new(10, 8)
      expect(custom_table.to_s).to eq('10x8 table')
    end
  end

  describe '#==' do
    it 'returns true for tables with same dimensions' do
      table1 = described_class.new(5, 5)
      table2 = described_class.new(5, 5)
      expect(table1).to eq(table2)
    end

    it 'returns false for tables with different dimensions' do
      table1 = described_class.new(5, 5)
      table2 = described_class.new(5, 4)
      expect(table1).not_to eq(table2)
    end

    it 'returns false when comparing with non-Table object' do
      expect(table).not_to eq('5x5')
    end
  end

  describe 'edge cases' do
    it 'handles zero dimensions gracefully' do
      expect { described_class.new(0, 0) }.not_to raise_error
    end

    it 'validates zero-dimension table correctly' do
      zero_table = described_class.new(0, 0)
      expect(zero_table.valid_position?(RobotChallenge::Position.new(0, 0))).to be false
    end
  end
end
