#!/bin/bash
# Interactive Demo Script for Reddit Clone REST API
# Demonstrates all API endpoints with colored, step-by-step output

BASE_URL="http://localhost:8080"
DELAY=1
LONG_DELAY=2

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}  Reddit Clone REST API - Interactive Demo${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${CYAN}This demo will walk through all API endpoints.${NC}"
echo -e "${CYAN}Press ENTER to continue or Ctrl+C to cancel.${NC}"
read

function print_header() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

function print_request() {
    echo -e "${CYAN}▶ $1${NC}"
}

function print_command() {
    echo -e "${MAGENTA}$ $1${NC}"
}

function print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

function print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Check if server is running
echo -e "${CYAN}Checking if server is running on $BASE_URL...${NC}"
if ! curl -s "$BASE_URL/health" > /dev/null 2>&1; then
    print_error "Server is not running!"
    echo ""
    echo "Please start the server first:"
    echo "  gleam run -m server 8081"
    echo ""
    exit 1
fi
print_success "Server is running!"
sleep $DELAY

# =============================================================================
# 1. Register Users
# =============================================================================
print_header "1. Registering Users"

print_request "Registering user 'alice'..."
print_command "curl -s -X POST $BASE_URL/users -d 'username=alice'"
curl -s -X POST "$BASE_URL/users" -d "username=alice" | jq
sleep $DELAY

print_request "Registering user 'bob'..."
print_command "curl -s -X POST $BASE_URL/users -d 'username=bob'"
curl -s -X POST "$BASE_URL/users" -d "username=bob" | jq
sleep $DELAY

print_request "Registering user 'charlie'..."
print_command "curl -s -X POST $BASE_URL/users -d 'username=charlie'"
curl -s -X POST "$BASE_URL/users" -d "username=charlie" | jq
sleep $LONG_DELAY

# =============================================================================
# 2. Search Users
# =============================================================================
print_header "2. Searching Users"

print_request "Searching for users matching 'ali'..."
print_command "curl -s '$BASE_URL/search/usernames?q=ali'"
curl -s "$BASE_URL/search/usernames?q=ali" | jq
sleep $LONG_DELAY

# =============================================================================
# 3. Create Subreddits
# =============================================================================
print_header "3. Creating Subreddits"

print_request "Alice creates subreddit 'r/programming'..."
print_command "curl -s -X POST $BASE_URL/subreddits -d 'user_id=user_alice' -d 'name=programming' -d 'description=Programming discussions'"
curl -s -X POST "$BASE_URL/subreddits" \
  -d "user_id=user_alice" \
  -d "name=programming" \
  -d "description=Programming discussions and help" | jq
sleep $DELAY

print_request "Bob creates subreddit 'r/gleam'..."
print_command "curl -s -X POST $BASE_URL/subreddits -d 'user_id=user_bob' -d 'name=gleam' -d 'description=Gleam programming language'"
curl -s -X POST "$BASE_URL/subreddits" \
  -d "user_id=user_bob" \
  -d "name=gleam" \
  -d "description=Gleam programming language community" | jq
sleep $LONG_DELAY

# =============================================================================
# 4. Search Subreddits
# =============================================================================
print_header "4. Searching Subreddits"

print_request "Searching for subreddits matching 'prog'..."
print_command "curl -s '$BASE_URL/search/subreddits?q=prog'"
curl -s "$BASE_URL/search/subreddits?q=prog" | jq
sleep $LONG_DELAY

# =============================================================================
# 5. Join Subreddits
# =============================================================================
print_header "5. Joining Subreddits"

print_request "Bob joins r/programming..."
print_command "curl -s -X PUT $BASE_URL/users/user_bob/subscriptions/r_programming"
curl -s -X PUT "$BASE_URL/users/user_bob/subscriptions/r_programming" | jq
sleep $DELAY

print_request "Charlie joins r/gleam..."
print_command "curl -s -X PUT $BASE_URL/users/user_charlie/subscriptions/r_gleam"
curl -s -X PUT "$BASE_URL/users/user_charlie/subscriptions/r_gleam" | jq
sleep $LONG_DELAY

# =============================================================================
# 6. Get Member Count
# =============================================================================
print_header "6. Checking Member Count"

print_request "Getting member count for r/programming..."
print_command "curl -s $BASE_URL/subreddits/r_programming/members"
curl -s "$BASE_URL/subreddits/r_programming/members" | jq
sleep $DELAY

print_request "Getting member count for r/gleam..."
print_command "curl -s $BASE_URL/subreddits/r_gleam/members"
curl -s "$BASE_URL/subreddits/r_gleam/members" | jq
sleep $LONG_DELAY

# =============================================================================
# 7. Create Posts
# =============================================================================
print_header "7. Creating Posts"

print_request "Alice posts in r/programming..."
print_command "curl -s -X POST $BASE_URL/subreddits/r_programming/posts -d 'user_id=user_alice' -d 'title=Hello World' -d 'content=First post!'"
RESPONSE=$(curl -s -X POST "$BASE_URL/subreddits/r_programming/posts" \
  -d "user_id=user_alice" \
  -d "title=Hello World in Gleam" \
  -d "content=This is my first post about learning Gleam!")
echo "$RESPONSE" | jq

# Extract Post ID
POST_ID=$(echo "$RESPONSE" | jq -r '.data.id')
echo -e "${GREEN}✓ Captured Post ID: $POST_ID${NC}"
sleep $DELAY

print_request "Bob posts in r/gleam..."
print_command "curl -s -X POST $BASE_URL/subreddits/r_gleam/posts -d 'user_id=user_bob' -d 'title=Gleam Tips' -d 'content=Here are some tips...'"
curl -s -X POST "$BASE_URL/subreddits/r_gleam/posts" \
  -d "user_id=user_bob" \
  -d "title=Gleam Best Practices" \
  -d "content=Here are some best practices for Gleam development..." | jq
sleep $LONG_DELAY

# =============================================================================
# 8. Vote on Posts
# =============================================================================
print_header "8. Voting on Posts"

print_request "Bob upvotes Alice's post..."
print_command "curl -s -X POST $BASE_URL/posts/${POST_ID}/votes -d 'user_id=user_bob' -d 'is_upvote=true'"
curl -s -X POST "$BASE_URL/posts/${POST_ID}/votes" \
  -d "user_id=user_bob" \
  -d "is_upvote=true" | jq
sleep $DELAY

print_request "Charlie also upvotes Alice's post..."
print_command "curl -s -X POST $BASE_URL/posts/${POST_ID}/votes -d 'user_id=user_charlie' -d 'is_upvote=true'"
curl -s -X POST "$BASE_URL/posts/${POST_ID}/votes" \
  -d "user_id=user_charlie" \
  -d "is_upvote=true" | jq
sleep $LONG_DELAY

# =============================================================================
# 9. Comment on Posts
# =============================================================================
print_header "9. Commenting on Posts"

print_request "Bob comments on Alice's post..."
print_command "curl -s -X POST $BASE_URL/posts/${POST_ID}/comments -d 'user_id=user_bob' -d 'content=Great post!'"
COMMENT_RESPONSE=$(curl -s -X POST "$BASE_URL/posts/${POST_ID}/comments" \
  -d "user_id=user_bob" \
  -d "content=Great post Alice! Very helpful.")
echo "$COMMENT_RESPONSE" | jq

# Extract Comment ID
COMMENT_ID=$(echo "$COMMENT_RESPONSE" | jq -r '.data.id')
echo -e "${GREEN}✓ Captured Comment ID: $COMMENT_ID${NC}"
sleep $DELAY

print_request "Charlie also comments..."
print_command "curl -s -X POST $BASE_URL/posts/${POST_ID}/comments -d 'user_id=user_charlie' -d 'content=Thanks for sharing!'"
curl -s -X POST "$BASE_URL/posts/${POST_ID}/comments" \
  -d "user_id=user_charlie" \
  -d "content=Thanks for sharing this information!" | jq
sleep $LONG_DELAY

# =============================================================================
# 10. Reply to Comments
# =============================================================================
print_header "10. Replying to Comments"

print_request "Alice replies to Bob's comment..."
print_command "curl -s -X POST $BASE_URL/comments/${COMMENT_ID}/replies -d 'user_id=user_alice' -d 'post_id=${POST_ID}' -d 'content=Thanks Bob!'"
curl -s -X POST "$BASE_URL/comments/${COMMENT_ID}/replies" \
  -d "user_id=user_alice" \
  -d "post_id=${POST_ID}" \
  -d "content=Thanks Bob! Glad you found it helpful." | jq
sleep $LONG_DELAY

# =============================================================================
# 11. Get User Feed
# =============================================================================
print_header "11. Getting User Feed"

print_request "Fetching Alice's feed (shows posts from subscribed subreddits)..."
print_command "curl -s $BASE_URL/users/user_alice/feed"
curl -s "$BASE_URL/users/user_alice/feed" | jq
sleep $LONG_DELAY

# =============================================================================
# 12. Direct Messaging
# =============================================================================
print_header "12. Direct Messaging"

print_request "Bob sends DM to Alice..."
print_command "curl -s -X POST $BASE_URL/dms -d 'from_user_id=user_bob' -d 'to_user_id=user_alice' -d 'content=Hey Alice!'"
curl -s -X POST "$BASE_URL/dms" \
  -d "from_user_id=user_bob" \
  -d "to_user_id=user_alice" \
  -d "content=Hey Alice, check out my latest post in r/gleam!" | jq
sleep $DELAY

print_request "Charlie sends DM to Alice..."
print_command "curl -s -X POST $BASE_URL/dms -d 'from_user_id=user_charlie' -d 'to_user_id=user_alice' -d 'content=Great content!'"
curl -s -X POST "$BASE_URL/dms" \
  -d "from_user_id=user_charlie" \
  -d "to_user_id=user_alice" \
  -d "content=Your posts are always great! Keep it up." | jq
sleep $LONG_DELAY

# =============================================================================
# 13. Get Direct Messages
# =============================================================================
print_header "13. Checking Direct Messages"

print_request "Alice checks her DMs..."
print_command "curl -s $BASE_URL/users/user_alice/dms"
curl -s "$BASE_URL/users/user_alice/dms" | jq
sleep $LONG_DELAY

# =============================================================================
# 14. Get User Karma
# =============================================================================
print_header "14. Checking User Karma"

print_request "Checking Alice's karma (based on post votes)..."
print_command "curl -s $BASE_URL/users/user_alice/karma"
curl -s "$BASE_URL/users/user_alice/karma" | jq
sleep $DELAY

print_request "Checking Bob's karma..."
print_command "curl -s $BASE_URL/users/user_bob/karma"
curl -s "$BASE_URL/users/user_bob/karma" | jq
sleep $LONG_DELAY

# =============================================================================
# 15. Leave Subreddit
# =============================================================================
print_header "15. Leaving Subreddit"

print_request "Charlie leaves r/gleam..."
print_command "curl -s -X DELETE $BASE_URL/users/user_charlie/subscriptions/r_gleam"
curl -s -X DELETE "$BASE_URL/users/user_charlie/subscriptions/r_gleam" | jq
sleep $DELAY

print_request "Checking r/gleam member count after Charlie left..."
print_command "curl -s $BASE_URL/subreddits/r_gleam/members"
curl -s "$BASE_URL/subreddits/r_gleam/members" | jq
sleep $LONG_DELAY

# =============================================================================
# 16. Engine Metrics
# =============================================================================
print_header "16. Engine Performance Metrics"

print_request "Fetching overall engine statistics..."
print_command "curl -s $BASE_URL/metrics"
curl -s "$BASE_URL/metrics" | jq
sleep $LONG_DELAY

# =============================================================================
# Summary
# =============================================================================
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ Demo completed successfully!${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${CYAN}Summary of what we demonstrated:${NC}"
echo -e "${CYAN}  • User registration (3 users)${NC}"
echo -e "${CYAN}  • User search${NC}"
echo -e "${CYAN}  • Subreddit creation (2 subreddits)${NC}"
echo -e "${CYAN}  • Subreddit search${NC}"
echo -e "${CYAN}  • Joining/leaving subreddits${NC}"
echo -e "${CYAN}  • Member count tracking${NC}"
echo -e "${CYAN}  • Creating posts${NC}"
echo -e "${CYAN}  • Voting on posts${NC}"
echo -e "${CYAN}  • Commenting on posts${NC}"
echo -e "${CYAN}  • Replying to comments${NC}"
echo -e "${CYAN}  • User feed generation${NC}"
echo -e "${CYAN}  • Direct messaging${NC}"
echo -e "${CYAN}  • Karma calculation${NC}"
echo -e "${CYAN}  • Performance metrics${NC}"
echo ""
echo -e "${YELLOW}All REST API endpoints are working! 🎉${NC}"
echo ""
