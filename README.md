# Robot Challenge

A Ruby implementation of a toy robot simulation with advanced features including Redis caching, comprehensive testing, and extensible architecture.

## Features

- **Core Robot Simulation**: Place, move, rotate, and report robot position
- **Redis Caching**: High-performance caching system with monitoring
- **Multiple Output Formats**: Text, JSON, XML, CSV, and quiet modes
- **Flexible Input Sources**: Stdin, files, strings, and arrays
- **Extensible Architecture**: Easy to add new commands and formats
- **Comprehensive Testing**: 300+ tests with 90%+ coverage
- **Docker Support**: Containerized deployment ready

## Requirements

- Ruby 3.0+
- Bundler
- Redis (optional, for caching)

## Installation

```bash
git clone <repository-url>
cd robot_challenge
bundle install
```

## Quick Start

```bash
# Basic usage
echo "PLACE 0,0,NORTH\nMOVE\nREPORT" | bundle exec ruby bin/robot_challenge

# JSON output
echo "PLACE 0,0,NORTH\nMOVE\nREPORT" | bundle exec ruby bin/robot_challenge -o json

# With input file
bundle exec ruby bin/robot_challenge < test_data/example_1.txt

# Redis caching demo
bundle exec ruby bin/cache_demo.rb
```

## Commands

- `PLACE X,Y,F` - Place robot at position (X,Y) facing direction F
- `MOVE` - Move robot one unit forward
- `LEFT` - Rotate robot 90° counter-clockwise
- `RIGHT` - Rotate robot 90° clockwise
- `REPORT` - Report current position and direction
- `EXIT` - Exit the application (aliases: `QUIT`, `BYE`)

## Configuration

### Environment Variables

```bash
ROBOT_TABLE_WIDTH=10      # Table width (default: 5)
ROBOT_TABLE_HEIGHT=8      # Table height (default: 5)
ROBOT_OUTPUT_FORMAT=json  # Output format (text, json, xml, csv, quiet)
ROBOT_CACHE_DEBUG=1       # Enable cache debugging
```

### Command Line Options

```bash
bundle exec ruby bin/robot_challenge --help
```

## Architecture

### Core Components

- **Application**: Main orchestrator with dependency injection
- **CommandProcessor**: Coordinates command parsing and execution
- **Robot**: Core robot entity with state management
- **Table**: Boundary validation and position management
- **Commands**: Extensible command system using Command pattern

### Design Patterns

- **Command Pattern**: Each command is a separate class
- **Factory Pattern**: Object creation and input/output formatting
- **Registry Pattern**: Command registration and management
- **Dependency Injection**: Loose coupling and testability
- **Strategy Pattern**: Pluggable input sources and output formats

### SOLID Principles

- **Single Responsibility**: Each class has one clear purpose
- **Open/Closed**: Extensible without modifying existing code
- **Liskov Substitution**: All implementations are substitutable
- **Interface Segregation**: Focused, minimal interfaces
- **Dependency Inversion**: Depends on abstractions, not concretions

## Redis Caching

The application includes a sophisticated Redis caching system:

```ruby
# Create cacheable robot
cache = RobotChallenge::Cache.create_redis_cache
cacheable_robot = RobotChallenge::Cache.create_cacheable_robot(robot, cache: cache)

# Performance benefits
# - 62.8% faster command execution
# - Automatic state caching
# - Intelligent cache invalidation
# - Health monitoring and statistics
```

## Testing

```bash
# Run all tests
bundle exec rspec

# Run specific test categories
bundle exec rspec spec/robot_spec.rb
bundle exec rspec spec/cache/
bundle exec rspec spec/integration/

# With coverage
COVERAGE=true bundle exec rspec
```

## Extensibility

### Adding New Commands

```ruby
class CustomCommand < RobotChallenge::Commands::Command
  def execute(robot)
    # Custom logic
    success_result("Custom action completed")
  end
end

# Register the command
app.register_command('CUSTOM', CustomCommand)
```

### Adding New Output Formats

```ruby
class YamlOutputFormatter < RobotChallenge::OutputFormatter
  def format_report(robot)
    require 'yaml'
    { position: robot.position, direction: robot.direction }.to_yaml
  end
end

# Use the formatter
app = Application.new(output_formatter: YamlOutputFormatter.new)
```

### Adding New Input Sources

```ruby
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
```

## Docker

```bash
# Build and run
docker build -t robot-challenge .
docker run -it robot-challenge

# With Redis
docker run -it --network host robot-challenge
```

## Examples

```bash
# Example 1: Basic movement
PLACE 0,0,NORTH
MOVE
REPORT
# Output: 0,1,NORTH

# Example 2: Rotation
PLACE 0,0,NORTH
LEFT
REPORT
# Output: 0,0,WEST

# Example 3: Complex sequence
PLACE 1,2,EAST
MOVE
MOVE
LEFT
MOVE
REPORT
# Output: 3,3,NORTH
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Run the test suite
6. Submit a pull request
