#!/bin/bash
# Demo Script for Terminal 3 - Demonstrates Posts, Comments, and Voting
# Run this AFTER demo_terminal2.sh completes

set -e

BASE_URL="http://localhost:8080"

echo "========================================"
echo "Terminal 3: Posts, Comments & Voting"
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

# Give time for Terminal 2 to complete
echo "Waiting for users and subreddits to be created..."
sleep 2
echo ""

# 1. Create posts
echo "1. Creating posts..."
echo "-----------------------------------"
echo ""

echo "Command: curl -X POST ${BASE_URL}/subreddits/r_programming/posts -d \"user_id=user_alice\" -d \"title=Learning Gleam\" -d \"content=Just started learning Gleam and it's amazing!\" -d \"is_repost=false\""
echo "Request Body:"
echo "  user_id=user_alice"
echo "  title=Learning Gleam"
echo "  content=Just started learning Gleam and it's amazing!"
echo "  is_repost=false"
echo "Response:"
curl -X POST "${BASE_URL}/subreddits/r_programming/posts" \
  -d "user_id=user_alice" \
  -d "title=Learning Gleam" \
  -d "content=Just started learning Gleam and it's amazing!" \
  -d "is_repost=false" 2>/dev/null | python3 -m json.tool 2>/dev/null || curl -X POST "${BASE_URL}/subreddits/r_programming/posts" -d "user_id=user_alice" -d "title=Learning Gleam" -d "content=Just started learning Gleam and it's amazing!" -d "is_repost=false" 2>/dev/null
sleep 0.5
echo ""

echo "Command: curl -X POST ${BASE_URL}/subreddits/r_programming/posts -d \"user_id=user_bob\" -d \"title=REST APIs in Gleam\" -d \"content=Building REST APIs with Wisp is so easy\" -d \"is_repost=false\""
echo "Request Body:"
echo "  user_id=user_bob"
echo "  title=REST APIs in Gleam"
echo "  content=Building REST APIs with Wisp is so easy"
echo "  is_repost=false"
echo "Response:"
curl -X POST "${BASE_URL}/subreddits/r_programming/posts" \
  -d "user_id=user_bob" \
  -d "title=REST APIs in Gleam" \
  -d "content=Building REST APIs with Wisp is so easy" \
  -d "is_repost=false" 2>/dev/null | python3 -m json.tool 2>/dev/null || curl -X POST "${BASE_URL}/subreddits/r_programming/posts" -d "user_id=user_bob" -d "title=REST APIs in Gleam" -d "content=Building REST APIs with Wisp is so easy" -d "is_repost=false" 2>/dev/null
sleep 0.5
echo ""

echo "Command: curl -X POST ${BASE_URL}/subreddits/r_gaming/posts -d \"user_id=user_charlie\" -d \"title=Best Games 2025\" -d \"content=What are your favorite games this year?\" -d \"is_repost=false\""
echo "Request Body:"
echo "  user_id=user_charlie"
echo "  title=Best Games 2025"
echo "  content=What are your favorite games this year?"
echo "  is_repost=false"
echo "Response:"
curl -X POST "${BASE_URL}/subreddits/r_gaming/posts" \
  -d "user_id=user_charlie" \
  -d "title=Best Games 2025" \
  -d "content=What are your favorite games this year?" \
  -d "is_repost=false" 2>/dev/null | python3 -m json.tool 2>/dev/null || curl -X POST "${BASE_URL}/subreddits/r_gaming/posts" -d "user_id=user_charlie" -d "title=Best Games 2025" -d "content=What are your favorite games this year?" -d "is_repost=false" 2>/dev/null
sleep 0.5
echo ""
echo "✓ Created 3 posts across different subreddits"
echo ""

# 2. Vote on posts
echo "2. Voting on posts..."
echo "-----------------------------------"
echo ""

