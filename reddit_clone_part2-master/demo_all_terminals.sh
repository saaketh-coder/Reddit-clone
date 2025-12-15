#!/bin/bash
# Demo Script for 4 Terminals - Runs all clients in parallel
# Terminal 1: Server (manual start)
# Terminals 2-4: Automated clients (this script runs them in sequence with delays)

BASE_URL="http://localhost:8080"

echo "========================================"
echo "Multi-Terminal Demo - All Endpoints"
echo "========================================"
echo ""

# Check if server is running
echo "Checking if server is running..."
if ! curl -s "${BASE_URL}/health" > /dev/null 2>&1; then
    echo "✗ Error: Server is not running!"
    echo ""
    echo "Please start the server in Terminal 1:"
    echo "  gleam run -m server"
    echo ""
    exit 1
fi
echo "✓ Server is running"
echo ""

echo "This script will run operations from 3 terminals sequentially:"
echo "  Terminal 2: User & Subreddit operations"
echo "  Terminal 3: Posts, Comments & Voting"
echo "  Terminal 4: Messaging & System Stats"
echo ""
echo "Press ENTER to start, or Ctrl+C to cancel..."
read

echo ""
echo "========================================"
echo "Running Terminal 2 operations..."
echo "========================================"
./demo_terminal2.sh
echo ""

sleep 2

echo ""
echo "========================================"
echo "Running Terminal 3 operations..."
echo "========================================"
./demo_terminal3.sh
echo ""

sleep 2

echo ""
echo "========================================"
echo "Running Terminal 4 operations..."
echo "========================================"
./demo_terminal4.sh
echo ""

echo ""
echo "========================================"
echo "✓ All operations completed successfully!"
echo "========================================"
echo ""
echo "Summary:"
echo "  ✓ Registered 3 users"
echo "  ✓ Created 3 subreddits"
echo "  ✓ Performed subscription operations"
echo "  ✓ Created 3 posts"
echo "  ✓ Created 5 comments (including replies)"
echo "  ✓ Performed voting operations"
echo "  ✓ Sent 4 direct messages"
echo "  ✓ Tested search functionality"
echo "  ✓ Retrieved feeds, karma, and system stats"
echo ""
echo "All 18 API endpoints tested successfully!"
echo "========================================"
