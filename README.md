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
- `EXIT` or `QUIT` - Exits the application

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

## License

MIT License
