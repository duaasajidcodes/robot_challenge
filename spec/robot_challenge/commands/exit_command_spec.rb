# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RobotChallenge::Commands::ExitCommand do
  let(:command) { described_class.new }
  let(:robot) { instance_double(RobotChallenge::Robot) }
  let(:table) { instance_double(RobotChallenge::Table) }
  let(:output_handler) { instance_double(Proc) }

  describe '#execute' do
    it 'returns goodbye message' do
      result = command.execute(robot)
      expect(result[:status]).to eq(:output)
      expect(result[:message]).to eq('Goodbye! Thanks for using Robot Challenge!')
    end
  end

  describe '#valid_for_robot?' do
    it 'returns true regardless of robot state' do
      expect(command.valid_for_robot?(robot)).to be true
    end
  end
end
