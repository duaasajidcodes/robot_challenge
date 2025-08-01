# frozen_string_literal: true

require 'simplecov'

if ENV['COVERAGE']
  SimpleCov.start do
    add_filter '/spec/'
    minimum_coverage 90
    refuse_coverage_drop
  end
end

require_relative '../lib/robot_challenge'
require_relative 'test_helper'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on Module and main
  config.disable_monkey_patching!

  # Use expect syntax instead of should
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Filter out system gems from backtraces
  config.filter_gems_from_backtrace 'bundler'

  # Color output
  config.color = true

  # Format output
  config.formatter = :documentation
end
