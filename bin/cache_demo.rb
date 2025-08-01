#!/usr/bin/env ruby
# frozen_string_literal: true

# Demo script for Redis caching functionality
require_relative '../lib/robot_challenge'

puts '🤖 Robot Challenge - Redis Caching Demo'
puts '========================================'

# Check if Redis is available
puts "\n📡 Checking Redis availability..."
if RobotChallenge::Cache.redis_available?
  puts '✅ Redis is available!'
else
  puts '❌ Redis is not available. Please start Redis server:'
  puts '   brew install redis && brew services start redis'
  puts '   or'
  puts '   docker run -d -p 6379:6379 redis:alpine'
  exit 1
end

# Create cache instance
puts "\n🔧 Creating cache instance..."
cache = RobotChallenge::Cache.create_redis_cache

# Create table and robot
puts "\n🤖 Creating robot and table..."
table = RobotChallenge::Table.new(5, 5)
robot = RobotChallenge::Robot.new(table)

# Create cacheable robot
puts "\n💾 Creating cacheable robot..."
cacheable_robot = RobotChallenge::Cache.create_cacheable_robot(robot, cache: cache)

# Create command processor
puts "\n⚙️ Creating command processor..."
processor = RobotChallenge::CommandProcessor.new(robot)

# Create cached command processor
puts "\n🚀 Creating cached command processor..."
cached_processor = RobotChallenge::Cache.create_cached_processor(processor, cache: cache)

# Demo 1: Robot state caching
puts "\n🎯 Demo 1: Robot State Caching"
puts '--------------------------------'

puts 'Placing robot at (1, 2, NORTH)...'
cacheable_robot.place(RobotChallenge::Position.new(1, 2), RobotChallenge::Direction.new('NORTH'))

puts 'Moving robot...'
cacheable_robot.move

puts "Current robot state: #{cacheable_robot.report}"

# Demo 2: Command result caching
puts "\n🎯 Demo 2: Command Result Caching"
puts '----------------------------------'

commands = [
  'PLACE 0,0,NORTH',
  'MOVE',
  'LEFT',
  'MOVE',
  'REPORT'
]

puts 'Executing commands with caching...'
commands.each do |command|
  puts "  Executing: #{command}"
  result = cached_processor.process_command_string(command)
  puts "  Result: #{result}"
end

# Demo 3: Cache statistics
puts "\n🎯 Demo 3: Cache Statistics"
puts '----------------------------'

stats = cache.cache_stats
puts "Total cache keys: #{stats[:total_keys]}"
puts "Memory usage: #{stats[:memory_usage]}"
puts "Hit rate: #{stats[:hit_rate]}%"
puts "Keys by type: #{stats[:keys_by_type]}"

# Demo 4: Cache invalidation
puts "\n🎯 Demo 4: Cache Invalidation"
puts '-------------------------------'

puts 'Invalidating robot cache...'
cacheable_robot.invalidate_cache

puts 'Cache stats after invalidation:'
new_stats = cache.cache_stats
puts "Total cache keys: #{new_stats[:total_keys]}"

# Demo 5: Health check
puts "\n🎯 Demo 5: Health Check"
puts '------------------------'

health = RobotChallenge::Cache.health_check
puts "Cache available: #{health[:available]}"
puts "Connection info: #{health[:connection_info]}"

# Demo 6: Performance comparison
puts "\n🎯 Demo 6: Performance Comparison"
puts '----------------------------------'

# Test without caching
start_time = Time.now
100.times do
  processor.process_command_string('REPORT')
end
without_cache_time = Time.now - start_time

# Test with caching
start_time = Time.now
100.times do
  cached_processor.process_command_string('REPORT')
end
with_cache_time = Time.now - start_time

puts "Time without cache: #{without_cache_time.round(4)} seconds"
puts "Time with cache: #{with_cache_time.round(4)} seconds"
puts "Performance improvement: #{((without_cache_time - with_cache_time) / without_cache_time * 100).round(2)}%"

# Demo 7: Command statistics
puts "\n🎯 Demo 7: Command Statistics"
puts '------------------------------'

command_stats = cached_processor.command_stats
puts "Command statistics: #{command_stats}"

puts "\n🎉 Demo completed successfully!"
puts "\n💡 Tips:"
puts '  - Set ROBOT_CACHE_DEBUG=1 to see cache operations'
puts '  - Use cache.health_check to monitor cache status'
puts '  - Use cache.clear_all_cache to reset cache'
puts '  - Cache TTL is configurable (default: 1 hour)'
