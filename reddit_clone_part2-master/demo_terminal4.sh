#!/bin/bash
# Demo Script for Terminal 4 - Demonstrates Direct Messaging and System Stats
# Run this AFTER demo_terminal2.sh and demo_terminal3.sh complete

set -e

BASE_URL="http://localhost:8080"

echo "========================================"
echo "Terminal 4: Messaging & System Stats"
echo "========================================"
echo ""

# Check if server is running
echo "Checking server connection..."
if ! curl -s "${BASE_URL}/health" > /dev/null 2>&1; then
    echo "✗ Error: Server is not running!"
    exit 1
fi
echo "✓ Server is running"
echo ""

# Give time for previous terminals to complete
echo "Waiting for previous operations..."
sleep 3
echo ""

# 1. Send direct messages
echo "1. Sending direct messages..."
echo "-----------------------------------"
echo ""

echo "Command: curl -X POST ${BASE_URL}/dms -d \"from_user_id=user_alice\" -d \"to_user_id=user_bob\" -d \"content=Hey Bob, thanks for your comment!\""
echo "Request Body:"
echo "  from_user_id=user_alice"
echo "  to_user_id=user_bob"
echo "  content=Hey Bob, thanks for your comment!"
echo "Response:"
curl -X POST "${BASE_URL}/dms" \
  -d "from_user_id=user_alice" \
  -d "to_user_id=user_bob" \
  -d "content=Hey Bob, thanks for your comment!" 2>/dev/null | python3 -m json.tool 2>/dev/null || curl -X POST "${BASE_URL}/dms" -d "from_user_id=user_alice" -d "to_user_id=user_bob" -d "content=Hey Bob, thanks for your comment!" 2>/dev/null
sleep 0.5
echo ""

echo "Command: curl -X POST ${BASE_URL}/dms -d \"from_user_id=user_bob\" -d \"to_user_id=user_alice\" -d \"content=You're welcome Alice! Great post.\""
echo "Request Body:"
echo "  from_user_id=user_bob"
echo "  to_user_id=user_alice"
echo "  content=You're welcome Alice! Great post."
echo "Response:"
curl -X POST "${BASE_URL}/dms" \
  -d "from_user_id=user_bob" \
  -d "to_user_id=user_alice" \
  -d "content=You're welcome Alice! Great post." 2>/dev/null | python3 -m json.tool 2>/dev/null || curl -X POST "${BASE_URL}/dms" -d "from_user_id=user_bob" -d "to_user_id=user_alice" -d "content=You're welcome Alice! Great post." 2>/dev/null
sleep 0.5
echo ""

echo "Command: curl -X POST ${BASE_URL}/dms -d \"from_user_id=user_charlie\" -d \"to_user_id=user_alice\" -d \"content=Love your content!\""
echo "Request Body:"
echo "  from_user_id=user_charlie"
echo "  to_user_id=user_alice"
echo "  content=Love your content!"
echo "Response:"
curl -X POST "${BASE_URL}/dms" \
  -d "from_user_id=user_charlie" \
  -d "to_user_id=user_alice" \
  -d "content=Love your content!" 2>/dev/null | python3 -m json.tool 2>/dev/null || curl -X POST "${BASE_URL}/dms" -d "from_user_id=user_charlie" -d "to_user_id=user_alice" -d "content=Love your content!" 2>/dev/null
sleep 0.5
echo ""

echo "Command: curl -X POST ${BASE_URL}/dms -d \"from_user_id=user_alice\" -d \"to_user_id=user_charlie\" -d \"content=Thank you Charlie!\""
echo "Request Body:"
echo "  from_user_id=user_alice"
echo "  to_user_id=user_charlie"
echo "  content=Thank you Charlie!"
echo "Response:"
curl -X POST "${BASE_URL}/dms" \
  -d "from_user_id=user_alice" \
  -d "to_user_id=user_charlie" \
  -d "content=Thank you Charlie!" 2>/dev/null | python3 -m json.tool 2>/dev/null || curl -X POST "${BASE_URL}/dms" -d "from_user_id=user_alice" -d "to_user_id=user_charlie" -d "content=Thank you Charlie!" 2>/dev/null
sleep 0.5
echo ""
echo "✓ Sent 4 direct messages between users"
echo ""

# 2. Get messages
echo "2. Getting user messages..."
echo "-----------------------------------"
echo ""

echo "Command: curl ${BASE_URL}/users/user_alice/dms"
echo "Request Body: (none)"
echo "Alice's messages:"
curl -s "${BASE_URL}/users/user_alice/dms" | python3 -m json.tool 2>/dev/null || curl -s "${BASE_URL}/users/user_alice/dms"
sleep 0.5
echo ""

echo "Command: curl ${BASE_URL}/users/user_bob/dms"
echo "Request Body: (none)"
echo "Bob's messages:"
curl -s "${BASE_URL}/users/user_bob/dms" | python3 -m json.tool 2>/dev/null || curl -s "${BASE_URL}/users/user_bob/dms"
sleep 0.5
echo ""
echo "✓ Retrieved user messages"
echo ""

# 3. Get user karma
echo "3. Getting user karma..."
echo "-----------------------------------"
echo ""

echo "Command: curl ${BASE_URL}/users/user_alice/karma"
echo "Request Body: (none)"
echo "Response:"
curl -s "${BASE_URL}/users/user_alice/karma" | python3 -m json.tool 2>/dev/null || curl -s "${BASE_URL}/users/user_alice/karma"
sleep 0.5
echo ""

echo "Command: curl ${BASE_URL}/users/user_bob/karma"
echo "Request Body: (none)"
echo "Response:"
curl -s "${BASE_URL}/users/user_bob/karma" | python3 -m json.tool 2>/dev/null || curl -s "${BASE_URL}/users/user_bob/karma"
sleep 0.5
echo ""

echo "Command: curl ${BASE_URL}/users/user_charlie/karma"
echo "Request Body: (none)"
echo "Response:"
curl -s "${BASE_URL}/users/user_charlie/karma" | python3 -m json.tool 2>/dev/null || curl -s "${BASE_URL}/users/user_charlie/karma"
sleep 0.5
echo ""
echo "✓ Retrieved user karma"
echo ""

# 4. Get system metrics
echo "4. Getting system metrics..."
echo "-----------------------------------"
echo ""

echo "Command: curl ${BASE_URL}/metrics"
echo "Request Body: (none)"
echo "Response:"
curl -s "${BASE_URL}/metrics" | python3 -m json.tool 2>/dev/null || curl -s "${BASE_URL}/metrics"
sleep 0.5
echo ""
echo "✓ Retrieved system metrics"
echo ""

# 5. Health check
echo "5. Health check..."
echo "-----------------------------------"
echo ""

echo "Command: curl ${BASE_URL}/health"
echo "Request Body: (none)"
echo "Response:"
curl -s "${BASE_URL}/health" | python3 -m json.tool 2>/dev/null || curl -s "${BASE_URL}/health"
echo ""
echo "✓ Health check completed"
echo ""

echo "========================================"
echo "✓ Terminal 4 operations completed!"
echo "========================================"
echo ""
echo "Summary of all operations:"
echo "  - Terminal 2: Created users & subreddits"
echo "  - Terminal 3: Created posts, comments & votes"
echo "  - Terminal 4: Sent messages & checked stats"
echo ""
echo "All 18 API endpoints have been tested!"
echo "========================================"