echo "Command: curl -X POST ${BASE_URL}/posts/post_1/votes -d \"user_id=user_bob\" -d \"is_upvote=true\""
echo "Request Body:"
echo "  user_id=user_bob"
echo "  is_upvote=true"
echo "Response:"
curl -X POST "${BASE_URL}/posts/post_1/votes" \
  -d "user_id=user_bob" \
  -d "is_upvote=true" 2>/dev/null | python3 -m json.tool 2>/dev/null || curl -X POST "${BASE_URL}/posts/post_1/votes" -d "user_id=user_bob" -d "is_upvote=true" 2>/dev/null
sleep 0.5
echo ""

echo "Command: curl -X POST ${BASE_URL}/posts/post_1/votes -d \"user_id=user_charlie\" -d \"is_upvote=true\""
echo "Request Body:"
echo "  user_id=user_charlie"
echo "  is_upvote=true"
echo "Response:"
curl -X POST "${BASE_URL}/posts/post_1/votes" \
  -d "user_id=user_charlie" \
  -d "is_upvote=true" 2>/dev/null | python3 -m json.tool 2>/dev/null || curl -X POST "${BASE_URL}/posts/post_1/votes" -d "user_id=user_charlie" -d "is_upvote=true" 2>/dev/null
sleep 0.5
echo ""

echo "Command: curl -X POST ${BASE_URL}/posts/post_2/votes -d \"user_id=user_alice\" -d \"is_upvote=true\""
echo "Request Body:"
echo "  user_id=user_alice"
echo "  is_upvote=true"
echo "Response:"
curl -X POST "${BASE_URL}/posts/post_2/votes" \
  -d "user_id=user_alice" \
  -d "is_upvote=true" 2>/dev/null | python3 -m json.tool 2>/dev/null || curl -X POST "${BASE_URL}/posts/post_2/votes" -d "user_id=user_alice" -d "is_upvote=true" 2>/dev/null
sleep 0.5
echo ""
echo "✓ Users voted on posts (upvotes)"
echo ""

# 3. Create comments
echo "3. Creating comments..."
echo "-----------------------------------"
echo ""

echo "Command: curl -X POST ${BASE_URL}/posts/post_1/comments -d \"user_id=user_bob\" -d \"content=Great post! I agree completely.\""
echo "Request Body:"
echo "  user_id=user_bob"
echo "  content=Great post! I agree completely."
echo "Response:"
curl -X POST "${BASE_URL}/posts/post_1/comments" \
  -d "user_id=user_bob" \
  -d "content=Great post! I agree completely." 2>/dev/null | python3 -m json.tool 2>/dev/null || curl -X POST "${BASE_URL}/posts/post_1/comments" -d "user_id=user_bob" -d "content=Great post! I agree completely." 2>/dev/null
sleep 0.5
echo ""

echo "Command: curl -X POST ${BASE_URL}/posts/post_1/comments -d \"user_id=user_charlie\" -d \"content=Thanks for sharing this!\""
echo "Request Body:"
echo "  user_id=user_charlie"
echo "  content=Thanks for sharing this!"
echo "Response:"
curl -X POST "${BASE_URL}/posts/post_1/comments" \
  -d "user_id=user_charlie" \
  -d "content=Thanks for sharing this!" 2>/dev/null | python3 -m json.tool 2>/dev/null || curl -X POST "${BASE_URL}/posts/post_1/comments" -d "user_id=user_charlie" -d "content=Thanks for sharing this!" 2>/dev/null
sleep 0.5
echo ""

echo "Command: curl -X POST ${BASE_URL}/posts/post_2/comments -d \"user_id=user_alice\" -d \"content=Wisp is indeed amazing!\""
echo "Request Body:"
echo "  user_id=user_alice"
echo "  content=Wisp is indeed amazing!"
echo "Response:"
curl -X POST "${BASE_URL}/posts/post_2/comments" \
  -d "user_id=user_alice" \
  -d "content=Wisp is indeed amazing!" 2>/dev/null | python3 -m json.tool 2>/dev/null || curl -X POST "${BASE_URL}/posts/post_2/comments" -d "user_id=user_alice" -d "content=Wisp is indeed amazing!" 2>/dev/null
