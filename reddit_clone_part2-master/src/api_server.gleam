// REST API Server for Reddit Clone using Wisp
import gleam/erlang/process.{type Subject}
import gleam/http.{Get, Post}
import gleam/int
import gleam/io
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import json_codec
import mist
import types.{
  type EngineMessage, CreateComment, CreatePost, CreateSubreddit,
  GetDirectMessages, GetFeed, GetStats, GetSubredditMemberCount, GetUserKarma,
  JoinSubreddit, LeaveSubreddit, RegisterUser, SearchSubreddits, SearchUsers,
  SendDirectMessage, VoteComment, VotePost,
}
import wisp.{type Request, type Response}
import wisp/wisp_mist

pub type Context {
  Context(engine: Subject(EngineMessage))
}

// Start the HTTP server on specified port
pub fn start_server(
  engine: Subject(EngineMessage),
  port: Int,
) -> Result(Nil, String) {
  io.println("Starting REST API server on port " <> int.to_string(port))

  let context = Context(engine: engine)
  let secret_key_base = wisp.random_string(64)

  let handler = fn(req: Request) { handle_request(req, context) }

  case
    wisp_mist.handler(handler, secret_key_base)
    |> mist.new
    |> mist.bind("0.0.0.0")
    |> mist.port(port)
    |> mist.start
  {
    Ok(_) -> {
      io.println(
        "✓ REST API server started on http://localhost:" <> int.to_string(port),
      )
      io.println(
        "API endpoints available at http://localhost:"
        <> int.to_string(port)
        <> "/*",
      )
      Ok(Nil)
    }
    Error(_) -> {
      Error(
        "Failed to start server. Port "
        <> int.to_string(port)
        <> " is likely already in use. Try: pkill -f beam.smp || lsof -ti :"
        <> int.to_string(port)
        <> " | xargs kill",
      )
    }
  }
}

// Main request handler
fn handle_request(req: Request, context: Context) -> Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)

  case wisp.path_segments(req) {
    // Health check
    ["health"] -> handle_health(req)

    // User registration: POST /users
    ["users"] -> handle_users(req, context)

    // Create subreddit: POST /subreddits
    ["subreddits"] -> handle_create_subreddit(req, context)

    // Join/Leave subreddit: PUT/DELETE /users/{user_id}/subscriptions/{subreddit_id}
    ["users", user_id, "subscriptions", subreddit_id] ->
      handle_subscription(req, context, user_id, subreddit_id)

    // Create post: POST /subreddits/{subreddit_id}/posts
    ["subreddits", subreddit_id, "posts"] ->
      handle_posts(req, context, subreddit_id)

    // Vote on post: POST /posts/{post_id}/votes
    ["posts", post_id, "votes"] -> handle_post_vote(req, context, post_id)

    // Create comment: POST /posts/{post_id}/comments  
    ["posts", post_id, "comments"] -> handle_comments(req, context, post_id)

    // Vote on comment: POST /comments/{comment_id}/votes
    ["comments", comment_id, "votes"] ->
      handle_comment_vote(req, context, comment_id)

    // Get user feed: GET /users/{user_id}/feed
    ["users", user_id, "feed"] -> handle_get_feed(req, context, user_id)

    // Direct messages: POST /dms or GET /users/{user_id}/dms
    ["dms"] -> handle_send_dm(req, context)
    ["users", user_id, "dms"] -> handle_get_dms(req, context, user_id)

    // Get karma: GET /users/{user_id}/karma
    ["users", user_id, "karma"] -> handle_get_karma(req, context, user_id)

    // Search users: GET /search/usernames?q=query
    ["search", "usernames"] -> handle_search_users(req, context)

    // Search subreddits: GET /search/subreddits?q=query
    ["search", "subreddits"] -> handle_search_subreddits(req, context)

    // Get subreddit member count: GET /subreddits/{id}/members
    ["subreddits", subreddit_id, "members"] ->
      handle_get_member_count(req, context, subreddit_id)

    // Reply to comment: POST /comments/{comment_id}/replies
    ["comments", comment_id, "replies"] ->
      handle_comment_reply(req, context, comment_id)

    // Get stats: GET /metrics
    ["metrics"] -> handle_get_stats(req, context)

    _ -> wisp.not_found()
  }
}

