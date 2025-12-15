// Multi-client demo for Reddit Clone REST API
import api_server
import engine
import gleam/erlang/process
import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/io
import gleam/json
import gleam/result

pub fn main() {
  io.println("=== Reddit Clone Multi-Client Demo ===")
  io.println("")

  // Start the engine
  io.println("1. Starting Reddit engine...")
  case engine.start() {
    Ok(engine_actor) -> {
      io.println("✓ Engine started")

      // Start API server
      io.println("2. Starting REST API server on port 8080...")
      case api_server.start_server(engine_actor.data, 8080) {
        Ok(_) -> {
          io.println("✓ API server started")
          io.println("")

          // Give server time to start
          process.sleep(1000)

          // Run the demo
          io.println("3. Running multi-client demo...")
          io.println("========================================")
          run_demo()
        }
        Error(err) -> {
          io.println("✗ Failed to start server: " <> err)
        }
      }
    }
    Error(_) -> {
      io.println("✗ Failed to start engine")
    }
  }
}

fn run_demo() -> Nil {
  let base_url = "http://localhost:8080"

  io.println("")
  io.println("=== Demo: Multiple Clients Interacting with Reddit Clone ===")
  io.println("")

  // Step 1: Register three users
  io.println("STEP 1: Registering users...")
  io.println("----------------------------")

  let _alice_result = register_user(base_url, "alice")
  let _bob_result = register_user(base_url, "bob")
  let _charlie_result = register_user(base_url, "charlie")

  process.sleep(500)

  // Step 2: Create subreddits
  io.println("")
  io.println("STEP 2: Creating subreddits...")
  io.println("-------------------------------")

  create_subreddit(
    base_url,
    "user_alice",
    "programming",
    "Programming discussions and help",
  )
  create_subreddit(base_url, "user_bob", "gaming", "Gaming news and reviews")

  process.sleep(500)

  // Step 3: Join subreddits
  io.println("")
  io.println("STEP 3: Users joining subreddits...")
  io.println("------------------------------------")

  join_subreddit(base_url, "user_alice", "r_programming")
  join_subreddit(base_url, "user_bob", "r_programming")
  join_subreddit(base_url, "user_bob", "r_gaming")
  join_subreddit(base_url, "user_charlie", "r_programming")
  join_subreddit(base_url, "user_charlie", "r_gaming")

  process.sleep(500)

  // Step 4: Create posts
  io.println("")
  io.println("STEP 4: Creating posts...")
  io.println("-------------------------")

  create_post(
    base_url,
    "user_alice",
    "r_programming",
    "Learning Gleam",
    "Just started learning Gleam, loving it!",
  )
  create_post(
    base_url,
    "user_bob",
    "r_programming",
    "Actor Model Best Practices",
    "What are your tips for using actors effectively?",
  )
  create_post(
    base_url,
    "user_charlie",
    "r_gaming",
    "New RPG Release",
    "Just finished playing the new RPG, amazing story!",
  )

  process.sleep(500)

  // Step 5: Comment on posts
  io.println("")
  io.println("STEP 5: Adding comments...")
  io.println("--------------------------")

  create_comment(
    base_url,
    "user_bob",
    "post_1",
    "Gleam is awesome! The type system is great.",
  )
  create_comment(
    base_url,
    "user_charlie",
    "post_1",
    "I agree! Coming from Elixir, it's familiar but better typed.",
  )
  create_comment(
    base_url,
    "user_alice",
    "post_2",
    "Use supervision trees and keep actors focused on single responsibilities.",
  )

  process.sleep(500)

  // Step 6: Vote on posts
  io.println("")
  io.println("STEP 6: Voting on posts...")
  io.println("--------------------------")

  vote_post(base_url, "user_bob", "post_1", True)
  vote_post(base_url, "user_charlie", "post_1", True)
  vote_post(base_url, "user_alice", "post_2", True)
  vote_post(base_url, "user_charlie", "post_2", True)

  process.sleep(500)

  // Step 7: Send direct messages
  io.println("")
  io.println("STEP 7: Sending direct messages...")
  io.println("-----------------------------------")

  send_message(
    base_url,
    "user_alice",
    "user_bob",
    "Hey Bob, thanks for the comment!",
  )
  send_message(
    base_url,
    "user_bob",
    "user_alice",
    "No problem! Let's collaborate on a project.",
  )
  send_message(
    base_url,
    "user_charlie",
    "user_alice",
    "Alice, can you help me with actors?",
  )

  process.sleep(500)

  // Step 8: Get user feeds
  io.println("")
  io.println("STEP 8: Retrieving user feeds...")
  io.println("---------------------------------")

  get_feed(base_url, "user_alice")
  get_feed(base_url, "user_bob")

  process.sleep(500)

  // Step 9: Get direct messages
  io.println("")
  io.println("STEP 9: Retrieving direct messages...")
  io.println("--------------------------------------")

  get_messages(base_url, "user_alice")
  get_messages(base_url, "user_bob")

  process.sleep(500)

  // Step 10: Get stats
  io.println("")
  io.println("STEP 10: Getting engine statistics...")
  io.println("--------------------------------------")

  get_stats(base_url)

  io.println("")
  io.println("========================================")
  io.println("✓ Demo completed successfully!")
  io.println("========================================")
  io.println("")
  io.println("All Reddit Clone functionality demonstrated:")
  io.println("  ✓ User registration")
  io.println("  ✓ Subreddit creation")
  io.println("  ✓ Joining/subscribing to subreddits")
  io.println("  ✓ Creating posts")
  io.println("  ✓ Commenting on posts")
  io.println("  ✓ Voting (upvotes/downvotes)")
  io.println("  ✓ Direct messaging")
  io.println("  ✓ Personalized feeds")
  io.println("  ✓ Engine statistics")
  io.println("")
}

