# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RobotChallenge::Commands::MoveCommand do
  let(:table) { RobotChallenge::Table.new }
  let(:robot) { RobotChallenge::Robot.new(table) }
  let(:command) { described_class.new }

  describe '#execute' do
    context 'when robot is placed' do
      before do
        position = RobotChallenge::Position.new(1, 1)
        direction = RobotChallenge::Direction.new('NORTH')
        robot.place(position, direction)
      end

      it 'moves the robot successfully' do
        result = command.execute(robot)

        expect(result[:status]).to eq(:success)
        expect(robot.position.y).to eq(2)
      end
    end

    context 'when robot is not placed' do
      it 'returns error result' do
        result = command.execute(robot)

        expect(result[:status]).to eq(:error)
        expect(result[:error_type]).to eq(:robot_not_placed)
        expect(result[:message]).to include('must be placed')
      end
    end

    context 'when move would cause robot to fall' do
      before do
        position = RobotChallenge::Position.new(0, 4)
        direction = RobotChallenge::Direction.new('NORTH')
        robot.place(position, direction)
      end

      it 'does not move the robot but returns success' do
        original_position = robot.position
        result = command.execute(robot)

        expect(result[:status]).to eq(:success)
        expect(robot.position).to eq(original_position)
      end
    end
  end

  describe '#to_s' do
    it 'returns string representation' do
      expect(command.to_s).to eq('MOVE')
    end
  end
end
