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

# Custom tasks
desc 'Run the robot challenge application'
task :run do
  ruby '-Ilib bin/robot_challenge'
end

desc 'Run with example test data'
task :run_example do
  sh 'ruby -Ilib bin/robot_challenge < test_data/example_commands.txt'
end

desc 'Clean temporary files'
task :clean do
  sh 'rm -rf coverage tmp'
end

desc 'Setup development environment'
task :setup do
  sh 'bundle install'
  puts 'Development environment setup complete!'
end
