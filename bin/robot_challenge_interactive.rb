#!/usr/bin/env ruby
# frozen_string_literal: true

# Add lib directory to load path
$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'robot_challenge'

puts "🤖 Welcome to Robot Challenge Interactive Mode!"
puts "This mode provides a comprehensive menu to test all features."
puts "Press Ctrl+C to exit at any time."
puts

# Create application with default settings
app = RobotChallenge::Application.new

# Run the menu system
menu = RobotChallenge::MenuSystem.new(app)
menu.run

puts "\n#{RobotChallenge::Constants::SUCCESS_MESSAGES[:goodbye]}" 