# frozen_string_literal: true

require 'rake'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

task default: %i[spec rubocop]

RSpec::Core::RakeTask.new(:spec) do |task|
  task.rspec_opts = '--format documentation --color'
end

RSpec::Core::RakeTask.new(:spec_with_coverage) do |task|
  task.rspec_opts = '--format documentation --color'
  ENV['COVERAGE'] = 'true'
end

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

desc 'Run the robot challenge in interactive mode'
task :interactive do
  ruby '-Ilib bin/robot_challenge_interactive.rb'
end

desc 'Run with example test data'
task :run_example do
  sh 'ruby -Ilib bin/robot_challenge < test_data/example_1.txt'
end

desc 'Run Redis caching demo'
task :demo_cache do
  ruby 'bin/cache_demo.rb'
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
