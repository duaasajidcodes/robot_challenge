# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RobotChallenge::Commands::PlaceCommand do
  let(:table) { RobotChallenge::Table.new }
  let(:robot) { RobotChallenge::Robot.new(table) }
  let(:command) { described_class.new(1, 2, 'NORTH') }

  describe '#initialize' do
    it 'sets x, y, and direction_name' do
      expect(command.x).to eq(1)
      expect(command.y).to eq(2)
      expect(command.direction_name).to eq('NORTH')
    end
  end

  describe '#execute' do
    context 'with valid position and direction' do
      it 'places the robot successfully' do
        result = command.execute(robot)

        expect(result[:status]).to eq(:success)
        expect(robot.position.x).to eq(1)
        expect(robot.position.y).to eq(2)
        expect(robot.direction.name).to eq('NORTH')
      end
    end

    context 'with invalid position' do
      let(:command) { described_class.new(10, 10, 'NORTH') }

      it 'returns error result for position outside table' do
        result = command.execute(robot)

        expect(result[:status]).to eq(:error)
        expect(result[:error_type]).to eq(:invalid_placement)
        expect(result[:message]).to include('outside table boundaries')
      end
    end

    context 'with invalid direction' do
      let(:command) { described_class.new(1, 2, 'INVALID') }

      it 'returns error result for invalid direction' do
        result = command.execute(robot)

        expect(result[:status]).to eq(:error)
        expect(result[:error_type]).to eq(:invalid_placement)
      end
    end
  end

  describe '#valid?' do
    context 'with valid parameters' do
      it 'returns true' do
        expect(command.valid?).to be true
      end
    end

    context 'with negative coordinates' do
      let(:command) { described_class.new(-1, 2, 'NORTH') }

      it 'returns false' do
        expect(command.valid?).to be false
      end
    end

    context 'with non-integer coordinates' do
      let(:command) { described_class.new('invalid', 2, 'NORTH') }

      it 'returns false' do
        expect(command.valid?).to be false
      end
    end

    context 'with invalid direction' do
      let(:command) { described_class.new(1, 2, 'INVALID') }

      it 'returns false' do
        expect(command.valid?).to be false
      end
    end
  end

  describe '#to_s' do
    it 'returns string representation' do
      expect(command.to_s).to eq('PLACE 1,2,NORTH')
    end
  end
end
