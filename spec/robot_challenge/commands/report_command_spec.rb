# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RobotChallenge::Commands::ReportCommand do
  let(:table) { RobotChallenge::Table.new }
  let(:robot) { RobotChallenge::Robot.new(table) }
  let(:command) { described_class.new }

  describe '#execute' do
    context 'when robot is placed' do
      before do
        position = RobotChallenge::Position.new(2, 3)
        direction = RobotChallenge::Direction.new('EAST')
        robot.place(position, direction)
      end

      it 'returns output result with robot report' do
        result = command.execute(robot)

        expect(result[:status]).to eq(:output)
        expect(result[:message]).to eq(robot)
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
  end

  describe '#to_s' do
    it 'returns string representation' do
      expect(command.to_s).to eq('REPORT')
    end
  end
end
