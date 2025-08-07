#!/bin/bash
set -e

# Check if running in CI environment (non-interactive) or if --cli flag is provided
if [ "$1" = "--cli" ] || [ ! -t 0 ] || [ "$CI" = "true" ]; then
    # Run CLI mode for CI/non-interactive environments
    exec ruby -Ilib bin/robot_challenge "${@:2}"
else
    # Run interactive mode for interactive environments
    exec ruby -Ilib bin/robot_challenge_interactive.rb "$@"
fi 