// ========== Handler Functions ==========

fn handle_health(req: Request) -> Response {
  case req.method {
    Get ->
      json_codec.success_response(json.string("OK"))
      |> json_response(200)
    _ -> wisp.method_not_allowed([Get])
  }
}

fn handle_users(req: Request, context: Context) -> Response {
  case req.method {
    Post -> {
      use form_data <- wisp.require_form(req)

      case list.key_find(form_data.values, "username") {
        Ok(username) -> {
          let reply = process.new_subject()
          process.send(context.engine, RegisterUser(username, reply))

          case process.receive(reply, 5000) {
            Ok(Ok(user)) ->
              json_codec.success_response(json_codec.user_to_json(user))
              |> json_response(200)
            Ok(Error(err)) ->
              json_codec.error_response(err)
              |> json_response(400)
            Error(_) ->
              json_codec.error_response("Request timeout")
              |> json_response(500)
          }
        }
        Error(_) ->
          json_codec.error_response("Missing username field")
          |> json_response(400)
      }
    }
    _ -> wisp.method_not_allowed([Post])
  }
}

fn handle_create_subreddit(req: Request, context: Context) -> Response {
  case req.method {
    Post -> {
      use form_data <- wisp.require_form(req)

      case
        list.key_find(form_data.values, "user_id"),
        list.key_find(form_data.values, "name"),
        list.key_find(form_data.values, "description")
      {
        Ok(user_id), Ok(name), Ok(description) -> {
          let reply = process.new_subject()
          process.send(
            context.engine,
            CreateSubreddit(user_id, name, description, reply),
          )

          case process.receive(reply, 5000) {
            Ok(Ok(subreddit)) ->
              json_codec.success_response(json_codec.subreddit_to_json(
                subreddit,
              ))
              |> json_response(200)
            Ok(Error(err)) ->
              json_codec.error_response(err)
              |> json_response(400)
            Error(_) ->
              json_codec.error_response("Request timeout")
              |> json_response(500)
          }
        }
        _, _, _ ->
          json_codec.error_response("Missing required fields")
          |> json_response(400)
      }
    }
    _ -> wisp.method_not_allowed([Post])
  }
}

fn handle_subscription(
  req: Request,
  context: Context,
  user_id: String,
  subreddit_id: String,
) -> Response {
  case req.method {
    http.Put -> {
      // Join subreddit
      let reply = process.new_subject()
      process.send(context.engine, JoinSubreddit(user_id, subreddit_id, reply))

      case process.receive(reply, 5000) {
        Ok(Ok(msg)) ->
          json_codec.success_response(json.string(msg))
          |> json_response(200)
        Ok(Error(err)) ->
          json_codec.error_response(err)
          |> json_response(400)
        Error(_) ->
          json_codec.error_response("Request timeout")
          |> json_response(500)
      }
    }
    http.Delete -> {
      // Leave subreddit
      let reply = process.new_subject()
      process.send(context.engine, LeaveSubreddit(user_id, subreddit_id, reply))

      case process.receive(reply, 5000) {
        Ok(Ok(msg)) ->
          json_codec.success_response(json.string(msg))
          |> json_response(200)
        Ok(Error(err)) ->
          json_codec.error_response(err)
          |> json_response(400)
        Error(_) ->
          json_codec.error_response("Request timeout")
          |> json_response(500)
      }
    }
    _ -> wisp.method_not_allowed([http.Put, http.Delete])
  }
}

