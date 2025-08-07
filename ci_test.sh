#!/bin/bash
set -e

echo "Running CI tests for robot-challenge Docker image..."

# Test Example 1: Basic movement (PLACE 0,0,NORTH, MOVE, REPORT)
echo "Testing Example 1..."
result1=$(echo -e "PLACE 0,0,NORTH\nMOVE\nREPORT" | docker run -i robot-challenge | grep "0,1,NORTH" || echo "FAILED")
if [ "$result1" = "0,1,NORTH" ]; then
    echo "✅ Example 1: PASSED"
else
    echo "❌ Example 1: FAILED"
    exit 1
fi

# Test Example 2: Rotation (PLACE 0,0,NORTH, LEFT, REPORT)
echo "Testing Example 2..."
result2=$(echo -e "PLACE 0,0,NORTH\nLEFT\nREPORT" | docker run -i robot-challenge | grep "0,0,WEST" || echo "FAILED")
if [ "$result2" = "0,0,WEST" ]; then
    echo "✅ Example 2: PASSED"
else
    echo "❌ Example 2: FAILED"
    exit 1
fi

# Test Example 3: Complex sequence (PLACE 1,2,EAST, MOVE, MOVE, LEFT, MOVE, REPORT)
echo "Testing Example 3..."
result3=$(echo -e "PLACE 1,2,EAST\nMOVE\nMOVE\nLEFT\nMOVE\nREPORT" | docker run -i robot-challenge | grep "3,3,NORTH" || echo "FAILED")
if [ "$result3" = "3,3,NORTH" ]; then
    echo "✅ Example 3: PASSED"
else
    echo "❌ Example 3: FAILED"
    exit 1
fi

echo "🎉 All CI tests passed!" 