#!/bin/bash
# Run multiple concurrent HTTP clients against the REST API server
# This demonstrates the engine working with multiple clients simultaneously

set -e

# Default values
NUM_CLIENTS=${1:-100}
SERVER_PORT=${2:-8080}
BASE_URL="http://localhost:${SERVER_PORT}"

echo "=================================================="
echo "Reddit Clone - Multiple Clients Demonstration"
echo "=================================================="
echo ""
echo "Configuration:"
echo "  Server URL: ${BASE_URL}"
echo "  Number of concurrent clients: ${NUM_CLIENTS}"
echo ""

# Check if server is running
echo "Checking if server is running..."
if ! curl -s "${BASE_URL}/health" > /dev/null 2>&1; then
    echo "✗ Error: Server is not running on port ${SERVER_PORT}"
    echo ""
    echo "Please start the server first:"
    echo "  gleam run -m server ${SERVER_PORT}"
    echo ""
    echo "Or use the automation script:"
    echo "  ./start_server.sh ${SERVER_PORT}"
    echo ""
    exit 1
fi
echo "✓ Server is running"
echo ""

# Run client simulator with concurrent HTTP clients
echo "Starting ${NUM_CLIENTS} concurrent HTTP clients..."
echo "This will simulate realistic Reddit-like behavior:"
echo "  - User registration"
echo "  - Creating/joining subreddits (Zipf distribution)"
echo "  - Creating posts and comments"
echo "  - Voting on content"
echo "  - Sending direct messages"
echo ""

gleam run -m client_simulator "${BASE_URL}" "${NUM_CLIENTS}"

echo ""
echo "=================================================="
echo "Multiple client demonstration completed!"
echo "=================================================="
