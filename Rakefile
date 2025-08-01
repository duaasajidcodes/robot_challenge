# frozen_string_literal: true

desc 'Run extensibility test runner'
task :test_extensibility do
  ruby 'bin/extensibility_test_runner'
end

desc 'Run all tests including extensibility'
task test_all: %i[spec test_extensibility]

# frozen_string_literal: true

require 'rake'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

# Default task
task default: %i[spec rubocop]

# RSpec tasks
RSpec::Core::RakeTask.new(:spec) do |task|
  task.rspec_opts = '--format documentation --color'
end

RSpec::Core::RakeTask.new(:spec_with_coverage) do |task|
  task.rspec_opts = '--format documentation --color'
  ENV['COVERAGE'] = 'true'
end

# RuboCop tasks
RuboCop::RakeTask.new(:rubocop) do |task|
  task.options = ['--display-cop-names']
end

RuboCop::RakeTask.new('rubocop:auto_correct') do |task|
  task.options = ['--auto-correct']
end

desc 'Run the robot challenge application'
task :run do
  ruby '-Ilib bin/robot_challenge'
end

desc 'Run with example test data'
task :run_example do
  sh 'ruby -Ilib bin/robot_challenge < test_data/example_commands.txt'
end

desc 'Demonstrate command extensibility'
task :demo_extensibility do
  ruby 'bin/extensibility_demo'
end

desc 'Show how to add new commands'
task :demo_extensions do
  ruby 'bin/demo_extensions'
end

# Utility tasks
desc 'Clean temporary files'
task :clean do
  sh 'rm -rf coverage tmp'
end

desc 'Setup development environment'
task :setup do
  sh 'bundle install'
  puts 'Development environment setup complete!'
end