fn handle_posts(
  req: Request,
  context: Context,
  subreddit_id: String,
) -> Response {
  case req.method {
    Post -> {
      use form_data <- wisp.require_form(req)

      case
        list.key_find(form_data.values, "user_id"),
        list.key_find(form_data.values, "title"),
        list.key_find(form_data.values, "content")
      {
        Ok(user_id), Ok(title), Ok(content) -> {
          let is_repost =
            list.key_find(form_data.values, "is_repost")
            |> result.map(fn(v) { v == "true" })
            |> result.unwrap(False)

          let reply = process.new_subject()
          process.send(
            context.engine,
            CreatePost(user_id, subreddit_id, title, content, is_repost, reply),
          )

          case process.receive(reply, 5000) {
            Ok(Ok(post)) ->
              json_codec.success_response(json_codec.post_to_json(post))
              |> json_response(200)
            Ok(Error(err)) ->
              json_codec.error_response(err)
              |> json_response(400)
            Error(_) ->
              json_codec.error_response("Request timeout")
              |> json_response(500)
          }
        }
        _, _, _ ->
          json_codec.error_response("Missing required fields")
          |> json_response(400)
      }
    }
    _ -> wisp.method_not_allowed([Post])
  }
}

fn handle_post_vote(req: Request, context: Context, post_id: String) -> Response {
  case req.method {
    Post -> {
      use form_data <- wisp.require_form(req)

      case
        list.key_find(form_data.values, "user_id"),
        list.key_find(form_data.values, "is_upvote")
      {
        Ok(user_id), Ok(vote_str) -> {
          let is_upvote = vote_str == "true"
          let reply = process.new_subject()
          process.send(
            context.engine,
            VotePost(user_id, post_id, is_upvote, reply),
          )

          case process.receive(reply, 5000) {
            Ok(Ok(msg)) ->
              json_codec.success_response(json.string(msg))
              |> json_response(200)
            Ok(Error(err)) ->
              json_codec.error_response(err)
              |> json_response(400)
            Error(_) ->
              json_codec.error_response("Request timeout")
              |> json_response(500)
          }
        }
        _, _ ->
          json_codec.error_response("Missing required fields")
          |> json_response(400)
      }
    }
    _ -> wisp.method_not_allowed([Post])
  }
}

fn handle_comments(req: Request, context: Context, post_id: String) -> Response {
  case req.method {
    Post -> {
      use form_data <- wisp.require_form(req)

      case
        list.key_find(form_data.values, "user_id"),
        list.key_find(form_data.values, "content")
      {
        Ok(user_id), Ok(content) -> {
          let parent_id = case
            list.key_find(form_data.values, "parent_comment_id")
          {
            Ok(pid) -> Some(pid)
            Error(_) -> None
          }

          let reply = process.new_subject()
          process.send(
            context.engine,
            CreateComment(user_id, post_id, content, parent_id, reply),
          )

          case process.receive(reply, 5000) {
            Ok(Ok(comment)) ->
              json_codec.success_response(json_codec.comment_to_json(comment))
              |> json_response(200)
            Ok(Error(err)) ->
              json_codec.error_response(err)
              |> json_response(400)
            Error(_) ->
              json_codec.error_response("Request timeout")
              |> json_response(500)
          }
        }
        _, _ ->
          json_codec.error_response("Missing required fields")
          |> json_response(400)
      }
    }
    _ -> wisp.method_not_allowed([Post])
  }
}

fn handle_comment_vote(
  req: Request,
  context: Context,
  comment_id: String,
) -> Response {
  case req.method {
    Post -> {
      use form_data <- wisp.require_form(req)

      case
        list.key_find(form_data.values, "user_id"),
        list.key_find(form_data.values, "is_upvote")
      {
        Ok(user_id), Ok(vote_str) -> {
          let is_upvote = vote_str == "true"
          let reply = process.new_subject()
          process.send(
            context.engine,
            VoteComment(user_id, comment_id, is_upvote, reply),
          )

          case process.receive(reply, 5000) {
            Ok(Ok(msg)) ->
              json_codec.success_response(json.string(msg))
              |> json_response(200)
            Ok(Error(err)) ->
              json_codec.error_response(err)
              |> json_response(400)
            Error(_) ->
              json_codec.error_response("Request timeout")
              |> json_response(500)
          }
        }
        _, _ ->
          json_codec.error_response("Missing required fields")
          |> json_response(400)
      }
    }
    _ -> wisp.method_not_allowed([Post])
  }
}

