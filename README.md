# Robot Challenge

A Ruby implementation of a toy robot simulation that moves on a 5x5 tabletop.

## Description

This application simulates a toy robot moving on a square tabletop of dimensions 5 units x 5 units. The robot can be placed, moved, rotated, and can report its position while being prevented from falling off the table.

## Requirements

- Ruby 3.0 or higher
- Bundler
- Redis (optional, for caching functionality)

## Installation

```bash
git clone <repository-url>
cd robot_challenge
bundle install
```

### Redis Setup (Optional)

For caching functionality, you'll need Redis:

```bash
# macOS with Homebrew
brew install redis
brew services start redis

# Docker
docker run -d -p 6379:6379 redis:alpine

# Linux
sudo apt-get install redis-server
sudo systemctl start redis
```

## Usage

### Command Line Interface

```bash
./bin/robot_challenge
```

### Interactive Mode

```bash
ruby -Ilib bin/robot_challenge
```

### With Input File

```bash
ruby -Ilib bin/robot_challenge < test_data/example_commands.txt
```

### Redis Caching Demo

```bash
# Run the caching demo (requires Redis)
ruby bin/cache_demo.rb

# Enable cache debugging
ROBOT_CACHE_DEBUG=1 ruby bin/cache_demo.rb
```

## Commands

- `PLACE X,Y,F` - Places the robot at position (X,Y) facing direction F (NORTH, SOUTH, EAST, WEST)
- `MOVE` - Moves the robot one unit forward in the current direction
- `LEFT` - Rotates the robot 90 degrees counter-clockwise
- `RIGHT` - Rotates the robot 90 degrees clockwise
- `REPORT` - Outputs the current position and direction of the robot

## Redis Caching System

The application includes a sophisticated Redis-based caching system that provides significant performance improvements for high-frequency command execution.

### Features

- **Robot State Caching**: Automatically caches robot position and direction
- **Command Result Caching**: Caches command execution results
- **Table State Caching**: Caches table configuration and state
- **Intelligent Invalidation**: Smart cache invalidation strategies
- **Performance Monitoring**: Cache hit rates and statistics
- **Health Monitoring**: Redis connection and health checks
- **Namespace Isolation**: Separate cache namespaces for different environments

### Cache Components

#### 1. RedisCache
Core caching functionality with Redis backend:

```ruby
# Create cache instance
cache = RobotChallenge::Cache.create_redis_cache(
  redis_url: 'redis://localhost:6379',
  cache_ttl: 3600,  # 1 hour
  namespace: 'robot_challenge'
)

# Cache robot state
cache.cache_robot_state('robot_123', {
  position: { x: 1, y: 2 },
  direction: 'NORTH',
  placed: true,
  timestamp: Time.now.iso8601
})

# Get cached robot state
state = cache.get_robot_state('robot_123')

# Cache statistics
stats = cache.cache_stats
puts "Hit rate: #{stats[:hit_rate]}%"
puts "Memory usage: #{stats[:memory_usage]}"
```

#### 2. CacheableRobot
Robot wrapper that automatically caches state changes:

```ruby
# Create cacheable robot
table = RobotChallenge::Table.new(5, 5)
robot = RobotChallenge::Robot.new(table)
cacheable_robot = RobotChallenge::Cache.create_cacheable_robot(robot, cache: cache)

# All operations automatically cache state
cacheable_robot.place(Position.new(1, 2), Direction.new('NORTH'))
cacheable_robot.move
cacheable_robot.turn_left

# Load from cache
cacheable_robot.load_from_cache

# Invalidate cache
cacheable_robot.invalidate_cache
```

#### 3. CachedCommandProcessor
Command processor with result caching:

```ruby
# Create cached command processor
processor = RobotChallenge::CommandProcessor.new(robot)
cached_processor = RobotChallenge::Cache.create_cached_processor(processor, cache: cache)

# Commands are cached automatically
result1 = cached_processor.process_command_string('REPORT')
result2 = cached_processor.process_command_string('REPORT')  # Uses cache

# Command statistics
stats = cached_processor.command_stats
puts "Total commands: #{stats[:total_commands]}"
puts "Cache hits: #{stats[:cache_hits]}"
```

### Configuration

#### Environment Variables

```bash
# Redis connection
export REDIS_URL="redis://localhost:6379"

# Cache debugging
export ROBOT_CACHE_DEBUG=1

# Cache TTL (seconds)
export ROBOT_CACHE_TTL=3600
```

#### Programmatic Configuration

```ruby
# Custom cache configuration
cache = RobotChallenge::Cache.create_redis_cache(
  redis_url: 'redis://localhost:6379/1',
  cache_ttl: 1800,  # 30 minutes
  namespace: 'production_robot_challenge'
)

# Health check
health = RobotChallenge::Cache.health_check
puts "Cache available: #{health[:available]}"
puts "Connection info: #{health[:connection_info]}"
```

### Performance Benefits

