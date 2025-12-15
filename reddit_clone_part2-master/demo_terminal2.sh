#!/bin/bash
# Demo Script for Terminal 2 - Demonstrates User Management and Subreddit Operations
# Run this in Terminal 2 while server runs in Terminal 1

set -e

BASE_URL="http://localhost:8080"

echo "========================================"
echo "Terminal 2: User & Subreddit Operations"
echo "========================================"
echo ""

# Check if server is running
echo "Checking server connection..."
if ! curl -s "${BASE_URL}/health" > /dev/null 2>&1; then
    echo "✗ Error: Server is not running!"
    echo "Please start the server in Terminal 1:"
    echo "  gleam run -m server"
    exit 1
fi
echo "✓ Server is running"
echo ""

# 1. Register users
echo "1. Registering users..."
echo "-----------------------------------"
echo ""

echo "Command: curl -X POST ${BASE_URL}/users -d \"username=alice\""
echo "Request Body: username=alice"
echo "Response:"
curl -X POST "${BASE_URL}/users" -d "username=alice" 2>/dev/null | python3 -m json.tool 2>/dev/null || curl -X POST "${BASE_URL}/users" -d "username=alice" 2>/dev/null
sleep 0.5
echo ""

echo "Command: curl -X POST ${BASE_URL}/users -d \"username=bob\""
echo "Request Body: username=bob"
echo "Response:"
curl -X POST "${BASE_URL}/users" -d "username=bob" 2>/dev/null | python3 -m json.tool 2>/dev/null || curl -X POST "${BASE_URL}/users" -d "username=bob" 2>/dev/null
sleep 0.5
echo ""

echo "Command: curl -X POST ${BASE_URL}/users -d \"username=charlie\""
echo "Request Body: username=charlie"
echo "Response:"
curl -X POST "${BASE_URL}/users" -d "username=charlie" 2>/dev/null | python3 -m json.tool 2>/dev/null || curl -X POST "${BASE_URL}/users" -d "username=charlie" 2>/dev/null
sleep 0.5
echo ""
echo "✓ Registered 3 users: alice, bob, charlie"
echo ""

# 2. Create subreddits
echo "2. Creating subreddits..."
echo "-----------------------------------"
echo ""

echo "Command: curl -X POST ${BASE_URL}/subreddits -d \"user_id=user_alice\" -d \"name=programming\" -d \"description=Programming discussions\""
echo "Request Body:"
echo "  user_id=user_alice"
echo "  name=programming"
echo "  description=Programming discussions"
echo "Response:"
curl -X POST "${BASE_URL}/subreddits" \
  -d "user_id=user_alice" \
  -d "name=programming" \
  -d "description=Programming discussions" 2>/dev/null | python3 -m json.tool 2>/dev/null || curl -X POST "${BASE_URL}/subreddits" -d "user_id=user_alice" -d "name=programming" -d "description=Programming discussions" 2>/dev/null
sleep 0.5
echo ""

echo "Command: curl -X POST ${BASE_URL}/subreddits -d \"user_id=user_bob\" -d \"name=gaming\" -d \"description=Gaming news and reviews\""
echo "Request Body:"
echo "  user_id=user_bob"
echo "  name=gaming"
echo "  description=Gaming news and reviews"
echo "Response:"
curl -X POST "${BASE_URL}/subreddits" \
  -d "user_id=user_bob" \
  -d "name=gaming" \
  -d "description=Gaming news and reviews" 2>/dev/null | python3 -m json.tool 2>/dev/null || curl -X POST "${BASE_URL}/subreddits" -d "user_id=user_bob" -d "name=gaming" -d "description=Gaming news and reviews" 2>/dev/null
sleep 0.5
echo ""

