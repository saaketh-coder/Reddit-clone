// Command-line REST API client for Reddit Clone
import argv
import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/io
import gleam/json
import gleam/result
import gleam/string

pub type ClientCommand {
  Register(username: String)
  CreateSubreddit(user_id: String, name: String, description: String)
  JoinSubreddit(user_id: String, subreddit_id: String)
  LeaveSubreddit(user_id: String, subreddit_id: String)
  CreatePost(
    user_id: String,
    subreddit_id: String,
    title: String,
    content: String,
  )
  CreateComment(user_id: String, post_id: String, content: String)
  VotePost(user_id: String, post_id: String, is_upvote: Bool)
  VoteComment(user_id: String, comment_id: String, is_upvote: Bool)
  GetFeed(user_id: String)
  SendMessage(from_user_id: String, to_user_id: String, content: String)
  GetMessages(user_id: String)
  GetStats
  Help
}

pub fn main() {
  let args = argv.load().arguments

  // Default API base URL
  let base_url = "http://localhost:8080"

  case parse_command(args) {
    Ok(command) -> {
      io.println("Executing command...")
      execute_command(base_url, command)
    }
    Error(err) -> {
      io.println("Error: " <> err)
      print_help()
    }
  }
}

fn parse_command(args: List(String)) -> Result(ClientCommand, String) {
  case args {
    ["register", username] -> Ok(Register(username))

    ["create-subreddit", user_id, name, description] ->
      Ok(CreateSubreddit(user_id, name, description))

    ["join", user_id, subreddit_id] -> Ok(JoinSubreddit(user_id, subreddit_id))

    ["leave", user_id, subreddit_id] ->
      Ok(LeaveSubreddit(user_id, subreddit_id))

    ["post", user_id, subreddit_id, title, ..content_parts] -> {
      let content = string.join(content_parts, " ")
      Ok(CreatePost(user_id, subreddit_id, title, content))
    }

    ["comment", user_id, post_id, ..content_parts] -> {
      let content = string.join(content_parts, " ")
      Ok(CreateComment(user_id, post_id, content))
    }

    ["upvote-post", user_id, post_id] -> Ok(VotePost(user_id, post_id, True))

    ["downvote-post", user_id, post_id] -> Ok(VotePost(user_id, post_id, False))

    ["upvote-comment", user_id, comment_id] ->
      Ok(VoteComment(user_id, comment_id, True))

    ["downvote-comment", user_id, comment_id] ->
      Ok(VoteComment(user_id, comment_id, False))

    ["feed", user_id] -> Ok(GetFeed(user_id))

    ["send-message", from_user_id, to_user_id, ..content_parts] -> {
      let content = string.join(content_parts, " ")
      Ok(SendMessage(from_user_id, to_user_id, content))
    }

    ["messages", user_id] -> Ok(GetMessages(user_id))

    ["stats"] -> Ok(GetStats)

    ["help"] | [] -> Ok(Help)

    _ -> Error("Invalid command")
  }
}

