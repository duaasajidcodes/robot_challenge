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

## Testing

```bash
# Run all tests
bundle exec rspec

# Run with coverage
bundle exec rspec --format documentation

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
