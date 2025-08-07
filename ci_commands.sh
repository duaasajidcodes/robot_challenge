#!/bin/bash
set -e

echo "Correct CI Pipeline Commands:"
echo "============================="
echo ""
echo "Example 1:"
echo 'echo -e "PLACE 0,0,NORTH\nMOVE\nREPORT" | docker run -i robot-challenge | grep "0,1,NORTH"'
echo ""
echo "Example 2:"
echo 'echo -e "PLACE 0,0,NORTH\nLEFT\nREPORT" | docker run -i robot-challenge | grep "0,0,WEST"'
echo ""
echo "Example 3:"
echo 'echo -e "PLACE 1,2,EAST\nMOVE\nMOVE\nLEFT\nMOVE\nREPORT" | docker run -i robot-challenge | grep "3,3,NORTH"'
echo ""
echo "Or use the comprehensive test:"
echo "./ci_test.sh" 