echo "Command: curl -X POST ${BASE_URL}/subreddits -d \"user_id=user_charlie\" -d \"name=technology\" -d \"description=Latest tech news\""
echo "Request Body:"
echo "  user_id=user_charlie"
echo "  name=technology"
echo "  description=Latest tech news"
echo "Response:"
curl -X POST "${BASE_URL}/subreddits" \
  -d "user_id=user_charlie" \
  -d "name=technology" \
  -d "description=Latest tech news" 2>/dev/null | python3 -m json.tool 2>/dev/null || curl -X POST "${BASE_URL}/subreddits" -d "user_id=user_charlie" -d "name=technology" -d "description=Latest tech news" 2>/dev/null
sleep 0.5
echo ""
echo "✓ Created 3 subreddits: programming, gaming, technology"
echo ""

# 3. Join subreddits
echo "3. Joining subreddits..."
echo "-----------------------------------"
echo ""

echo "Command: curl -X PUT ${BASE_URL}/users/user_alice/subscriptions/r_gaming"
echo "Request Body: (none)"
echo "Response:"
curl -X PUT "${BASE_URL}/users/user_alice/subscriptions/r_gaming" 2>/dev/null | python3 -m json.tool 2>/dev/null || curl -X PUT "${BASE_URL}/users/user_alice/subscriptions/r_gaming" 2>/dev/null
sleep 0.5
echo ""

echo "Command: curl -X PUT ${BASE_URL}/users/user_bob/subscriptions/r_programming"
echo "Request Body: (none)"
echo "Response:"
curl -X PUT "${BASE_URL}/users/user_bob/subscriptions/r_programming" 2>/dev/null | python3 -m json.tool 2>/dev/null || curl -X PUT "${BASE_URL}/users/user_bob/subscriptions/r_programming" 2>/dev/null
sleep 0.5
echo ""

echo "Command: curl -X PUT ${BASE_URL}/users/user_charlie/subscriptions/r_programming"
echo "Request Body: (none)"
echo "Response:"
curl -X PUT "${BASE_URL}/users/user_charlie/subscriptions/r_programming" 2>/dev/null | python3 -m json.tool 2>/dev/null || curl -X PUT "${BASE_URL}/users/user_charlie/subscriptions/r_programming" 2>/dev/null
sleep 0.5
echo ""
echo "✓ Users joined different subreddits"
echo ""

# 4. Get member counts
echo "4. Getting member counts..."
echo "-----------------------------------"
echo ""

echo "Command: curl ${BASE_URL}/subreddits/r_programming/members"
echo "Request Body: (none)"
echo "Response:"
curl -s "${BASE_URL}/subreddits/r_programming/members" | python3 -m json.tool 2>/dev/null || curl -s "${BASE_URL}/subreddits/r_programming/members"
sleep 0.5
echo ""

echo "Command: curl ${BASE_URL}/subreddits/r_gaming/members"
echo "Request Body: (none)"
echo "Response:"
curl -s "${BASE_URL}/subreddits/r_gaming/members" | python3 -m json.tool 2>/dev/null || curl -s "${BASE_URL}/subreddits/r_gaming/members"
sleep 0.5
echo ""
echo "✓ Retrieved member counts"
echo ""

# 5. Search operations
echo "5. Searching users and subreddits..."
echo "-----------------------------------"
echo ""

echo "Command: curl \"${BASE_URL}/search/usernames?q=ali\""
echo "Request Body: (none)"
echo "Response:"
curl -s "${BASE_URL}/search/usernames?q=ali" | python3 -m json.tool 2>/dev/null || curl -s "${BASE_URL}/search/usernames?q=ali"
sleep 0.5
echo ""

echo "Command: curl \"${BASE_URL}/search/subreddits?q=tech\""
echo "Request Body: (none)"
echo "Response:"
curl -s "${BASE_URL}/search/subreddits?q=tech" | python3 -m json.tool 2>/dev/null || curl -s "${BASE_URL}/search/subreddits?q=tech"
sleep 0.5
echo ""
echo "✓ Search operations completed"
echo ""

echo "========================================"
echo "✓ Terminal 2 operations completed!"
echo "========================================"
