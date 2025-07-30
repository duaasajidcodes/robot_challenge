# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RobotChallenge do
  describe 'VERSION' do
    it 'has a version number' do
      expect(RobotChallenge::VERSION).not_to be_nil
      expect(RobotChallenge::VERSION).to be_a(String)
    end

    it 'follows semantic versioning format' do
      expect(RobotChallenge::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
    end

    it 'has the expected version' do
      expect(RobotChallenge::VERSION).to eq('1.0.0')
    end
  end

  describe 'module constants' do
    it 'defines custom error classes' do
      expect(RobotChallenge::Error).to be < StandardError
      expect(RobotChallenge::InvalidCommandError).to be < RobotChallenge::Error
      expect(RobotChallenge::InvalidPositionError).to be < RobotChallenge::Error
      expect(RobotChallenge::InvalidDirectionError).to be < RobotChallenge::Error
      expect(RobotChallenge::RobotNotPlacedError).to be < RobotChallenge::Error
    end
  end

  describe 'module loading' do
    it 'loads all required components' do
      expect(defined?(RobotChallenge::Position)).to be_truthy
      expect(defined?(RobotChallenge::Direction)).to be_truthy
      expect(defined?(RobotChallenge::Robot)).to be_truthy
      expect(defined?(RobotChallenge::Table)).to be_truthy
      expect(defined?(RobotChallenge::CommandParser)).to be_truthy
      expect(defined?(RobotChallenge::CommandProcessor)).to be_truthy
      expect(defined?(RobotChallenge::Application)).to be_truthy
    end

    it 'provides access to all classes through module namespace' do
      expect(RobotChallenge::Position).to be_a(Class)
      expect(RobotChallenge::Direction).to be_a(Class)
      expect(RobotChallenge::Robot).to be_a(Class)
      expect(RobotChallenge::Table).to be_a(Class)
      expect(RobotChallenge::CommandParser).to be_a(Class)
      expect(RobotChallenge::CommandProcessor).to be_a(Class)
      expect(RobotChallenge::Application).to be_a(Class)
    end
  end
end
