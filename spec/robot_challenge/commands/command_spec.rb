# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RobotChallenge::Commands::Command do
  let(:command) { described_class.new }

  describe '#execute' do
    it 'raises NotImplementedError' do
      expect { command.execute(double('robot')) }.to raise_error(NotImplementedError)
    end
  end

  describe '#valid?' do
    it 'returns true by default' do
      expect(command.valid?).to be true
    end
  end

  describe '#name' do
    it 'returns the class name as lowercase symbol' do
      expect(command.name).to eq(:command)
    end
  end

  describe 'result helper methods' do
    describe '#success_result' do
      it 'returns success status with optional data' do
        result = command.send(:success_result, 'test data')
        expect(result).to eq({ status: :success, data: 'test data' })
      end

      it 'returns success status without data' do
        result = command.send(:success_result)
        expect(result).to eq({ status: :success, data: nil })
      end
    end

    describe '#error_result' do
      it 'returns error status with message and type' do
        result = command.send(:error_result, 'test error', :test_type)
        expect(result).to eq({ status: :error, message: 'test error', error_type: :test_type })
      end

      it 'returns error status with default error type' do
        result = command.send(:error_result, 'test error')
        expect(result).to eq({ status: :error, message: 'test error', error_type: :general_error })
      end
    end

    describe '#output_result' do
      it 'returns output status with message' do
        result = command.send(:output_result, 'test output')
        expect(result).to eq({ status: :output, message: 'test output' })
      end
    end
  end
end