fn execute_command(base_url: String, command: ClientCommand) -> Nil {
  case command {
    Help -> print_help()

    Register(username) -> {
      let body = json.object([#("username", json.string(username))])
      let url = base_url <> "/api/register"

      case post_request(url, body) {
        Ok(response_body) -> {
          io.println("✓ User registered successfully!")
          io.println(response_body)
        }
        Error(err) -> io.println("✗ Error: " <> err)
      }
    }

    CreateSubreddit(user_id, name, description) -> {
      let body =
        json.object([
          #("user_id", json.string(user_id)),
          #("name", json.string(name)),
          #("description", json.string(description)),
        ])
      let url = base_url <> "/api/subreddit"

      case post_request(url, body) {
        Ok(response_body) -> {
          io.println("✓ Subreddit created successfully!")
          io.println(response_body)
        }
        Error(err) -> io.println("✗ Error: " <> err)
      }
    }

    JoinSubreddit(user_id, subreddit_id) -> {
      let body = json.object([#("user_id", json.string(user_id))])
      let url = base_url <> "/api/subreddit/" <> subreddit_id <> "/join"

      case post_request(url, body) {
        Ok(response_body) -> {
          io.println("✓ Joined subreddit successfully!")
          io.println(response_body)
        }
        Error(err) -> io.println("✗ Error: " <> err)
      }
    }

    LeaveSubreddit(user_id, subreddit_id) -> {
      let body = json.object([#("user_id", json.string(user_id))])
      let url = base_url <> "/api/subreddit/" <> subreddit_id <> "/leave"

      case post_request(url, body) {
        Ok(response_body) -> {
          io.println("✓ Left subreddit successfully!")
          io.println(response_body)
        }
        Error(err) -> io.println("✗ Error: " <> err)
      }
    }

    CreatePost(user_id, subreddit_id, title, content) -> {
      let body =
        json.object([
          #("user_id", json.string(user_id)),
          #("subreddit_id", json.string(subreddit_id)),
          #("title", json.string(title)),
          #("content", json.string(content)),
          #("is_repost", json.bool(False)),
        ])
      let url = base_url <> "/api/post"

      case post_request(url, body) {
        Ok(response_body) -> {
          io.println("✓ Post created successfully!")
          io.println(response_body)
        }
        Error(err) -> io.println("✗ Error: " <> err)
      }
    }

    CreateComment(user_id, post_id, content) -> {
      let body =
        json.object([
          #("user_id", json.string(user_id)),
          #("post_id", json.string(post_id)),
          #("content", json.string(content)),
        ])
      let url = base_url <> "/api/comment"

      case post_request(url, body) {
        Ok(response_body) -> {
          io.println("✓ Comment created successfully!")
          io.println(response_body)
        }
        Error(err) -> io.println("✗ Error: " <> err)
      }
    }

    VotePost(user_id, post_id, is_upvote) -> {
      let body =
        json.object([
          #("user_id", json.string(user_id)),
          #("is_upvote", json.bool(is_upvote)),
        ])
      let url = base_url <> "/api/post/" <> post_id <> "/vote"

      case post_request(url, body) {
        Ok(response_body) -> {
          io.println("✓ Vote recorded successfully!")
          io.println(response_body)
        }
        Error(err) -> io.println("✗ Error: " <> err)
      }
    }

    VoteComment(user_id, comment_id, is_upvote) -> {
      let body =
        json.object([
          #("user_id", json.string(user_id)),
          #("is_upvote", json.bool(is_upvote)),
        ])
      let url = base_url <> "/api/comment/" <> comment_id <> "/vote"

      case post_request(url, body) {
        Ok(response_body) -> {
          io.println("✓ Vote recorded successfully!")
          io.println(response_body)
        }
        Error(err) -> io.println("✗ Error: " <> err)
      }
    }

    GetFeed(user_id) -> {
      let url = base_url <> "/api/feed/" <> user_id

      case get_request(url) {
        Ok(response_body) -> {
          io.println("✓ Feed retrieved successfully!")
          io.println(response_body)
        }
        Error(err) -> io.println("✗ Error: " <> err)
      }
    }

    SendMessage(from_user_id, to_user_id, content) -> {
      let body =
        json.object([
          #("from_user_id", json.string(from_user_id)),
          #("to_user_id", json.string(to_user_id)),
          #("content", json.string(content)),
        ])
      let url = base_url <> "/api/message"

      case post_request(url, body) {
        Ok(response_body) -> {
          io.println("✓ Message sent successfully!")
          io.println(response_body)
        }
        Error(err) -> io.println("✗ Error: " <> err)
      }
    }

    GetMessages(user_id) -> {
      let url = base_url <> "/api/message/" <> user_id

      case get_request(url) {
        Ok(response_body) -> {
          io.println("✓ Messages retrieved successfully!")
          io.println(response_body)
        }
        Error(err) -> io.println("✗ Error: " <> err)
      }
    }

    GetStats -> {
      let url = base_url <> "/api/stats"

      case get_request(url) {
        Ok(response_body) -> {
          io.println("✓ Stats retrieved successfully!")
          io.println(response_body)
        }
        Error(err) -> io.println("✗ Error: " <> err)
      }
    }
  }
}

// HTTP request helpers
fn post_request(url: String, body: json.Json) -> Result(String, String) {
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
        Error(_) -> Error("Failed to send HTTP request")
      }
    }
    Error(_) -> Error("Invalid URL")
  }
}

fn get_request(url: String) -> Result(String, String) {
  case request.to(url) {
    Ok(req) -> {
      case httpc.send(req) {
        Ok(response) -> Ok(response.body)
        Error(_) -> Error("Failed to send HTTP request")
      }
    }
    Error(_) -> Error("Invalid URL")
  }
}

fn print_help() -> Nil {
  io.println(
    "
Reddit Clone REST API Client

USAGE:
  gleam run -m client <command> [arguments]

COMMANDS:
  register <username>
      Register a new user account

  create-subreddit <user_id> <name> <description>
      Create a new subreddit

  join <user_id> <subreddit_id>
      Join a subreddit

  leave <user_id> <subreddit_id>
      Leave a subreddit

  post <user_id> <subreddit_id> <title> <content...>
      Create a new post in a subreddit

  comment <user_id> <post_id> <content...>
      Comment on a post

  upvote-post <user_id> <post_id>
      Upvote a post

  downvote-post <user_id> <post_id>
      Downvote a post

  upvote-comment <user_id> <comment_id>
      Upvote a comment

  downvote-comment <user_id> <comment_id>
      Downvote a comment

  feed <user_id>
      Get personalized feed for a user

  send-message <from_user_id> <to_user_id> <content...>
      Send a direct message to another user

  messages <user_id>
      Get all direct messages for a user

  stats
      Get engine statistics

  help
      Show this help message

EXAMPLES:
  gleam run -m client register alice
  gleam run -m client create-subreddit user_alice programming \"Programming discussions\"
  gleam run -m client join user_alice r_programming
  gleam run -m client post user_alice r_programming \"Hello World\" This is my first post
  gleam run -m client stats
",
  )
}
