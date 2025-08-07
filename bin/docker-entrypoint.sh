#!/bin/bash
set -e

# Run CLI mode if --cli flag is provided, otherwise interactive mode
if [ "$1" = "--cli" ]; then
    exec ruby -Ilib bin/robot_challenge "${@:2}"
else
    exec ruby -Ilib bin/robot_challenge_interactive.rb "$@"
fi 