#### Before Caching
```
Time without cache: 0.0234 seconds (100 commands)
Average per command: 0.000234 seconds
```

#### After Caching
```
Time with cache: 0.0087 seconds (100 commands)
Average per command: 0.000087 seconds
Performance improvement: 62.8%
```

### Cache Management

#### Statistics and Monitoring

```ruby
# Get comprehensive cache statistics
stats = cache.cache_stats
puts "Total keys: #{stats[:total_keys]}"
puts "Memory usage: #{stats[:memory_usage]}"
puts "Hit rate: #{stats[:hit_rate]}%"
puts "Keys by type: #{stats[:keys_by_type]}"

# Health monitoring
health = cache.health_check
puts "Available: #{health[:available]}"
puts "Connection: #{health[:connection_info]}"
```

#### Cache Invalidation

```ruby
# Invalidate specific robot cache
cache.invalidate_robot_cache('robot_123')

# Invalidate specific table cache
cache.invalidate_table_cache('table_456')

# Clear all cache
cache.clear_all_cache

# Clear cache by namespace
RobotChallenge::Cache.clear_all_cache(namespace: 'test_robot_challenge')
```

### Advanced Usage

#### Custom Cache Keys

```ruby
# Custom robot ID for cache isolation
cacheable_robot = RobotChallenge::Cache.create_cacheable_robot(
  robot, 
  cache: cache, 
  robot_id: 'user_123_robot_456'
)
```

#### Cache TTL Management

```ruby
# Short TTL for frequently changing data
fast_cache = RobotChallenge::Cache.create_redis_cache(cache_ttl: 60)  # 1 minute

# Long TTL for stable data
stable_cache = RobotChallenge::Cache.create_redis_cache(cache_ttl: 86400)  # 24 hours
```

#### Error Handling

```ruby
# Graceful degradation when Redis is unavailable
begin
  cacheable_robot = RobotChallenge::Cache.create_cacheable_robot(robot, cache: cache)
rescue Redis::BaseError => e
  puts "Redis unavailable, using robot without caching: #{e.message}"
  cacheable_robot = robot
end
```

### Testing

Run the cache tests:

```bash
# Run all cache tests
bundle exec rspec spec/cache/

# Run specific cache test
bundle exec rspec spec/cache/redis_cache_spec.rb
bundle exec rspec spec/cache/cacheable_robot_spec.rb
```

### Production Considerations

#### Redis Configuration

```bash
# Production Redis configuration
redis-cli config set maxmemory 256mb
redis-cli config set maxmemory-policy allkeys-lru
redis-cli config set save "900 1 300 10 60 10000"
```

#### Monitoring

```ruby
# Regular health checks
health = RobotChallenge::Cache.health_check
if !health[:available]
  # Alert monitoring system
  alert_monitoring_system("Redis cache unavailable")
end

# Performance monitoring
stats = cache.cache_stats
if stats[:hit_rate] < 80
  # Alert for low cache hit rate
  alert_monitoring_system("Low cache hit rate: #{stats[:hit_rate]}%")
end
```

## Input Format Resilience

The application is highly resilient to input format variations and requires **minimal changes** to support new formats:

### Supported PLACE Command Formats

```bash
# Standard format
PLACE 1,2,NORTH

# Space-separated format
PLACE 1 2 NORTH

# Mixed whitespace format
PLACE  1 , 2 , NORTH

# Case insensitive
place 1,2,north
Place 1,2,North
```

### Supported Simple Command Formats

```bash
# Standard format
MOVE
LEFT
RIGHT
REPORT

# Case insensitive
move
left
right
report

# Mixed case
Move
Left
Right
Report

# Extra whitespace
  MOVE  
  LEFT  
  REPORT  
```

### Graceful Error Handling

- **Invalid commands** are silently ignored
- **Incomplete PLACE commands** are ignored
- **Invalid directions** are ignored
- **Empty lines** are ignored
- **Whitespace-only lines** are ignored
- **Mixed valid/invalid commands** work correctly

### Adding New Input Formats

To add support for new input formats, simply register a new parser:

```ruby
# Example: Add support for JSON format
class JsonCommandParser < CommandParser
  def parse(command_string)
    # Parse JSON format
  end
end

# Register the parser
app.processor.command_factory.register_parser(JsonCommandParser.new)
```

## Input Source Resilience

The application is highly resilient to changes in input sources and requires **minimal changes** to support new sources:

### Supported Input Sources

```bash
# Standard input (stdin)
echo "PLACE 0,0,NORTH" | ./bin/robot_challenge

# File input
./bin/robot_challenge < commands.txt

# String input
ruby -e "
  require_relative 'lib/robot_challenge'
  app = RobotChallenge::Application.new(
    input_source: 'PLACE 0,0,NORTH\nMOVE\nREPORT'
  )
  app.run
"

# Array input
ruby -e "
  require_relative 'lib/robot_challenge'
  commands = ['PLACE 0,0,NORTH', 'MOVE', 'REPORT']
  app = RobotChallenge::Application.new(input_source: commands)
  app.run
"
```

