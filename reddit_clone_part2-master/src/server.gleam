// Reddit Clone REST API Server Entry Point
import api_server
import argv
import engine
import gleam/erlang/process
import gleam/int
import gleam/io
import gleam/result

pub fn main() {
  io.println("=== Reddit Clone REST API Server ===")
  io.println("")

  // Parse command-line arguments for port
  let args = argv.load().arguments
  let port = case args {
    [port_str, ..] -> int.parse(port_str) |> result.unwrap(8080)
    _ -> 8080
  }

  io.println("1. Starting Reddit Clone engine...")

  // Start the Reddit engine
  case engine.start() {
    Ok(engine_actor) -> {
      io.println("✓ Engine started successfully")
      io.println("")

      io.println(
        "2. Starting REST API server on port " <> int.to_string(port) <> "...",
      )

      // Start the REST API server
      case api_server.start_server(engine_actor.data, port) {
        Ok(_) -> {
          io.println("")
          io.println("========================================")
          io.println("✓ Reddit Clone API Server is running!")
          io.println("========================================")
          io.println("")
          io.println("API Base URL: http://localhost:" <> int.to_string(port))
          io.println("")
          io.println("Available Endpoints:")
          io.println("  # User Management")
          io.println("  POST   /users - Register user")
          io.println("  GET    /users/{user_id}/karma - Get user karma")
          io.println("  GET    /users/{user_id}/feed - Get user feed")
          io.println("")
          io.println("  # Subreddit Management")
          io.println("  POST   /subreddits - Create subreddit")
          io.println(
            "  PUT    /users/{user_id}/subscriptions/{subreddit_id} - Join subreddit",
          )
          io.println(
            "  DELETE /users/{user_id}/subscriptions/{subreddit_id} - Leave subreddit",
          )
          io.println(
            "  GET    /subreddits/{subreddit_id}/members - Get member count",
          )
          io.println("")
          io.println("  # Posts & Comments")
          io.println("  POST   /subreddits/{subreddit_id}/posts - Create post")
          io.println("  POST   /posts/{post_id}/votes - Vote on post")
          io.println("  POST   /posts/{post_id}/comments - Create comment")
          io.println(
            "  POST   /comments/{comment_id}/replies - Reply to comment",
          )
          io.println("  POST   /comments/{comment_id}/votes - Vote on comment")
          io.println("")
          io.println("  # Direct Messaging")
          io.println("  POST   /dms - Send direct message")
          io.println("  GET    /users/{user_id}/dms - Get messages")
          io.println("")
          io.println("  # Search & System")
          io.println("  GET    /search/usernames?q={query} - Search users")
          io.println(
            "  GET    /search/subreddits?q={query} - Search subreddits",
          )
          io.println("  GET    /metrics - System metrics")
          io.println("  GET    /health - Health check")
          io.println("")
          io.println("Use the client to interact with the API:")
          io.println("  gleam run -m client help")
          io.println("")
          io.println("Press Ctrl+C to stop the server")
          io.println("========================================")

          // Keep the server running
          process.sleep_forever()
        }
        Error(err) -> {
          io.println("")
          io.println("========================================")
          io.println("✗ FAILED TO START SERVER")
          io.println("========================================")
          io.println("")
          io.println("Error: " <> err)
          io.println("")
          io.println("To fix this, kill the existing server:")
          io.println("  pkill -f beam.smp")
          io.println("  # OR")
          io.println(
            "  lsof -ti :" <> int.to_string(port) <> " | xargs kill -9",
          )
          io.println("")
          io.println("Then try again:")
          io.println("  gleam run -m server")
          io.println("")
          io.println("Or use a different port:")
          io.println("  gleam run -m server 8081")
          io.println("========================================")
        }
      }
    }
    Error(_) -> {
      io.println("✗ Failed to start engine")
    }
  }
}
