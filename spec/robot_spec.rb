# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RobotChallenge::Robot do
  let(:table) { RobotChallenge::Table.new }
  let(:robot) { described_class.new(table) }
  let(:position) { RobotChallenge::Position.new(1, 1) }
  let(:direction) { RobotChallenge::Direction.new('NORTH') }

  describe '#initialize' do
    it 'creates robot with table' do
      expect(robot.table).to eq(table)
    end

    it 'starts in unplaced state' do
      expect(robot).not_to be_placed
      expect(robot.position).to be_nil
      expect(robot.direction).to be_nil
    end
  end

  describe '#place' do
    context 'with valid position and direction' do
      it 'places robot successfully' do
        robot.place(position, direction)

        expect(robot).to be_placed
        expect(robot.position).to eq(position)
        expect(robot.direction).to eq(direction)
      end

      it 'returns self for method chaining' do
        result = robot.place(position, direction)
        expect(result).to be(robot)
      end
    end

    context 'with invalid position' do
      let(:invalid_position) { RobotChallenge::Position.new(10, 10) }

      it 'raises InvalidPositionError' do
        expect { robot.place(invalid_position, direction) }.to raise_error(RobotChallenge::InvalidPositionError)
      end
    end

    context 'with invalid direction' do
      let(:invalid_direction) { double('direction') }

      it 'raises InvalidDirectionError' do
        expect { robot.place(position, invalid_direction) }.to raise_error(RobotChallenge::InvalidDirectionError)
      end
    end

    context 'with non-Position object' do
      it 'raises InvalidPositionError' do
        expect { robot.place('invalid', direction) }.to raise_error(RobotChallenge::InvalidPositionError)
      end
    end

    context 'with non-Direction object' do
      it 'raises InvalidDirectionError' do
        expect { robot.place(position, 'invalid') }.to raise_error(RobotChallenge::InvalidDirectionError)
      end
    end
  end

  describe '#placed?' do
    it 'returns false when robot is not placed' do
      expect(robot).not_to be_placed
    end

    it 'returns true when robot is placed' do
      robot.place(position, direction)
      expect(robot).to be_placed
    end
  end

  describe '#move' do
    context 'when robot is not placed' do
      it 'raises RobotNotPlacedError' do
        expect { robot.move }.to raise_error(RobotChallenge::RobotNotPlacedError)
      end
    end

    context 'when robot is placed' do
      before { robot.place(position, direction) }

      it 'moves robot in current direction' do
        robot.move
        expect(robot.position.y).to eq(2)
      end

      it 'returns self for method chaining' do
        result = robot.move
        expect(result).to be(robot)
      end

      context 'when move would go off table' do
        let(:edge_position) { RobotChallenge::Position.new(0, 0) }
        let(:south_direction) { RobotChallenge::Direction.new('SOUTH') }

        it 'does not move robot' do
          robot.place(edge_position, south_direction)
          robot.move
          expect(robot.position).to eq(edge_position)
        end
      end

      context 'when move is valid' do
        it 'moves robot to new position' do
          original_position = robot.position
          robot.move
          expect(robot.position).not_to eq(original_position)
        end
      end
    end
  end

  describe '#turn_left' do
    context 'when robot is not placed' do
      it 'raises RobotNotPlacedError' do
        expect { robot.turn_left }.to raise_error(RobotChallenge::RobotNotPlacedError)
      end
    end

    context 'when robot is placed' do
      before { robot.place(position, direction) }

      it 'turns robot 90 degrees counter-clockwise' do
        robot.turn_left
        expect(robot.direction.name).to eq('WEST')
      end

      it 'returns self for method chaining' do
        result = robot.turn_left
        expect(result).to be(robot)
      end

      it 'handles full rotation' do
        robot.turn_left.turn_left.turn_left.turn_left
        expect(robot.direction.name).to eq('NORTH')
      end
    end
  end

  describe '#turn_right' do
    context 'when robot is not placed' do
      it 'raises RobotNotPlacedError' do
        expect { robot.turn_right }.to raise_error(RobotChallenge::RobotNotPlacedError)
      end
    end

    context 'when robot is placed' do
      before { robot.place(position, direction) }

      it 'turns robot 90 degrees clockwise' do
        robot.turn_right
        expect(robot.direction.name).to eq('EAST')
      end

      it 'returns self for method chaining' do
        result = robot.turn_right
        expect(result).to be(robot)
      end

      it 'handles full rotation' do
        robot.turn_right.turn_right.turn_right.turn_right
        expect(robot.direction.name).to eq('NORTH')
      end
    end
  end

  describe '#report' do
    context 'when robot is not placed' do
      it 'raises RobotNotPlacedError' do
        expect { robot.report }.to raise_error(RobotChallenge::RobotNotPlacedError)
      end
    end

    context 'when robot is placed' do
      before { robot.place(position, direction) }

      it 'returns formatted position and direction string' do
        expect(robot.report).to eq('1,1,NORTH')
      end

      it 'updates when robot moves' do
        robot.move
        expect(robot.report).to eq('1,2,NORTH')
      end

      it 'updates when robot turns' do
        robot.turn_right
        expect(robot.report).to eq('1,1,EAST')
      end
    end
  end

  describe '#to_s' do
    it 'returns descriptive string for unplaced robot' do
      expect(robot.to_s).to eq('Robot not placed')
    end

    it 'returns descriptive string for placed robot' do
      robot.place(position, direction)
      expect(robot.to_s).to eq('Robot at 1,1 facing NORTH')
    end
  end

  describe 'integration scenarios' do
    it 'handles complex movement sequence' do
      robot.place(RobotChallenge::Position.new(1, 2), RobotChallenge::Direction.new('EAST'))
      robot.move.move.turn_left.move
      expect(robot.report).to eq('3,3,NORTH')
    end

    it 'handles boundary collision during sequence' do
      robot.place(RobotChallenge::Position.new(0, 0), RobotChallenge::Direction.new('NORTH'))
      5.times { robot.move }
      expect(robot.report).to eq('0,4,NORTH') # Stopped at boundary
    end

    it 'handles rotation without movement' do
      robot.place(RobotChallenge::Position.new(0, 0), RobotChallenge::Direction.new('NORTH'))
      robot.turn_left.turn_left
      expect(robot.report).to eq('0,0,SOUTH')
    end

    it 'allows multiple placements' do
      robot.place(RobotChallenge::Position.new(0, 0), RobotChallenge::Direction.new('NORTH'))
      robot.place(RobotChallenge::Position.new(4, 4), RobotChallenge::Direction.new('SOUTH'))
      expect(robot.report).to eq('4,4,SOUTH')
    end
  end
end