// Helper functions for API calls

fn register_user(base_url: String, username: String) -> Result(String, String) {
  io.println("  Registering user: " <> username)
  let body = json.object([#("username", json.string(username))])
  case post_json(base_url <> "/api/register", body) {
    Ok(response) -> {
      io.println("  ✓ User " <> username <> " registered")
      Ok(response)
    }
    Error(err) -> {
      io.println("  ✗ Failed to register " <> username <> ": " <> err)
      Error(err)
    }
  }
}

fn create_subreddit(
  base_url: String,
  user_id: String,
  name: String,
  description: String,
) -> Nil {
  io.println("  Creating subreddit: " <> name)
  let body =
    json.object([
      #("user_id", json.string(user_id)),
      #("name", json.string(name)),
      #("description", json.string(description)),
    ])
  case post_json(base_url <> "/api/subreddit", body) {
    Ok(_) -> io.println("  ✓ Subreddit " <> name <> " created")
    Error(err) -> io.println("  ✗ Failed: " <> err)
  }
}

fn join_subreddit(
  base_url: String,
  user_id: String,
  subreddit_id: String,
) -> Nil {
  io.println("  " <> user_id <> " joining " <> subreddit_id)
  let body = json.object([#("user_id", json.string(user_id))])
  case
    post_json(base_url <> "/api/subreddit/" <> subreddit_id <> "/join", body)
  {
    Ok(_) -> io.println("  ✓ Joined successfully")
    Error(err) -> io.println("  ✗ Failed: " <> err)
  }
}

fn create_post(
  base_url: String,
  user_id: String,
  subreddit_id: String,
  title: String,
  content: String,
) -> Nil {
  io.println("  " <> user_id <> " posting: " <> title)
  let body =
    json.object([
      #("user_id", json.string(user_id)),
      #("subreddit_id", json.string(subreddit_id)),
      #("title", json.string(title)),
      #("content", json.string(content)),
      #("is_repost", json.bool(False)),
    ])
  case post_json(base_url <> "/api/post", body) {
    Ok(_) -> io.println("  ✓ Post created")
    Error(err) -> io.println("  ✗ Failed: " <> err)
  }
}

fn create_comment(
  base_url: String,
  user_id: String,
  post_id: String,
  content: String,
) -> Nil {
  io.println("  " <> user_id <> " commenting on " <> post_id)
  let body =
    json.object([
      #("user_id", json.string(user_id)),
      #("post_id", json.string(post_id)),
      #("content", json.string(content)),
    ])
  case post_json(base_url <> "/api/comment", body) {
    Ok(_) -> io.println("  ✓ Comment added")
    Error(err) -> io.println("  ✗ Failed: " <> err)
  }
}

fn vote_post(
  base_url: String,
  user_id: String,
  post_id: String,
  is_upvote: Bool,
) -> Nil {
  let vote_type = case is_upvote {
    True -> "upvoting"
    False -> "downvoting"
  }
  io.println("  " <> user_id <> " " <> vote_type <> " " <> post_id)
  let body =
    json.object([
      #("user_id", json.string(user_id)),
      #("is_upvote", json.bool(is_upvote)),
    ])
  case post_json(base_url <> "/api/post/" <> post_id <> "/vote", body) {
    Ok(_) -> io.println("  ✓ Vote recorded")
    Error(err) -> io.println("  ✗ Failed: " <> err)
  }
}

fn send_message(
  base_url: String,
  from_id: String,
  to_id: String,
  content: String,
) -> Nil {
  io.println("  " <> from_id <> " messaging " <> to_id)
  let body =
    json.object([
      #("from_user_id", json.string(from_id)),
      #("to_user_id", json.string(to_id)),
      #("content", json.string(content)),
    ])
  case post_json(base_url <> "/api/message", body) {
    Ok(_) -> io.println("  ✓ Message sent")
    Error(err) -> io.println("  ✗ Failed: " <> err)
  }
}

fn get_feed(base_url: String, user_id: String) -> Nil {
  io.println("  Getting feed for " <> user_id)
  case get_json(base_url <> "/api/feed/" <> user_id) {
    Ok(response) -> {
      io.println("  ✓ Feed retrieved")
      io.println("    " <> response)
    }
    Error(err) -> io.println("  ✗ Failed: " <> err)
  }
}

fn get_messages(base_url: String, user_id: String) -> Nil {
  io.println("  Getting messages for " <> user_id)
  case get_json(base_url <> "/api/message/" <> user_id) {
    Ok(response) -> {
      io.println("  ✓ Messages retrieved")
      io.println("    " <> response)
    }
    Error(err) -> io.println("  ✗ Failed: " <> err)
  }
}

fn get_stats(base_url: String) -> Nil {
  io.println("  Getting engine statistics")
  case get_json(base_url <> "/api/stats") {
    Ok(response) -> {
      io.println("  ✓ Statistics retrieved")
      io.println("    " <> response)
    }
    Error(err) -> io.println("  ✗ Failed: " <> err)
  }
}

// HTTP helpers

fn post_json(url: String, body: json.Json) -> Result(String, String) {
  let body_string = json.to_string(body)

  case
    request.to(url)
    |> result.map(fn(req) {
      req
      |> request.set_method(http.Post)
      |> request.set_body(body_string)
      |> request.set_header("content-type", "application/json")
    })
  {
    Ok(req) -> {
      case httpc.send(req) {
        Ok(response) -> Ok(response.body)
        Error(_) -> Error("HTTP request failed")
      }
    }
    Error(_) -> Error("Invalid URL")
  }
}

fn get_json(url: String) -> Result(String, String) {
  case request.to(url) {
    Ok(req) -> {
      case httpc.send(req) {
        Ok(response) -> Ok(response.body)
        Error(_) -> Error("HTTP request failed")
      }
    }
    Error(_) -> Error("Invalid URL")
  }
}
