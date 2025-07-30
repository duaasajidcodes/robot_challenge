# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RobotChallenge::Robot do
  let(:table) { RobotChallenge::Table.new }
  let(:robot) { described_class.new(table) }
  let(:position) { RobotChallenge::Position.new(1, 1) }
  let(:direction) { RobotChallenge::Direction.new('NORTH') }

  describe '#initialize' do
    it 'creates robot with table reference' do
      expect(robot.table).to eq(table)
    end

    it 'initializes robot as not placed' do
      expect(robot).not_to be_placed
      expect(robot.position).to be_nil
      expect(robot.direction).to be_nil
    end
  end

  describe '#place' do
    it 'places robot at valid position and direction' do
      robot.place(position, direction)

      expect(robot.position).to eq(position)
      expect(robot.direction).to eq(direction)
      expect(robot).to be_placed
    end

    it 'returns self for method chaining' do
      result = robot.place(position, direction)
      expect(result).to be(robot)
    end

    it 'raises error for invalid position object' do
      expect { robot.place('0,0', direction) }
        .to raise_error(RobotChallenge::InvalidPositionError, /Position must be a Position object/)
    end

    it 'raises error for invalid direction object' do
      expect { robot.place(position, 'NORTH') }
        .to raise_error(RobotChallenge::InvalidDirectionError, /Direction must be a Direction object/)
    end

    it 'raises error for position outside table boundaries' do
      invalid_position = RobotChallenge::Position.new(5, 5)
      expect { robot.place(invalid_position, direction) }
        .to raise_error(RobotChallenge::InvalidPositionError, /outside table boundaries/)
    end

    it 'allows replacing existing placement' do
      robot.place(position, direction)
      new_position = RobotChallenge::Position.new(2, 2)
      new_direction = RobotChallenge::Direction.new('SOUTH')

      robot.place(new_position, new_direction)

      expect(robot.position).to eq(new_position)
      expect(robot.direction).to eq(new_direction)
    end
  end

  describe '#placed?' do
    it 'returns false for unplaced robot' do
      expect(robot).not_to be_placed
    end

    it 'returns true for placed robot' do
      robot.place(position, direction)
      expect(robot).to be_placed
    end
  end

  describe '#move' do
    context 'when robot is not placed' do
      it 'raises error' do
        expect { robot.move }
          .to raise_error(RobotChallenge::RobotNotPlacedError, /must be placed before moving/)
      end
    end

    context 'when robot is placed' do
      before { robot.place(position, direction) }

      it 'moves robot one step in current direction' do
        robot.move
        expect(robot.position).to eq(RobotChallenge::Position.new(1, 2))
      end

      it 'returns self for method chaining' do
        result = robot.move
        expect(result).to be(robot)
      end

      it 'does not move robot if new position would be invalid' do
        # Place robot at edge facing outward
        robot.place(RobotChallenge::Position.new(0, 0), RobotChallenge::Direction.new('SOUTH'))
        original_position = robot.position

        robot.move
        expect(robot.position).to eq(original_position)
      end

      context 'movement in each direction' do
        it 'moves north correctly' do
          robot.place(RobotChallenge::Position.new(2, 2), RobotChallenge::Direction.new('NORTH'))
          robot.move
          expect(robot.position).to eq(RobotChallenge::Position.new(2, 3))
        end

        it 'moves east correctly' do
          robot.place(RobotChallenge::Position.new(2, 2), RobotChallenge::Direction.new('EAST'))
          robot.move
          expect(robot.position).to eq(RobotChallenge::Position.new(3, 2))
        end

        it 'moves south correctly' do
          robot.place(RobotChallenge::Position.new(2, 2), RobotChallenge::Direction.new('SOUTH'))
          robot.move
          expect(robot.position).to eq(RobotChallenge::Position.new(2, 1))
        end

        it 'moves west correctly' do
          robot.place(RobotChallenge::Position.new(2, 2), RobotChallenge::Direction.new('WEST'))
          robot.move
          expect(robot.position).to eq(RobotChallenge::Position.new(1, 2))
        end
      end

      context 'boundary protection' do
        it 'prevents movement beyond north boundary' do
          robot.place(RobotChallenge::Position.new(2, 4), RobotChallenge::Direction.new('NORTH'))
          robot.move
          expect(robot.position).to eq(RobotChallenge::Position.new(2, 4))
        end

        it 'prevents movement beyond east boundary' do
          robot.place(RobotChallenge::Position.new(4, 2), RobotChallenge::Direction.new('EAST'))
          robot.move
          expect(robot.position).to eq(RobotChallenge::Position.new(4, 2))
        end

        it 'prevents movement beyond south boundary' do
          robot.place(RobotChallenge::Position.new(2, 0), RobotChallenge::Direction.new('SOUTH'))
          robot.move
          expect(robot.position).to eq(RobotChallenge::Position.new(2, 0))
        end

        it 'prevents movement beyond west boundary' do
          robot.place(RobotChallenge::Position.new(0, 2), RobotChallenge::Direction.new('WEST'))
          robot.move
          expect(robot.position).to eq(RobotChallenge::Position.new(0, 2))
        end
      end
    end
  end

  describe '#turn_left' do
    context 'when robot is not placed' do
      it 'raises error' do
        expect { robot.turn_left }
          .to raise_error(RobotChallenge::RobotNotPlacedError, /must be placed before turning/)
      end
    end

    context 'when robot is placed' do
      before { robot.place(position, direction) }

      it 'rotates direction 90 degrees counter-clockwise' do
        robot.turn_left
        expect(robot.direction.name).to eq('WEST')
        expect(robot.position).to eq(position) # Position unchanged
      end

      it 'returns self for method chaining' do
        result = robot.turn_left
        expect(result).to be(robot)
      end

      it 'completes full rotation in 4 turns' do
        original_direction = robot.direction
        robot.turn_left.turn_left.turn_left.turn_left
        expect(robot.direction).to eq(original_direction)
      end
    end
  end

  describe '#turn_right' do
    context 'when robot is not placed' do
      it 'raises error' do
        expect { robot.turn_right }
          .to raise_error(RobotChallenge::RobotNotPlacedError, /must be placed before turning/)
      end
    end

    context 'when robot is placed' do
      before { robot.place(position, direction) }

      it 'rotates direction 90 degrees clockwise' do
        robot.turn_right
        expect(robot.direction.name).to eq('EAST')
        expect(robot.position).to eq(position) # Position unchanged
      end

      it 'returns self for method chaining' do
        result = robot.turn_right
        expect(result).to be(robot)
      end

      it 'completes full rotation in 4 turns' do
        original_direction = robot.direction
        robot.turn_right.turn_right.turn_right.turn_right
        expect(robot.direction).to eq(original_direction)
      end
    end
  end

  describe '#report' do
    context 'when robot is not placed' do
      it 'raises error' do
        expect { robot.report }
          .to raise_error(RobotChallenge::RobotNotPlacedError, /must be placed before reporting/)
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

  describe '#reset' do
    it 'resets robot to unplaced state' do
      robot.place(position, direction)
      expect(robot).to be_placed

      robot.reset
      expect(robot).not_to be_placed
      expect(robot.position).to be_nil
      expect(robot.direction).to be_nil
    end

    it 'returns self for method chaining' do
      result = robot.reset
      expect(result).to be(robot)
    end

    it 'can be called on already unplaced robot' do
      expect { robot.reset }.not_to raise_error
    end
  end

  describe '#can_move?' do
    context 'when robot is not placed' do
      it 'returns false' do
        expect(robot.can_move?).to be false
      end
    end

    context 'when robot is placed' do
      it 'returns true when move is valid' do
        robot.place(RobotChallenge::Position.new(2, 2), RobotChallenge::Direction.new('NORTH'))
        expect(robot.can_move?).to be true
      end

      it 'returns false when move would go off table' do
        robot.place(RobotChallenge::Position.new(0, 0), RobotChallenge::Direction.new('SOUTH'))
        expect(robot.can_move?).to be false
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