fn handle_get_feed(req: Request, context: Context, user_id: String) -> Response {
  case req.method {
    Get -> {
      let reply = process.new_subject()
      process.send(context.engine, GetFeed(user_id, reply))

      case process.receive(reply, 5000) {
        Ok(Ok(posts)) ->
          json_codec.list_to_json(posts, json_codec.post_to_json)
          |> json_codec.success_response
          |> json_response(200)
        Ok(Error(err)) ->
          json_codec.error_response(err)
          |> json_response(400)
        Error(_) ->
          json_codec.error_response("Request timeout")
          |> json_response(500)
      }
    }
    _ -> wisp.method_not_allowed([Get])
  }
}

fn handle_send_dm(req: Request, context: Context) -> Response {
  case req.method {
    Post -> {
      use form_data <- wisp.require_form(req)

      case
        list.key_find(form_data.values, "from_user_id"),
        list.key_find(form_data.values, "to_user_id"),
        list.key_find(form_data.values, "content")
      {
        Ok(from_id), Ok(to_id), Ok(content) -> {
          let parent_id = case
            list.key_find(form_data.values, "parent_message_id")
          {
            Ok(pid) -> Some(pid)
            Error(_) -> None
          }

          let reply = process.new_subject()
          process.send(
            context.engine,
            SendDirectMessage(from_id, to_id, content, parent_id, reply),
          )

          case process.receive(reply, 5000) {
            Ok(Ok(message)) ->
              json_codec.success_response(json_codec.message_to_json(message))
              |> json_response(200)
            Ok(Error(err)) ->
              json_codec.error_response(err)
              |> json_response(400)
            Error(_) ->
              json_codec.error_response("Request timeout")
              |> json_response(500)
          }
        }
        _, _, _ ->
          json_codec.error_response("Missing required fields")
          |> json_response(400)
      }
    }
    _ -> wisp.method_not_allowed([Post])
  }
}

fn handle_get_dms(req: Request, context: Context, user_id: String) -> Response {
  case req.method {
    Get -> {
      let reply = process.new_subject()
      process.send(context.engine, GetDirectMessages(user_id, reply))

      case process.receive(reply, 5000) {
        Ok(Ok(messages)) ->
          json_codec.list_to_json(messages, json_codec.message_to_json)
          |> json_codec.success_response
          |> json_response(200)
        Ok(Error(err)) ->
          json_codec.error_response(err)
          |> json_response(400)
        Error(_) ->
          json_codec.error_response("Request timeout")
          |> json_response(500)
      }
    }
    _ -> wisp.method_not_allowed([Get])
  }
}

