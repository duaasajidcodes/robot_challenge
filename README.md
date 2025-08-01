# Robot Challenge

A Ruby implementation of a toy robot simulation that moves on a 5x5 tabletop.

## Description

This application simulates a toy robot moving on a square tabletop of dimensions 5 units x 5 units. The robot can be placed, moved, rotated, and can report its position while being prevented from falling off the table.

## Requirements

- Ruby 3.0 or higher
- Bundler

## Installation

```bash
git clone <repository-url>
cd robot_challenge
bundle install
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

## Commands

- `PLACE X,Y,F` - Places the robot at position (X,Y) facing direction F (NORTH, SOUTH, EAST, WEST)
- `MOVE` - Moves the robot one unit forward in the current direction
- `LEFT` - Rotates the robot 90 degrees counter-clockwise
- `RIGHT` - Rotates the robot 90 degrees clockwise
- `REPORT` - Outputs the current position and direction of the robot

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

# File input (positional argument)
./bin/robot_challenge commands.txt

# File input (explicit flag)
./bin/robot_challenge -i commands.txt

# File input (stdin redirection)
./bin/robot_challenge < commands.txt
```

### Input Source Abstraction

The application uses a flexible input source abstraction:

```ruby
# Built-in input sources
RobotChallenge::StdinInputSource.new($stdin)
RobotChallenge::FileInputSource.new('commands.txt')
RobotChallenge::StringInputSource.new("PLACE 0,0,NORTH\nMOVE")
RobotChallenge::ArrayInputSource.new(['PLACE 0,0,NORTH', 'MOVE'])

# Factory methods for easy creation
RobotChallenge::InputSourceFactory.from_file_path('commands.txt')
RobotChallenge::InputSourceFactory.from_string("PLACE 0,0,NORTH")
RobotChallenge::InputSourceFactory.from_array(['PLACE 0,0,NORTH'])
RobotChallenge::InputSourceFactory.from_stdin($stdin)
```

### Adding New Input Sources

To add support for new input sources, simply implement the `InputSource` interface:

```ruby
# Example: Add support for network input
class NetworkInputSource < RobotChallenge::InputSource
  def initialize(socket)
    @socket = socket
  end

  def each_line(&block)
    @socket.each_line(&block)
  end

  def close
    @socket.close
  end
end

# Use the new input source
app = RobotChallenge::Application.new(
  input_source: NetworkInputSource.new(socket)
)
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

## Environment Configuration

The application supports multiple environment configurations through `.env` files:

### Environment Files

- `.env.test` - Test environment configuration
- `.env.development` - Development environment configuration  
- `.env.production` - Production environment configuration

### Configuration Options

| Variable | Description | Default |
|----------|-------------|---------|
| `ROBOT_TABLE_WIDTH` | Table width | 5 |
| `ROBOT_TABLE_HEIGHT` | Table height | 5 |
| `ROBOT_TEST_MODE` | Enable test mode | false |
| `ROBOT_DEBUG_MODE` | Enable debug mode | false |
| `ROBOT_OUTPUT_FORMAT` | Output format | text |
| `ROBOT_QUIET_MODE` | Suppress output | false |
| `ROBOT_MAX_COMMANDS` | Maximum commands to process | 100000 |
| `ROBOT_TIMEOUT_SECONDS` | Command timeout | 60 |
| `ROBOT_TEST_DATA_DIR` | Test data directory | test_data |
| `ROBOT_LOG_LEVEL` | Log level | info |

### Usage Examples

```bash
# Run with test environment
./bin/test

# Run with development environment
./bin/dev

# Run with custom table size
ROBOT_TABLE_WIDTH=10 ROBOT_TABLE_HEIGHT=8 ./bin/robot_challenge

# Run with debug mode
ROBOT_DEBUG_MODE=true ./bin/robot_challenge
```

## Testing

```bash
# Run all tests with test environment
./bin/test

# Run specific test files
./bin/test spec/robot_challenge/

# Run with coverage
./bin/test --format documentation

# Run linting
bundle exec rubocop

# Auto-correct linting issues
bundle exec rubocop -a
```

## Docker

### Build and Run

```bash
# Build the Docker image
docker build -t robot_challenge .

# Run interactively
docker run -it robot_challenge

# Run with test data
docker run -i robot_challenge < test_data/example_commands.txt
```

## Project Structure

```
robot_challenge/
├── lib/                    # Main application code
│   ├── robot_challenge/    # Core classes and modules
│   └── robot_challenge.rb  # Main entry point
├── spec/                   # RSpec tests
├── bin/                    # Executable scripts
├── test_data/              # Sample input files
├── .github/workflows/      # CI/CD configuration
├── Dockerfile              # Docker configuration
├── Gemfile                 # Ruby dependencies
└── README.md              # This file
```

## Architecture

The application follows SOLID principles and uses the Command Pattern for maximum extensibility:

- **Robot**: Core entity with position and direction
- **Table**: Boundary validation and constraints  
- **Command Pattern**: Each command is a self-contained class
- **CommandFactory**: Handles command parsing and creation
- **CommandRegistry**: Manages available commands
- **CommandProcessor**: Executes commands using polymorphism
- **Application**: Main orchestration and I/O handling

### Adding New Commands

Adding new commands requires **zero modifications** to existing code:

```ruby
# 1. Create new command class
class MyCustomCommand < RobotChallenge::Commands::Command
  def execute(robot)
    # Your command logic here
    output_result("Custom command executed!")
  end
end

# 2. Register with application
app.register_command('CUSTOM', MyCustomCommand)

# 3. Use immediately!
app.process_command("CUSTOM")
```

**Examples of easy extensions:**
- `STATUS` - Show detailed robot information
- `RESET` - Reset robot to unplaced state
- `HISTORY` - Show movement history
- `TELEPORT X,Y` - Jump to position
- `VALIDATE` - Check robot state

See `bin/extensibility_demo` for a live demonstration!

## SOLID Principles Compliance

The application follows SOLID principles to ensure maintainable and extensible code:

### **Single Responsibility Principle (SRP)**
Each class has a single, well-defined responsibility:

- **`CommandParserService`** - Responsible for parsing command strings into command objects
- **`CommandDispatcher`** - Responsible for executing commands and handling results
- **`CommandProcessor`** - Coordinates parsing and dispatching (facade pattern)
- **`CliArgumentParser`** - Responsible for parsing command line arguments
- **`OutputFormatter`** - Responsible for formatting output in different formats
- **`InputSource`** - Responsible for reading input from different sources

### **Open/Closed Principle (OCP)**
The application is open for extension but closed for modification:

- **Commands**: New commands can be added without modifying existing code
- **Output Formats**: New output formats can be added by implementing `OutputFormatter`
- **Input Sources**: New input sources can be added by implementing `InputSource`
- **Parsers**: New command parsers can be added to the factory

### **Liskov Substitution Principle (LSP)**
All implementations can be substituted for their base classes:

- All `OutputFormatter` implementations can be used interchangeably
- All `InputSource` implementations can be used interchangeably
- All `Command` implementations can be used interchangeably

### **Interface Segregation Principle (ISP)**
Interfaces are focused and specific:

- `OutputFormatter` has focused methods for different output types
- `InputSource` has a minimal interface for reading input
- `Command` has a focused interface for execution

### **Dependency Inversion Principle (DIP)**
High-level modules depend on abstractions:

- `Application` depends on `InputSource` and `OutputFormatter` abstractions
- `CommandProcessor` depends on `CommandParserService` and `CommandDispatcher`
- `CommandFactory` depends on `CommandRegistry` abstraction

## License

MIT License