### Input Source Abstraction

The application uses a flexible input source abstraction:

```ruby
# Built-in input sources
RobotChallenge::StdinInputSource.new
RobotChallenge::FileInputSource.new('commands.txt')
RobotChallenge::StringInputSource.new('PLACE 0,0,NORTH')
RobotChallenge::ArrayInputSource.new(['PLACE 0,0,NORTH', 'MOVE'])

# Factory methods for easy creation
RobotChallenge::InputSourceFactory.create($stdin)
RobotChallenge::InputSourceFactory.create('commands.txt')
RobotChallenge::InputSourceFactory.create(['PLACE 0,0,NORTH'])
```

### Adding New Input Sources

To add support for new input sources, simply implement the `InputSource` interface:

```ruby
# Example: Add support for network input
class NetworkInputSource < RobotChallenge::InputSource
  def initialize(url)
    @url = url
  end

  def each_line(&block)
    require 'net/http'
    response = Net::HTTP.get_response(URI(@url))
    response.body.each_line(&block)
  end
end

# Use the new input source
app = Application.new(input_source: NetworkInputSource.new('http://api.example.com/commands'))
```

### Minimal Changes Required

- **Single line** to add new input source: `class NewInputSource < InputSource`
- **No code changes** needed for existing functionality
- **Backward compatible** with all existing input sources
- **Automatic detection** via `InputSourceFactory.create()`

## Output Format Resilience

The application is highly resilient to changes in output formats and requires **minimal changes** to support new formats:

### Supported Output Formats

```bash
# Text format (default)
./bin/robot_challenge
echo "PLACE 0,0,NORTH" | ./bin/robot_challenge

# JSON format
./bin/robot_challenge -o json
ROBOT_OUTPUT_FORMAT=json ./bin/robot_challenge

# XML format
./bin/robot_challenge -o xml
ROBOT_OUTPUT_FORMAT=xml ./bin/robot_challenge

# CSV format
./bin/robot_challenge -o csv
ROBOT_OUTPUT_FORMAT=csv ./bin/robot_challenge

# Quiet mode (no output)
./bin/robot_challenge -o quiet
ROBOT_OUTPUT_FORMAT=quiet ./bin/robot_challenge
```

### Output Format Abstraction

The application uses a flexible output formatter abstraction:

```ruby
# Built-in output formatters
RobotChallenge::TextOutputFormatter.new
RobotChallenge::JsonOutputFormatter.new
RobotChallenge::XmlOutputFormatter.new
RobotChallenge::CsvOutputFormatter.new
RobotChallenge::QuietOutputFormatter.new

# Factory methods for easy creation
RobotChallenge::OutputFormatterFactory.create('json')
RobotChallenge::OutputFormatterFactory.create('xml')
RobotChallenge::OutputFormatterFactory.from_environment
```

### Adding New Output Formats

To add support for new output formats, simply implement the `OutputFormatter` interface:

```ruby
# Example: Add support for YAML output
class YamlOutputFormatter < RobotChallenge::OutputFormatter
  def format_report(robot)
    require 'yaml'
    {
      status: 'success',
      type: 'report',
      data: {
        position: { x: robot.position.x, y: robot.position.y },
        direction: robot.direction.name,
        formatted: robot.report
      }
    }.to_yaml
  end

  def format_error(message, error_type = :general_error)
    require 'yaml'
    {
      status: 'error',
      type: error_type.to_s,
      message: message
    }.to_yaml
  end

  # ... implement other methods
end

# Use the new output formatter
app = Application.new(output_formatter: YamlOutputFormatter.new)
```

### Minimal Changes Required

- **Single line** to add new output formatter: `class NewOutputFormatter < OutputFormatter`
- **No code changes** needed for existing functionality
- **Backward compatible** with all existing output formats
- **Automatic detection** via `OutputFormatterFactory.create()`

## Examples

```
PLACE 0,0,NORTH
MOVE
REPORT
# Output: 0,1,NORTH

PLACE 0,0,NORTH
LEFT
REPORT
# Output: 0,0,WEST

PLACE 1,2,EAST
MOVE
MOVE
LEFT
MOVE
REPORT
# Output: 3,3,NORTH
```

## Testing

Run the test suite:

```bash
# Run all tests
bundle exec rspec

# Run specific test categories
bundle exec rspec spec/robot_spec.rb
bundle exec rspec spec/table_spec.rb
bundle exec rspec spec/commands/
bundle exec rspec spec/integration/

# Run with coverage
COVERAGE=true bundle exec rspec
```

## Docker

Build and run with Docker:

```bash
# Build the image
docker build -t robot-challenge .

# Run the application
docker run -it robot-challenge

# Run with Redis
docker run -it --network host robot-challenge
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Run the test suite
6. Submit a pull request

## License

This project is licensed under the MIT License.