sleep 0.5
echo ""
echo "✓ Created 3 comments on posts"
echo ""

# 4. Reply to comments
echo "4. Replying to comments..."
echo "-----------------------------------"
echo ""

echo "Command: curl -X POST ${BASE_URL}/comments/comment_1/replies -d \"user_id=user_alice\" -d \"content=Thank you so much!\""
echo "Request Body:"
echo "  user_id=user_alice"
echo "  content=Thank you so much!"
echo "Response:"
curl -X POST "${BASE_URL}/comments/comment_1/replies" \
  -d "user_id=user_alice" \
  -d "content=Thank you so much!" 2>/dev/null | python3 -m json.tool 2>/dev/null || curl -X POST "${BASE_URL}/comments/comment_1/replies" -d "user_id=user_alice" -d "content=Thank you so much!" 2>/dev/null
sleep 0.5
echo ""

echo "Command: curl -X POST ${BASE_URL}/comments/comment_2/replies -d \"user_id=user_alice\" -d \"content=You're welcome!\""
echo "Request Body:"
echo "  user_id=user_alice"
echo "  content=You're welcome!"
echo "Response:"
curl -X POST "${BASE_URL}/comments/comment_2/replies" \
  -d "user_id=user_alice" \
  -d "content=You're welcome!" 2>/dev/null | python3 -m json.tool 2>/dev/null || curl -X POST "${BASE_URL}/comments/comment_2/replies" -d "user_id=user_alice" -d "content=You're welcome!" 2>/dev/null
sleep 0.5
echo ""
echo "✓ Created 2 replies to comments"
echo ""

# 5. Vote on comments
echo "5. Voting on comments..."
echo "-----------------------------------"
echo ""

echo "Command: curl -X POST ${BASE_URL}/comments/comment_1/votes -d \"user_id=user_charlie\" -d \"is_upvote=true\""
echo "Request Body:"
echo "  user_id=user_charlie"
echo "  is_upvote=true"
echo "Response:"
curl -X POST "${BASE_URL}/comments/comment_1/votes" \
  -d "user_id=user_charlie" \
  -d "is_upvote=true" 2>/dev/null | python3 -m json.tool 2>/dev/null || curl -X POST "${BASE_URL}/comments/comment_1/votes" -d "user_id=user_charlie" -d "is_upvote=true" 2>/dev/null
sleep 0.5
echo ""

echo "Command: curl -X POST ${BASE_URL}/comments/comment_2/votes -d \"user_id=user_bob\" -d \"is_upvote=true\""
echo "Request Body:"
echo "  user_id=user_bob"
echo "  is_upvote=true"
echo "Response:"
curl -X POST "${BASE_URL}/comments/comment_2/votes" \
  -d "user_id=user_bob" \
  -d "is_upvote=true" 2>/dev/null | python3 -m json.tool 2>/dev/null || curl -X POST "${BASE_URL}/comments/comment_2/votes" -d "user_id=user_bob" -d "is_upvote=true" 2>/dev/null
sleep 0.5
echo ""
echo "✓ Users voted on comments"
echo ""

# 6. Get user feeds
echo "6. Getting user feeds..."
echo "-----------------------------------"
echo ""

echo "Command: curl ${BASE_URL}/users/user_alice/feed"
echo "Request Body: (none)"
echo "Alice's feed:"
curl -s "${BASE_URL}/users/user_alice/feed" | python3 -m json.tool 2>/dev/null || curl -s "${BASE_URL}/users/user_alice/feed"
sleep 0.5
echo ""

echo "Command: curl ${BASE_URL}/users/user_bob/feed"
echo "Request Body: (none)"
echo "Bob's feed:"
curl -s "${BASE_URL}/users/user_bob/feed" | python3 -m json.tool 2>/dev/null || curl -s "${BASE_URL}/users/user_bob/feed"
sleep 0.5
echo ""
echo "✓ Retrieved user feeds"
echo ""

echo "========================================"
echo "✓ Terminal 3 operations completed!"
echo "========================================"
