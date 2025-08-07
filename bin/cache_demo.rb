#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/robot_challenge'

puts '🤖 Robot Challenge - Redis Caching Demo'
puts '========================================'

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

cache = RobotChallenge::Cache.create_redis_cache(namespace: 'demo_robot_challenge')
table = RobotChallenge::Table.new(5, 5)
robot = RobotChallenge::Robot.new(table)
cacheable_robot = RobotChallenge::Cache.create_cacheable_robot(robot, cache: cache)
cached_processor = RobotChallenge::Cache.create_cached_processor(
  RobotChallenge::CommandProcessor.new(robot), cache: cache
)

puts "\n🎯 Demo 1: Robot State Caching"
puts '--------------------------------'

puts 'Placing robot at (1, 2, NORTH)...'
cacheable_robot.place(RobotChallenge::Position.new(1, 2), RobotChallenge::Direction.new('NORTH'))

puts 'Moving robot...'
cacheable_robot.move

puts "Robot position: #{cacheable_robot.report}"

puts "\n🎯 Demo 2: Cache Operations"
puts '----------------------------'

puts 'Testing cache operations...'
cache.set_command_result('test_key', 'test_value')
result = cache.get_command_result('test_key')
puts "  Cached value: #{result}"

cache.invalidate_command_cache_by_hash('test_key')
result = cache.get_command_result('test_key')
puts "  After invalidation: #{result}"

puts "\n🎯 Demo 3: Cache Statistics"
puts '----------------------------'

stats = cache.cache_stats
puts "Total cache keys: #{stats[:total_keys]}"
puts "Memory usage: #{stats[:memory_usage]}"
puts "Hit rate: #{stats[:hit_rate]}%"
puts "Keys by type: #{stats[:keys_by_type]}"

puts "\n🎯 Demo 4: Cache Invalidation"
puts '-------------------------------'

puts 'Invalidating robot cache...'
cacheable_robot.invalidate_cache

new_stats = cache.cache_stats
puts "Total cache keys: #{new_stats[:total_keys]}"

puts "\n🎯 Demo 5: Health Check"
puts '------------------------'

health = RobotChallenge::Cache.health_check
puts "Cache available: #{health[:available]}"
puts "Connection info: #{health[:connection_info]}"

puts "\n🎯 Demo 6: Performance Comparison"
puts '----------------------------------'

start_time = Time.now
100.times { robot.move }
time_without_cache = Time.now - start_time

start_time = Time.now
100.times { cacheable_robot.move }
time_with_cache = Time.now - start_time

improvement = ((time_without_cache - time_with_cache) / time_without_cache * 100).round(1)
puts "Time without cache: #{time_without_cache.round(4)} seconds"
puts "Time with cache: #{time_with_cache.round(4)} seconds"
puts "Performance improvement: #{improvement}%"

puts "\n🎯 Demo 7: Cache Health Check"
puts '------------------------------'

health = cache.health_check
puts "Cache available: #{health[:available]}"
puts "Connection info: #{health[:connection_info]}"
puts "Cache stats: #{health[:cache_stats]}"

puts "\n🎉 Demo completed successfully!"
puts "\n💡 Tips:"
puts '  - Use cache.health_check to monitor cache status'
puts '  - Use cache.clear_all_cache to reset cache'
puts '  - Cache TTL is configurable (default: 1 hour)'