fn handle_get_karma(req: Request, context: Context, user_id: String) -> Response {
  case req.method {
    Get -> {
      let reply = process.new_subject()
      process.send(context.engine, GetUserKarma(user_id, reply))

      case process.receive(reply, 5000) {
        Ok(Ok(karma)) ->
          json_codec.success_response(
            json.object([#("karma", json.int(karma))]),
          )
          |> json_response(200)
        Ok(Error(err)) ->
          json_codec.error_response(err)
          |> json_response(404)
        Error(_) ->
          json_codec.error_response("Request timeout")
          |> json_response(500)
      }
    }
    _ -> wisp.method_not_allowed([Get])
  }
}

fn handle_get_stats(req: Request, context: Context) -> Response {
  case req.method {
    Get -> {
      let reply = process.new_subject()
      process.send(context.engine, GetStats(reply))

      case process.receive(reply, 5000) {
        Ok(stats) ->
          json_codec.success_response(json_codec.stats_to_json(stats))
          |> json_response(200)
        Error(_) ->
          json_codec.error_response("Request timeout")
          |> json_response(500)
      }
    }
    _ -> wisp.method_not_allowed([Get])
  }
}

fn handle_search_users(req: Request, context: Context) -> Response {
  case req.method {
    Get -> {
      case list.key_find(wisp.get_query(req), "q") {
        Ok(query) -> {
          let reply = process.new_subject()
          process.send(context.engine, SearchUsers(query, reply))

          case process.receive(reply, 5000) {
            Ok(usernames) -> {
              let json_array = json.array(usernames, json.string)
              json_codec.success_response(
                json.object([#("usernames", json_array)]),
              )
              |> json_response(200)
            }
            Error(_) ->
              json_codec.error_response("Request timeout")
              |> json_response(500)
          }
        }
        Error(_) ->
          json_codec.error_response("Missing query parameter 'q'")
          |> json_response(400)
      }
    }
    _ -> wisp.method_not_allowed([Get])
  }
}

fn handle_search_subreddits(req: Request, context: Context) -> Response {
  case req.method {
    Get -> {
      case list.key_find(wisp.get_query(req), "q") {
        Ok(query) -> {
          let reply = process.new_subject()
          process.send(context.engine, SearchSubreddits(query, reply))

          case process.receive(reply, 5000) {
            Ok(results) -> {
              let json_array =
                json.array(results, fn(item) {
                  let #(id, description) = item
                  json.object([
                    #("name", json.string(id)),
                    #("description", json.string(description)),
                  ])
                })
              json_codec.success_response(
                json.object([#("subreddits", json_array)]),
              )
              |> json_response(200)
            }
            Error(_) ->
              json_codec.error_response("Request timeout")
              |> json_response(500)
          }
        }
        Error(_) ->
          json_codec.error_response("Missing query parameter 'q'")
          |> json_response(400)
      }
    }
    _ -> wisp.method_not_allowed([Get])
  }
}

fn handle_get_member_count(
  req: Request,
  context: Context,
  subreddit_id: String,
) -> Response {
  case req.method {
    Get -> {
      let reply = process.new_subject()
      process.send(context.engine, GetSubredditMemberCount(subreddit_id, reply))

      case process.receive(reply, 5000) {
        Ok(Ok(count)) ->
          json_codec.success_response(
            json.object([#("member_count", json.int(count))]),
          )
          |> json_response(200)
        Ok(Error(err)) ->
          json_codec.error_response(err)
          |> json_response(404)
        Error(_) ->
          json_codec.error_response("Request timeout")
          |> json_response(500)
      }
    }
    _ -> wisp.method_not_allowed([Get])
  }
}

fn handle_comment_reply(
  req: Request,
  context: Context,
  parent_comment_id: String,
) -> Response {
  case req.method {
    Post -> {
      use form_data <- wisp.require_form(req)

      case
        list.key_find(form_data.values, "user_id"),
        list.key_find(form_data.values, "post_id"),
        list.key_find(form_data.values, "content")
      {
        Ok(user_id), Ok(post_id), Ok(content) -> {
          let reply = process.new_subject()
          process.send(
            context.engine,
            CreateComment(
              user_id,
              post_id,
              content,
              Some(parent_comment_id),
              reply,
            ),
          )

          case process.receive(reply, 5000) {
            Ok(Ok(comment)) ->
              json_codec.success_response(json_codec.comment_to_json(comment))
              |> json_response(200)
            Ok(Error(err)) ->
              json_codec.error_response(err)
              |> json_response(400)
            Error(_) ->
              json_codec.error_response("Request timeout")
              |> json_response(500)
          }
        }
        _, _, _ ->
          json_codec.error_response("Missing required fields")
          |> json_response(400)
      }
    }
    _ -> wisp.method_not_allowed([Post])
  }
}

// ========== Helper Functions ==========

fn json_response(body: json.Json, status: Int) -> Response {
  wisp.response(status)
  |> wisp.set_header("content-type", "application/json")
  |> wisp.set_body(wisp.Text(json.to_string(body)))
}
