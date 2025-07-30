# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RobotChallenge::Position do
  describe '#initialize' do
    it 'creates a position with integer coordinates' do
      position = described_class.new(1, 2)
      expect(position.x).to eq(1)
      expect(position.y).to eq(2)
    end

    it 'converts string coordinates to integers' do
      position = described_class.new('3', '4')
      expect(position.x).to eq(3)
      expect(position.y).to eq(4)
    end

    it 'handles zero coordinates' do
      position = described_class.new(0, 0)
      expect(position.x).to eq(0)
      expect(position.y).to eq(0)
    end

    it 'handles negative coordinates' do
      position = described_class.new(-1, -2)
      expect(position.x).to eq(-1)
      expect(position.y).to eq(-2)
    end
  end

  describe '#==' do
    it 'returns true for positions with same coordinates' do
      position1 = described_class.new(1, 2)
      position2 = described_class.new(1, 2)
      expect(position1).to eq(position2)
    end

    it 'returns false for positions with different coordinates' do
      position1 = described_class.new(1, 2)
      position2 = described_class.new(2, 1)
      expect(position1).not_to eq(position2)
    end

    it 'returns false when comparing with non-Position object' do
      position = described_class.new(1, 2)
      expect(position).not_to eq('1,2')
    end
  end

  describe '#eql?' do
    it 'returns true for equal positions' do
      position1 = described_class.new(1, 2)
      position2 = described_class.new(1, 2)
      expect(position1.eql?(position2)).to be true
    end

    it 'returns false for different positions' do
      position1 = described_class.new(1, 2)
      position2 = described_class.new(2, 1)
      expect(position1.eql?(position2)).to be false
    end
  end

  describe '#hash' do
    it 'returns same hash for equal positions' do
      position1 = described_class.new(1, 2)
      position2 = described_class.new(1, 2)
      expect(position1.hash).to eq(position2.hash)
    end

    it 'can be used as hash keys' do
      position1 = described_class.new(1, 2)
      position2 = described_class.new(1, 2)
      hash = { position1 => 'value1' }
      expect(hash[position2]).to eq('value1')
    end
  end

  describe '#to_s' do
    it 'returns coordinate string in X,Y format' do
      position = described_class.new(3, 4)
      expect(position.to_s).to eq('3,4')
    end

    it 'handles zero coordinates' do
      position = described_class.new(0, 0)
      expect(position.to_s).to eq('0,0')
    end
  end

  describe '#move' do
    it 'returns new position with delta applied' do
      position = described_class.new(1, 2)
      new_position = position.move(1, -1)

      expect(new_position.x).to eq(2)
      expect(new_position.y).to eq(1)
      expect(position.x).to eq(1) # Original unchanged
      expect(position.y).to eq(2) # Original unchanged
    end

    it 'handles zero delta' do
      position = described_class.new(1, 2)
      new_position = position.move(0, 0)
      expect(new_position).to eq(position)
      expect(new_position).not_to be(position) # Different object
    end

    it 'handles negative deltas' do
      position = described_class.new(3, 3)
      new_position = position.move(-2, -1)
      expect(new_position.x).to eq(1)
      expect(new_position.y).to eq(2)
    end
  end

  describe '#inspect' do
    it 'returns detailed object representation' do
      position = described_class.new(1, 2)
      inspect_string = position.inspect

      expect(inspect_string).to include('Position')
      expect(inspect_string).to include('x=1')
      expect(inspect_string).to include('y=2')
    end
  end
end
