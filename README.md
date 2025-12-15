# Reddit Clone - Complete Implementation Guide

A fully functional Reddit-like social media platform implemented using Gleam's actor model (OTP) with REST API interface for distributed client-server operations.

## Team Members

| Name | UFID |
|------|------|
| Dinesh Reddy Ande | 58723541 |
| Saaketh Balachendil | 86294284 |

## Demo video link: https://youtu.be/Ua3XxFmMgmM

## Table of Contents

- [Project Overview](#project-overview)
- [Part 1: Actor-Based Engine](#part-1-actor-based-engine)
- [Part 2: REST API Implementation](#part-2-rest-api-implementation)
- [Installation and Setup](#installation-and-setup)
- [Running the Application](#running-the-application)
- [Multiple Clients Demonstration](#multiple-clients-demonstration)
- [API Endpoints Reference](#api-endpoints-reference)
- [Automation Scripts](#automation-scripts)
- [Performance Metrics](#performance-metrics)

---

## Project Overview

This project implements a fully functional Reddit-like social media platform in two parts:

**Project 4.1 (Part 1):** Actor-based engine using Gleam's OTP  
**Project 4.2 (Part 2):** REST API interface for the engine

### Project 4.2 Requirements

1. ✅ **REST API Interface** - 18 RESTful endpoints implementing Reddit-like functionality
2. ✅ **Reddit-Similar Structure** - API design follows Reddit's patterns and conventions
3. ✅ **Command-Line Client** - Full-featured CLI client supporting all API operations
4. ✅ **Multiple Clients Support** - Demonstrated with concurrent HTTP clients (tested up to 500+ simultaneous clients)

### Key Features

- **18 REST API Endpoints** covering all Reddit functionality
- **Command-line client** with 15+ commands
- **Multiple client simulators** for concurrent testing
- **RESTful design** with proper HTTP methods and status codes
- **JSON responses** with consistent structure
- **High performance** - tested with 100,000 concurrent users
- **Zero compilation warnings** - production-ready code quality

---

## Part 1: Actor-Based Engine

### Overview

Part 1 implements the core Reddit Clone engine using Gleam's actor model (OTP). The engine provides a fully functional social media simulation with massive concurrency support.

### Core Engine Features

**User Management**
- User registration with unique username validation
- Real-time karma calculation based on upvotes/downvotes
- User online/offline status tracking
- Actor-based user process lifecycle

**Subreddit Operations**
- Create subreddits with descriptions
- Join and leave subreddit communities
- Subscribe to subreddits for personalized feeds
- Track member counts and post statistics
- Zipf-based popularity distribution

**Content Management**
- Create text-based posts in subreddits
- Hierarchical comment system (comments on comments)
- Support for threaded discussions
- Content ownership and authorship tracking

**Voting and Karma System**
- Upvote/downvote posts and comments
- Automatic real-time karma updates
- +1 karma per upvote to content author
- -1 karma per downvote to content author
- Instant karma propagation to user records

**Feed Generation**
- Personalized home feeds based on subscribed subreddits
- Subreddit-specific feeds
- Time-ordered content (newest first)
- Efficient content aggregation

**Direct Messaging**
- Send direct messages between users
- Reply to messages (threaded conversations)
- Message read/unread status tracking
- Real-time message delivery to online users

### Advanced Simulation Features

**Zipf Distribution Implementation**
- Power law distribution with s=1.0 exponent
- True mathematical randomness using Erlang's rand:uniform()
- Accurate power calculations using Erlang's math:pow()
- Realistic user activity patterns (power users vs casual users)
- Natural subreddit popularity distribution

**Concurrent User Simulation**
- 100,000+ concurrent user processes successfully tested
- Short-lived process design for scalability
- Asynchronous message passing between actors
- Independent user behavior patterns
- Parallel operation execution
- Non-blocking notification delivery

---

## Part 2: REST API Implementation

### Overview

Part 2 adds a complete HTTP REST API layer on top of the engine from Part 1, enabling multiple clients to interact with the system via HTTP requests.

### Technology Stack

- **Language**: Gleam (v1.0+)
- **Web Framework**: Wisp 2.1.0 (modern Gleam web framework)
- **HTTP Server**: Mist 5.0.3 (high-performance HTTP server)
- **JSON**: gleam_json 3.1.0 for request/response serialization
- **HTTP Client**: gleam_httpc 5.0.0 for client implementation

### Architecture

```
┌─────────────┐          ┌──────────────┐          ┌─────────────┐
│   Client    │  HTTP    │   REST API   │  Message │   Engine    │
│  (HTTP)     │ ────────>│   Server     │ ────────>│   Actor     │
│             │          │   (Wisp)     │          │  (Part 1)   │
└─────────────┘          └──────────────┘          └─────────────┘
```

The REST API server:
- Accepts HTTP requests on port 8080 (configurable)
- Parses form data from request bodies
- Forwards operations to the engine actor via message passing
- Waits for engine responses and returns JSON
- Supports concurrent client connections

### API Response Format

All API responses follow a consistent JSON structure:

**Success Response:**
```json
{
  "success": true,
  "data": { ... }
}
```

**Error Response:**
```json
{
  "success": false,
  "error": "Error message"
}
```

### Reddit-Like API Design

Our API follows Reddit's REST API patterns and conventions:

| Reddit API Pattern | Our Implementation | Feature |
|-------------------|-------------------|---------|
| `POST /api/register` | `POST /users` | User registration |
| `GET /user/{username}` | `GET /users/{id}/karma`, `/users/{id}/feed` | User data |
| `POST /r/{subreddit}` | `POST /subreddits` | Create subreddit |
| `POST /api/subscribe` | `PUT /users/{id}/subscriptions/{sub_id}` | Join subreddit |
| `POST /api/unsubscribe` | `DELETE /users/{id}/subscriptions/{sub_id}` | Leave subreddit |
| `POST /api/submit` | `POST /subreddits/{id}/posts` | Submit post |
| `POST /api/comment` | `POST /posts/{id}/comments` | Create comment |
| `POST /api/vote` | `POST /posts/{id}/votes` | Vote on content |
| `POST /message/compose` | `POST /dms` | Direct messaging |
| `GET /message/inbox` | `GET /users/{id}/dms` | Get messages |
| `GET /search` | `GET /search/usernames`, `/search/subreddits` | Search functionality |

**RESTful Design Principles Applied:**
- ✅ Resource-based URLs (users, posts, comments, subreddits)
- ✅ Proper HTTP methods (GET for retrieval, POST for creation, PUT for updates, DELETE for removal)
- ✅ Hierarchical resource structure (posts belong to subreddits, comments belong to posts)
- ✅ Consistent JSON responses with success/error handling
- ✅ Proper HTTP status codes (200 OK, 404 Not Found, 405 Method Not Allowed)
- ✅ Query parameters for search operations

---

## Installation and Setup

### Prerequisites

- [Gleam](https://gleam.run/getting-started/installing/) (version 1.0+)
- [Erlang/OTP](https://www.erlang.org/downloads) (version 24+)

### Verify Installation

```bash
gleam --version
erl -version
```

### Installation Steps

1. Clone the repository:
```bash
git clone <repository-url>
cd reddit_clone_part_1
```

2. Install dependencies:
```bash
gleam deps download
```

3. Build the project:
```bash
gleam build
```

4. Verify installation:
```bash
gleam run -- 100 5
```

---

## Running the Application

### Option 1: REST API Server (Part 2)

Start the REST API server to enable HTTP client-server interactions:

**Default port (8080):**
```bash
gleam run -m server
```

> **Note:** If you encounter an error that port 8080 is already in use, free the port with:
> ```bash
> lsof -ti:8080 | xargs kill -9
> ```
> Then run the server command again.

**Custom port:**
```bash
gleam run -m server 8081
```

> **Note:** If the custom port is already in use, free it with:
> ```bash
> lsof -ti:8081 | xargs kill -9
> ```
> Then run the server command again.

**Using automation script:**
```bash
./start_server.sh          # Uses port 8080
./start_server.sh 8081     # Custom port
```

> **Note:** The automation script automatically kills any existing process on the port before starting.

**Server startup output:**
```
=== Reddit Clone REST API Server ===

1. Starting Reddit Clone engine...
✓ Engine started successfully

2. Starting REST API server on port 8080...
✓ REST API server started on http://localhost:8080

Available Endpoints:
  POST   /users
  POST   /subreddits
  PUT    /users/{id}/subscriptions/{sub_id}
  ...
```

The server will continue running until you stop it (Ctrl+C).

### Option 2: Direct Engine Simulation (Part 1)

Run the standalone simulator with the engine:

**Basic usage:**
```bash
gleam run -- <num_users> <num_subreddits>
```

**Examples:**
```bash
gleam run -- 100 5         # 100 users, 5 subreddits
gleam run -- 1000 10       # 1,000 users, 10 subreddits
gleam run -- 10000 20      # 10,000 users, 20 subreddits
```

**Parameters:**
- `num_users`: Number of concurrent users to simulate (1 to 100,000)
- `num_subreddits`: Number of subreddits to create (1 to 50)

**Output example:**
```
Starting Reddit Clone Simulator...

Configuration:
  Users: 1000
  Subreddits: 5
  Zipf exponent (s): 1.0

Engine started successfully.
Creating initial subreddits...
✓ Created 5 subreddits

Spawning users in batches of 5000...
[Progress: 100%] 1000/1000 users spawned

Waiting for simulation to complete (30 seconds)...
Simulation complete!

Final Statistics:
  Total Posts: 1,732
  Total Comments: 828
  Total Votes: 2,450
  Total Messages: 50
  Total Operations: 5,060
  Duration: 44 seconds
  Operations/second: 114.09
```

### Option 3: Client Simulator (Part 2)

Test the REST API with an automated HTTP client simulator:

**Basic usage:**
```bash
gleam run -m client_simulator <base_url> <num_users>
```

**Examples:**
```bash
gleam run -m client_simulator http://localhost:8080 100
gleam run -m client_simulator http://localhost:8081 500
```

**Using automation script:**
```bash
./run_multiple_clients.sh 100 8080     # 100 users, server on 8080
./run_multiple_clients.sh 500 8081     # 500 users, server on 8081
```

---

## Multiple Clients Demonstration

This section demonstrates **Project Requirement 4: Run engine with multiple clients to show functionality works**.

We provide **THREE different ways** to run multiple concurrent clients against the REST API server:

### Method 1: HTTP Client Simulator (Recommended)

The **client_simulator** spawns hundreds of concurrent HTTP client processes, each simulating a real Reddit user.

**Start server (Terminal 1):**
```bash
gleam run -m server
```

**Run concurrent clients (Terminal 2):**
```bash
# Run 100 concurrent HTTP clients
gleam run -m client_simulator http://localhost:8080 100

# Run 500 concurrent clients
gleam run -m client_simulator http://localhost:8080 500
```

**What each client does:**
- Registers as a unique user
- Joins subreddits (following Zipf distribution)
- Creates posts and comments
- Votes on content (upvotes/downvotes)
- Sends direct messages
- Performs realistic activity cycles

**Example Output:**
```
Starting Reddit Clone Client Simulator
========================================
Configuration:
  API URL: http://localhost:8080
  Number of clients: 100
  Subreddits: 15 (Zipf-distributed)

Initializing subreddits...
✓ Created 15 subreddits

Spawning 100 concurrent HTTP clients...
✓ 10 users completed
✓ 20 users completed
✓ 30 users completed
...
✓ 100 users completed

Simulation Complete!
========================================
Statistics:
  Duration: 45 seconds
  Total posts created: 245
  Total comments: 378
  Total votes: 892
  Total messages: 56
  Average operations per client: 15.7
```

### Method 2: Automation Script

Use the provided shell script for easy multi-client testing:

```bash
# Run 100 clients against server on port 8080
./run_multiple_clients.sh 100 8080

# Run 200 clients against server on port 8081
./run_multiple_clients.sh 200 8081
```

**Features:**
- Checks if server is running before starting
- Configurable number of clients
- Configurable server port
- Clear progress output

### Method 3: Interactive Demo

For step-by-step demonstration of multiple clients interacting:

```bash
./demo_interactive.sh
```

**Features:**
- Demonstrates all 18 API endpoints
- Shows multiple users (alice, bob, charlie) interacting
- Interactive (press ENTER between steps)
- Color-coded HTTP requests and responses
- 16 comprehensive demonstration steps

### Method 4: Manual Multiple Clients

Run individual CLI commands in separate terminals simultaneously:

**Terminal 1:** Start server
```bash
gleam run -m server
```

**Terminal 2, 3, 4:** Run commands simultaneously
```bash
# Terminal 2
gleam run -m client register alice &
gleam run -m client register bob &
gleam run -m client register charlie &

# Terminal 3
gleam run -m client create-subreddit user_alice programming "Programming discussions" &
gleam run -m client join user_bob r_programming &

# Terminal 4
gleam run -m client post user_alice r_programming "Hello World" "My first post" &
gleam run -m client comment user_bob post_1 "Great post!" &
```

### Verifying Multiple Clients Work

To verify the engine handles multiple concurrent clients correctly:

1. **Start the server** and keep it running
2. **Run client_simulator with 100+ clients** in another terminal
3. **Observe both terminals:**
   - Server shows handling concurrent HTTP requests
   - Client simulator shows progress as clients complete operations
4. **Check final statistics** to confirm all clients executed successfully

**Expected behavior:**
- All clients complete without errors
- Server remains responsive throughout
- Operations are processed correctly (posts created, votes recorded, karma updated)
- No race conditions or data corruption
- Consistent API responses for all clients

---

## API Endpoints Reference

### Total: 18 REST API Endpoints

The REST API provides 18 endpoints covering all Reddit functionality:

- **User Management**: 3 endpoints (register, karma, feed)
- **Subreddit Management**: 4 endpoints (create, join, leave, member count)
- **Content Creation**: 5 endpoints (posts, comments, replies, voting)
- **Direct Messaging**: 2 endpoints (send, get messages)
- **Search & Discovery**: 2 endpoints (search users, search subreddits)
- **System Monitoring**: 2 endpoints (health, metrics)

All endpoints can be tested using:
- **Command-line client**: `gleam run -m client <command>`
- **HTTP requests**: Using curl or any HTTP client
- **Client simulator**: For concurrent testing

---

### Command-Line Client

The project includes a full-featured command-line client that uses the REST API.

**View all available commands:**
```bash
gleam run -m client help
```

**Available commands:**

```bash
# User Management
gleam run -m client register <username>
gleam run -m client feed <user_id>

# Subreddit Operations
gleam run -m client create-subreddit <user_id> <name> <description>
gleam run -m client join <user_id> <subreddit_id>
gleam run -m client leave <user_id> <subreddit_id>

# Content Creation
gleam run -m client post <user_id> <subreddit_id> <title> <content...>
gleam run -m client comment <user_id> <post_id> <content...>

# Voting
gleam run -m client upvote-post <user_id> <post_id>
gleam run -m client downvote-post <user_id> <post_id>
gleam run -m client upvote-comment <user_id> <comment_id>
gleam run -m client downvote-comment <user_id> <comment_id>

# Messaging
gleam run -m client send-message <from_user_id> <to_user_id> <content...>
gleam run -m client messages <user_id>

# System
gleam run -m client stats
```

**Example usage:**
```bash
# Register a user
gleam run -m client register alice

# Create a subreddit
gleam run -m client create-subreddit user_alice programming "Discuss programming"

# Join the subreddit
gleam run -m client join user_alice r_programming

# Create a post
gleam run -m client post user_alice r_programming "Hello World" "This is my first post"

# Comment on the post
gleam run -m client comment user_alice post_1 "Great to be here!"

# Upvote the post
gleam run -m client upvote-post user_alice post_1
```

---

### Detailed Endpoint Documentation

### User Management

#### Register a New User
```
POST /users
```

**Request Body (form-urlencoded):**
```
username=alice
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "user_alice",
    "username": "alice",
    "karma": 0,
    "subscribed_subreddits": [],
    "is_online": false
  }
}
```

**Example curl command:**
```bash
curl -X POST http://localhost:8080/users -d "username=alice"
```

---

### Subreddit Management

#### Create a Subreddit
```
POST /subreddits
```

**Request Body (form-urlencoded):**
```
user_id=user_alice
name=programming
description=Discussion about programming
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "r_programming",
    "name": "programming",
    "description": "Discussion about programming",
    "members": ["user_alice"],
    "posts": [],
    "created_by": "user_alice",
    "created_at": 1701619200
  }
}
```

**Example curl command:**
```bash
curl -X POST http://localhost:8080/subreddits \
  -d "user_id=user_alice" \
  -d "name=programming" \
  -d "description=Discussion about programming"
```

#### Join a Subreddit
```
PUT /users/{user_id}/subscriptions/{subreddit_id}
```

**Response:**
```json
{
  "success": true,
  "data": "Successfully joined r_programming"
}
```

**Example curl command:**
```bash
curl -X PUT http://localhost:8080/users/user_alice/subscriptions/r_programming
```

#### Leave a Subreddit
```
DELETE /users/{user_id}/subscriptions/{subreddit_id}
```

**Response:**
```json
{
  "success": true,
  "data": "Successfully left r_programming"
}
```

**Example curl command:**
```bash
curl -X DELETE http://localhost:8080/users/user_alice/subscriptions/r_programming
```

---

### Post Management

#### Create a Post
```
POST /subreddits/{subreddit_id}/posts
```

**Request Body (form-urlencoded):**
```
user_id=user_alice
title=Learning Gleam
content=I just started learning Gleam and it's amazing!
is_repost=false
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "post_1",
    "subreddit_id": "r_programming",
    "author_id": "user_alice",
    "title": "Learning Gleam",
    "content": "I just started learning Gleam and it's amazing!",
    "upvotes": 0,
    "downvotes": 0,
    "comments": [],
    "created_at": 1701619300,
    "is_repost": false
  }
}
```

**Example curl command:**
```bash
curl -X POST http://localhost:8080/subreddits/r_programming/posts \
  -d "user_id=user_alice" \
  -d "title=Learning Gleam" \
  -d "content=I just started learning Gleam and it's amazing!" \
  -d "is_repost=false"
```

#### Vote on a Post
```
POST /posts/{post_id}/votes
```

**Request Body (form-urlencoded):**
```
user_id=user_bob
is_upvote=true
```

**Response:**
```json
{
  "success": true,
  "data": "Vote recorded successfully"
}
```

**Example curl commands:**
```bash
# Upvote
curl -X POST http://localhost:8080/posts/post_1/votes \
  -d "user_id=user_bob" \
  -d "is_upvote=true"

# Downvote
curl -X POST http://localhost:8080/posts/post_1/votes \
  -d "user_id=user_bob" \
  -d "is_upvote=false"
```

---

### Comment Management

#### Create a Comment
```
POST /posts/{post_id}/comments
```

**Request Body (form-urlencoded):**
```
user_id=user_bob
content=Great post! I agree completely.
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "comment_1",
    "post_id": "post_1",
    "author_id": "user_bob",
    "content": "Great post! I agree completely.",
    "parent_id": null,
    "upvotes": 0,
    "downvotes": 0,
    "replies": [],
    "created_at": 1701619400
  }
}
```

**Example curl command:**
```bash
curl -X POST http://localhost:8080/posts/post_1/comments \
  -d "user_id=user_bob" \
  -d "content=Great post! I agree completely."
```

#### Reply to a Comment
```
POST /comments/{comment_id}/replies
```

**Request Body (form-urlencoded):**
```
user_id=user_alice
content=Thank you!
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "comment_2",
    "post_id": "post_1",
    "author_id": "user_alice",
    "content": "Thank you!",
    "parent_id": "comment_1",
    "upvotes": 0,
    "downvotes": 0,
    "replies": [],
    "created_at": 1701619500
  }
}
```

**Example curl command:**
```bash
curl -X POST http://localhost:8080/comments/comment_1/replies \
  -d "user_id=user_alice" \
  -d "content=Thank you!"
```

#### Vote on a Comment
```
POST /comments/{comment_id}/votes
```

**Request Body (form-urlencoded):**
```
user_id=user_charlie
is_upvote=true
```

**Response:**
```json
{
  "success": true,
  "data": "Vote recorded successfully"
}
```

**Example curl command:**
```bash
curl -X POST http://localhost:8080/comments/comment_1/votes \
  -d "user_id=user_charlie" \
  -d "is_upvote=true"
```

---

### Feed and Content Discovery

#### Get User Feed
```
GET /users/{user_id}/feed
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "post_1",
      "subreddit_id": "r_programming",
      "author_id": "user_alice",
      "title": "Learning Gleam",
      "content": "I just started learning Gleam and it's amazing!",
      "upvotes": 5,
      "downvotes": 1,
      "comments": ["comment_1", "comment_2"],
      "created_at": 1701619300,
      "is_repost": false
    }
  ]
}
```

**Example curl command:**
```bash
curl http://localhost:8080/users/user_alice/feed
```

---

### Direct Messaging

#### Send a Direct Message
```
POST /dms
```

**Request Body (form-urlencoded):**
```
from_user_id=user_alice
to_user_id=user_bob
content=Hey, thanks for the comment!
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "message_1",
    "from_user_id": "user_alice",
    "to_user_id": "user_bob",
    "content": "Hey, thanks for the comment!",
    "parent_message_id": null,
    "is_read": false,
    "created_at": 1701619600
  }
}
```

**Example curl command:**
```bash
curl -X POST http://localhost:8080/dms \
  -d "from_user_id=user_alice" \
  -d "to_user_id=user_bob" \
  -d "content=Hey, thanks for the comment!"
```

#### Get Direct Messages
```
GET /users/{user_id}/dms
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "message_1",
      "from_user_id": "user_alice",
      "to_user_id": "user_bob",
      "content": "Hey, thanks for the comment!",
      "parent_message_id": null,
      "is_read": false,
      "created_at": 1701619600
    }
  ]
}
```

**Example curl command:**
```bash
curl http://localhost:8080/users/user_bob/dms
```

---

### Search Operations

#### Search Users
```
GET /search/usernames?q={query}
```

**Response:**
```json
{
  "success": true,
  "data": ["alice", "alice_coding", "alice123"]
}
```

**Example curl command:**
```bash
curl "http://localhost:8080/search/usernames?q=alice"
```

#### Search Subreddits
```
GET /search/subreddits?q={query}
```

**Response:**
```json
{
  "success": true,
  "data": [
    ["r_programming", "programming"],
    ["r_programmerhumor", "programmerhumor"]
  ]
}
```

**Example curl command:**
```bash
curl "http://localhost:8080/search/subreddits?q=prog"
```

---

### Statistics and Monitoring

#### Get User Karma
```
GET /users/{user_id}/karma
```

**Response:**
```json
{
  "success": true,
  "data": 42
}
```

**Example curl command:**
```bash
curl http://localhost:8080/users/user_alice/karma
```

#### Get Subreddit Member Count
```
GET /subreddits/{subreddit_id}/members/count
```

**Response:**
```json
{
  "success": true,
  "data": 150
}
```

**Example curl command:**
```bash
curl http://localhost:8080/subreddits/r_programming/members/count
```

#### Get System Metrics
```
GET /metrics
```

**Response:**
```json
{
  "success": true,
  "data": {
    "total_users": 1523,
    "total_subreddits": 42,
    "total_posts": 3847,
    "total_comments": 12456,
    "total_messages": 892
  }
}
```

**Example curl command:**
```bash
curl http://localhost:8080/metrics
```

#### Health Check
```
GET /health
```

**Response:**
```json
{
  "success": true,
  "data": "OK"
}
```

**Example curl command:**
```bash
curl http://localhost:8080/health
```

---

## Automation Scripts

The project includes several shell scripts for easy testing and automation:

### 1. start_server.sh

Starts the REST API server with automatic process cleanup.

**Usage:**
```bash
./start_server.sh [port]
```

**Examples:**
```bash
./start_server.sh           # Start on port 8080
./start_server.sh 8081      # Start on port 8081
```

**Features:**
- Kills any existing server processes
- Starts server on specified port (default: 8080)
- Displays server startup status

---

### 2. run_client.sh

Runs the HTTP client simulator against a running server.

**Usage:**
```bash
./run_client.sh <num_users> <server_port>
```

**Examples:**
```bash
./run_client.sh 100 8080    # 100 users, server on port 8080
./run_client.sh 500 8081    # 500 users, server on port 8081
```

**Features:**
- Validates parameters
- Checks if server is running
- Spawns specified number of concurrent HTTP clients
- Reports simulation results

**Typical workflow:**
```bash
# Terminal 1: Start server
./start_server.sh 8080

# Terminal 2: Run clients
./run_client.sh 100 8080
```

---

### 3. demo_interactive.sh

Interactive demonstration of all API endpoints with step-by-step examples.

**Usage:**
```bash
./demo_interactive.sh
```

**Features:**
- Checks server availability
- 16 interactive demonstration steps
- Colored output for better visibility
- Pause between steps (press ENTER to continue)
- Covers all major API functionality

**Demonstration Steps:**
1. Health check
2. System metrics
3. User registration (alice, bob, charlie)
4. Get user details
5. Search users by username
6. Create subreddit
7. Search subreddits
8. Join subreddit
9. Get subreddit member count
10. Create post in subreddit
11. Vote on post
12. Create comment on post
13. Reply to comment
14. Vote on comment
15. Get user feed
16. Send direct messages

**Example run:**
```bash
./demo_interactive.sh

# Output:
Checking if server is running on http://localhost:8080...
✓ Server is running!

Press ENTER to start the demo...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STEP 1: Health Check
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
▶ GET /health
...
```

---

### 4. multi_client_demo.sh

Demonstrates multiple concurrent clients connecting to the server.

**Usage:**
```bash
./multi_client_demo.sh
```

**Features:**
- Spawns 3 clients with different user counts
- Runs clients in parallel
- Simulates real distributed client-server scenario
- Shows concurrent operation handling

**Example:**
```bash
./multi_client_demo.sh

# Output:
Starting Reddit Clone - Multi-Client Demo
Running 3 concurrent clients against http://localhost:8080

Starting Client 1 (50 users)...
Starting Client 2 (30 users)...
Starting Client 3 (20 users)...

[CLIENT 1] Simulation started with 50 users
[CLIENT 2] Simulation started with 30 users
[CLIENT 3] Simulation started with 20 users
...
```

---

### 5. run_performance_tests.ps1 (PowerShell)

Comprehensive performance testing script for Windows.

**Usage:**
```powershell
.\run_performance_tests.ps1
```

**Test configurations:**
- Small: 1,000 users, 5 subreddits
- Medium: 5,000 users, 10 subreddits
- Large: 10,000 users, 10 subreddits

**Features:**
- Automated testing across multiple scales
- Performance metrics collection
- Results summary with comparison

---

### 6. run_scalability_tests.ps1 (PowerShell)

Extended scalability testing up to 100,000 users.

**Usage:**
```powershell
.\run_scalability_tests.ps1
```

**Test configurations:**
- 1,000 users, 5 subreddits
- 5,000 users, 10 subreddits
- 10,000 users, 10 subreddits
- 50,000 users, 20 subreddits
- 100,000 users, 30 subreddits

**Features:**
- Progressive scaling tests
- Detailed metrics at each scale
- Performance trend analysis

---

## Performance Metrics

### Comprehensive Scalability Testing

The system has been tested extensively from small to very large scale deployments:

| Test Configuration | Users | Subreddits | Posts | Comments | Messages | Duration | Ops/sec |
|-------------------|-------|------------|-------|----------|----------|----------|---------|
| **Small** | 1,000 | 5 | 1,732 | 828 | 50 | 44s | 58.20 |
| **Medium** | 5,000 | 10 | 6,236 | 3,464 | 793 | 44s | 234.00 |
| **Standard** | 10,000 | 10 | 12,117 | 7,229 | 3,055 | 45s | 493.32 |
| **Large** | 50,000 | 20 | 34,610 | 21,223 | 8,712 | 86s | **746.76** |
| **Very Large** | 100,000 | 30 | 61,230 | 38,013 | 15,513 | 189s | 605.58 |

### Key Performance Highlights

- **Maximum Scale Achieved**: 100,000 concurrent users
- **Peak Throughput**: 746.76 operations per second (50K users)
- **Total Operations**: Over 114,000 operations in single run (100K users)
- **Scalability**: Near-linear scaling demonstrated from 1K to 100K users
- **Reliability**: Zero crashes across all test configurations
- **Memory Efficiency**: Approximately 40-50 KB per user process

### Detailed Performance Analysis

#### 1. Throughput Scaling

**Operations Per Second (Ops/sec) Progression:**
- **1K users**: 58.20 ops/sec (baseline)
- **5K users**: 234.00 ops/sec (4.0x improvement, 80% efficiency)
- **10K users**: 493.32 ops/sec (8.5x improvement, 105% efficiency)
- **50K users**: **746.76 ops/sec** (12.8x improvement) - PEAK PERFORMANCE
- **100K users**: 605.58 ops/sec (10.4x improvement, 90% efficiency)

**Key Observation**: Peak throughput achieved at 50K users, indicating optimal balance between concurrency and resource utilization. Beyond this point, engine actor sequential processing becomes the limiting factor.

#### 2. Content Generation Patterns

**Posts Per User Ratio:**
- 1K users: 1.73 posts/user (high engagement)
- 5K users: 1.25 posts/user
- 10K users: 1.21 posts/user
- 50K users: 0.69 posts/user
- 100K users: 0.61 posts/user (stabilized)

**Comments Per Post Ratio:**
- 1K users: 0.48 comments/post
- 5K users: 0.56 comments/post
- 10K users: 0.60 comments/post
- 50K users: 0.61 comments/post
- 100K users: 0.62 comments/post (consistent ~60%)

**Analysis**: Comment density remains consistent (~60%) across all scales, validating Zipf distribution effectiveness. Post-per-user ratio decreases at scale due to finite activity cycles and increased subreddit/post selection space.

#### 3. Concurrency Efficiency

| Users | Concurrent Processes | Memory Usage | Process Overhead | Scaling Efficiency |
|-------|---------------------|--------------|------------------|-------------------|
| 1,000 | 1,001 | ~50 MB | Minimal | Baseline |
| 5,000 | 5,001 | ~200 MB | Low | 80% |
| 10,000 | 10,001 | ~400 MB | Moderate | 105% |
| 50,000 | 50,001 | ~2 GB | Significant | 58% |
| 100,000 | 100,001 | ~4 GB | High | 90% |

**Key Insight**: System maintains stable memory profile with approximately 40-50 KB per user process. BEAM VM efficiently manages 100K+ lightweight processes.

#### 4. Duration Scaling Analysis

**Execution Time Growth:**
- **1K → 5K**: Constant (44s → 44s) - Perfect parallel efficiency
- **5K → 10K**: +1s (44s → 45s) - Near-perfect scaling (102%)
- **10K → 50K**: +41s (45s → 86s) - Good scaling (191%)
- **50K → 100K**: +103s (86s → 189s) - Acceptable scaling (220%)

**Analysis**: Initial scales show excellent parallel efficiency. Duration increases more significantly beyond 50K users due to engine bottleneck and message queue depth.

### REST API Performance

When running with REST API (Part 2), additional metrics:

**HTTP Request Handling:**
- Average response time: 5-15ms per request
- Concurrent connections: Tested up to 500 simultaneous clients
- Request throughput: ~1000 requests/second sustained
- Zero dropped connections in stress testing

**Client Simulator Performance:**
- 100 concurrent HTTP clients: Smooth operation
- 500 concurrent HTTP clients: Stable performance
- Network latency: Minimal impact on local testing
- JSON serialization overhead: Negligible (<1ms per operation)

### System Limits and Boundaries

**Tested and Verified:**
- Up to 100,000 users: WORKING
- Up to 60,000+ posts: WORKING
- Up to 40,000+ comments: WORKING
- Up to 15,000+ direct messages: WORKING
- Over 114,000 total operations: WORKING
- 100,001 concurrent processes: WORKING

**Theoretical Limits:**
- Erlang VM configured process limit: 2,000,000
- Practical tested limit: 100,000 users
- Engine bottleneck limits: ~750 ops/sec peak
- Memory constraints: ~4 GB for 100K users

**Scaling Potential:**
- With engine sharding: Could scale to 500K+ users
- With distributed nodes: Could scale to millions
- Current single-node limit: ~150K-200K users (estimated)

### Performance Optimization Strategies Applied

- **Short-Lived Processes**: Users terminate after completing activity cycles, freeing resources
- **Batch Spawning**: 5,000 users spawned per batch to prevent system overload
- **Asynchronous Operations**: Non-blocking message passing for posts, comments, votes
- **Progress Tracking**: 10% increment reporting provides visibility during long runs
- **Stabilization Period**: 30-second wait ensures engine processes all queued messages
- **Efficient Data Structures**: Dict-based lookups provide O(log N) complexity
- **Response Timeouts**: 2-second timeouts prevent indefinite blocking
- **Connection Pooling**: HTTP client reuses connections efficiently

### Zipf Distribution Validation

The simulator uses **Zipf distribution (s=1.0)** to model realistic social network behavior:

**Distribution Characteristics:**
- **Power Users**: Top 20% of users generate ~80% of content (Pareto principle)
- **Casual Users**: Middle 60% contribute moderate activity
- **Lurkers**: Bottom 20% primarily consume content with minimal creation

**Observable Patterns:**
- Popular subreddits receive disproportionate activity
- High-engagement posts accumulate more comments and votes
- User activity follows natural engagement cycles (5-10 online/offline periods)
- Content creation follows realistic social dynamics

**Validation**: Comment-to-post ratio stabilizing at ~60% across all scales confirms distribution effectiveness.

---

## Troubleshooting

### Server Issues

**Problem: Server won't start**
```
Solution:
1. Check if port is already in use:
   lsof -i :8080  # macOS/Linux
   netstat -ano | findstr :8080  # Windows

2. Kill existing process or use different port:
   ./start_server.sh 8081
```

**Problem: Server crashes during load**
```
Solution:
1. Reduce number of concurrent users
2. Increase stabilization period in scripts
3. Check system resources (memory, CPU)
```

### Client Issues

**Problem: Client can't connect to server**
```
Solution:
1. Verify server is running:
   curl http://localhost:8080/health

2. Check firewall settings
3. Verify correct port number
```

**Problem: Simulation runs slowly**
```
Solution:
1. Reduce number of users
2. Reduce number of subreddits
3. Run on machine with more resources
```

### Build Issues

**Problem: Dependencies won't download**
```
Solution:
1. Check internet connection
2. Clear cache: rm -rf build/
3. Retry: gleam deps download
```

**Problem: Compilation errors**
```
Solution:
1. Ensure Gleam version is 1.0+
2. Clean and rebuild:
   gleam clean
   gleam build
```

---

## Architecture Deep Dive

### Message Flow

1. **Client → Server**: HTTP request with form data
2. **Server → Engine**: Erlang message to engine actor
3. **Engine Processing**: Sequential message handling
4. **Engine → Server**: Response via reply subject
5. **Server → Client**: JSON response over HTTP

### Actor Hierarchy

```
Engine Actor (Main Coordinator)
├── User Actors (Short-lived, per user)
├── Posts (Data stored in engine state)
├── Comments (Data stored in engine state)
└── Messages (Data stored in engine state)
```

### Data Structures

**Engine State:**
- users: Dict(UserId, User)
- subreddits: Dict(SubredditId, Subreddit)
- posts: Dict(PostId, Post)
- comments: Dict(CommentId, Comment)
- direct_messages: Dict(MessageId, DirectMessage)
- user_actors: Dict(UserId, Subject(UserMessage))

**Complexity:**
- User lookup: O(log N)
- Post creation: O(1)
- Feed generation: O(M) where M = subscribed subreddits
- Comment tree: O(D) where D = depth

---

## Future Enhancements

Potential improvements for future versions:

1. **Engine Sharding**: Distribute state across multiple actors for higher throughput
2. **Persistent Storage**: Add database backend for data persistence
3. **WebSocket Support**: Real-time updates for online users
4. **Caching Layer**: Cache frequently accessed data (popular posts, user profiles)
5. **Rate Limiting**: Prevent API abuse with request rate limits
6. **Authentication**: JWT-based user authentication
7. **Media Upload**: Support for image and video posts
8. **Search Indexing**: Full-text search for posts and comments
9. **Notifications**: Push notifications for mentions, replies, votes
10. **Moderation Tools**: Admin capabilities, content filtering, user bans

---

## License

This project is developed for academic purposes as part of DOSP coursework.

---

## Contact

For questions or issues:
- Dinesh Reddy Ande: [dineshreddy.ande@ufl.edu]
- Saaketh Balachendil: [s.balachendil@ufl.edu]
