// Concurrent client simulator for Reddit Clone - simulates hundreds of concurrent users
// Similar to reference implementation with Zipf distribution and realistic behavior
import argv
import gleam/dynamic/decode
import gleam/erlang/process
import gleam/float
import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/int
import gleam/io
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import gleam/uri

// Default configuration
const default_num_clients = 100

const default_api_host = "localhost"

const default_api_port = 8081

// Subreddits ranked by expected popularity (Zipf distribution)
// You can add more subreddits here - they will automatically follow Zipf's law
const subreddits_by_rank = [
  #("programming", "Programming discussions and help", 1),
  #("gleam", "Gleam programming language", 2),
  #("gaming", "Gaming news and reviews", 3),
  #("technology", "Latest tech news", 4),
  #("science", "Scientific discoveries", 5),
  #("movies", "Movie discussions", 6),
  #("music", "Music and audio discussions", 7),
  #("sports", "Sports news and discussions", 8),
  #("books", "Book recommendations and reviews", 9),
  #("food", "Cooking and recipes", 10),
  #("travel", "Travel tips and stories", 11),
  #("photography", "Photography showcase", 12),
  #("art", "Art and design", 13),
  #("fitness", "Fitness and health", 14),
  #("diy", "DIY and crafts", 15),
]

pub fn main() {
  // Parse command-line arguments
  let args = argv.load().arguments
  let #(num_clients, api_host, api_port) = case args {
    [num_str, host, port_str, ..] -> {
      let num = int.parse(num_str) |> result.unwrap(default_num_clients)
      let port = int.parse(port_str) |> result.unwrap(default_api_port)
      #(num, host, port)
    }
    [num_str, host, ..] -> {
      let num = int.parse(num_str) |> result.unwrap(default_num_clients)
      #(num, host, default_api_port)
    }
    [num_str, ..] -> {
      let num = int.parse(num_str) |> result.unwrap(default_num_clients)
      #(num, default_api_host, default_api_port)
    }
    _ -> #(default_num_clients, default_api_host, default_api_port)
  }

  io.println("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
  io.println("    Reddit Clone Concurrent Simulator")
  io.println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
  io.println("Configuration:")
  io.println("  Users:  " <> int.to_string(num_clients))
  io.println("  Server: " <> api_host <> ":" <> int.to_string(api_port))
  io.println("\nUsing Zipf distribution for subreddit popularity\n")

  // Start the shared post tracker
  let post_tracker = start_post_tracker()

  run_simulation(post_tracker, num_clients, api_host, api_port)
}

// Message types for post tracking actor
pub type PostTrackingMessage {
  AddPost(subreddit: String, post_id: String)
  GetRandomPost(reply_to: process.Subject(Result(#(String, String), Nil)))
  AddComment(subreddit: String, post_id: String, comment_id: String)
  GetRandomComment(
    reply_to: process.Subject(Result(#(String, String, String), Nil)),
  )
}

// Actor to track posts across all users for voting/commenting
fn start_post_tracker() -> process.Subject(PostTrackingMessage) {
  let parent_subject = process.new_subject()

  process.spawn_unlinked(fn() {
    let subject = process.new_subject()
    process.send(parent_subject, subject)
    post_tracker_loop(subject, [], [])
  })

  let assert Ok(subject) = process.receive(parent_subject, 10_000)
  subject
}

fn post_tracker_loop(
  subject: process.Subject(PostTrackingMessage),
  posts: List(#(String, String)),
  comments: List(#(String, String, String)),
) {
  case process.receive(subject, 10_000) {
    Ok(AddPost(subreddit, post_id)) -> {
      post_tracker_loop(subject, [#(subreddit, post_id), ..posts], comments)
    }
    Ok(GetRandomPost(reply_to)) -> {
      let result = case list.shuffle(posts) |> list.first {
        Ok(post) -> Ok(post)
        Error(_) -> Error(Nil)
      }
      process.send(reply_to, result)
      post_tracker_loop(subject, posts, comments)
    }
    Ok(AddComment(subreddit, post_id, comment_id)) -> {
      post_tracker_loop(subject, posts, [
        #(subreddit, post_id, comment_id),
        ..comments
      ])
    }
    Ok(GetRandomComment(reply_to)) -> {
      let result = case list.shuffle(comments) |> list.first {
        Ok(comment) -> Ok(comment)
        Error(_) -> Error(Nil)
      }
      process.send(reply_to, result)
      post_tracker_loop(subject, posts, comments)
    }
    Error(_) -> {
      // Timeout, continue
      post_tracker_loop(subject, posts, comments)
    }
  }
}

fn run_simulation(
  post_tracker: process.Subject(PostTrackingMessage),
  num_clients: Int,
  api_host: String,
  api_port: Int,
) {
  io.println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
  io.println("Phase 1: Setting up Subreddits")
  io.println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")

  // Register admin user for creating subreddits
  let _ = register_user("admin", api_host, api_port)

  // Create subreddits
  list.each(subreddits_by_rank, fn(subreddit) {
    let #(name, desc, _) = subreddit
    let _ = create_subreddit("admin", name, desc, api_host, api_port)
    io.println("✓ Created subreddit: r/" <> name)
  })
  io.println("")
  process.sleep(500)

  io.println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
  io.println("Phase 2: Spawning User Actors")
  io.println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")

  let completion_subject = process.new_subject()

  // Spawn user actors - each runs independently
  let _user_pids =
    list.range(1, num_clients)
    |> list.map(fn(i) {
      let username = "user" <> int.to_string(i)
      let is_power_user = i <= num_clients / 10

      // Spawn each user as a separate process
      let user_pid =
        process.spawn_unlinked(fn() {
          simulate_user(
            username,
            is_power_user,
            post_tracker,
            api_host,
            api_port,
          )
          process.send(completion_subject, username)
        })

      case i % 10 {
        0 -> io.println("✓ Spawned " <> int.to_string(i) <> " user actors...")
        _ -> Nil
      }
      user_pid
    })

  io.println("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
  io.println("✓ All " <> int.to_string(num_clients) <> " user actors spawned")
  io.println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
  io.println("Simulation running... (this will take a minute)\n")

  // Wait for all users to complete
  wait_for_completions(completion_subject, num_clients, 0)

  io.println("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
  io.println("Subreddit Membership (Zipf Distribution)")
  io.println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")

  report_membership_distribution(api_host, api_port)

  io.println("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
  io.println("Engine Performance Metrics")
  io.println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")

  report_engine_metrics(api_host, api_port)

  io.println("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
  io.println("✓ Simulation Complete!")
  io.println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
}

fn wait_for_completions(
  subject: process.Subject(String),
  total: Int,
  count: Int,
) {
  case process.receive(subject, 120_000) {
    Ok(_username) -> {
      let new_count = count + 1
      case new_count % 10 {
        0 -> io.println("✓ " <> int.to_string(new_count) <> " users completed")
        _ -> Nil
      }
      case new_count >= total {
        True -> Nil
        False -> wait_for_completions(subject, total, new_count)
      }
    }
    Error(_) -> wait_for_completions(subject, total, count)
  }
}

// Each user actor runs independently
fn simulate_user(
  username: String,
  is_power_user: Bool,
  post_tracker: process.Subject(PostTrackingMessage),
  api_host: String,
  api_port: Int,
) {
  // 1. Register
  let _ = register_user(username, api_host, api_port)
  process.sleep(int.random(100) + 50)

  // 2. Join subreddits (Zipf distribution)
  let num_joins = case is_power_user {
    True -> 4 + int.random(3)
    // Power users join 4-6 subreddits
    False -> 2 + int.random(2)
    // Regular users join 2-3
  }

  list.range(1, num_joins)
  |> list.each(fn(_) {
    let subreddit = pick_random_subreddit(is_power_user)
    let _ = join_subreddit(username, subreddit, api_host, api_port)
    process.sleep(int.random(200) + 100)
  })

  // 3. Perform online/offline cycles
  let cycles = case is_power_user {
    True -> 3 + int.random(3)
    // Power users: 3-5 cycles
    False -> 1 + int.random(2)
    // Regular users: 1-2 cycles
  }

  list.range(1, cycles)
  |> list.each(fn(cycle) {
    perform_online_activities(
      username,
      is_power_user,
      cycle,
      post_tracker,
      api_host,
      api_port,
    )

    let online_duration = case is_power_user {
      True -> 1000 + int.random(2000)
      // 1-3 seconds
      False -> 500 + int.random(1000)
      // 0.5-1.5 seconds
    }
    process.sleep(online_duration)

    let offline_duration = int.random(500) + 200
    process.sleep(offline_duration)
  })
}

fn perform_online_activities(
  username: String,
  is_power_user: Bool,
  cycle: Int,
  post_tracker: process.Subject(PostTrackingMessage),
  api_host: String,
  api_port: Int,
) {
  let num_activities = case is_power_user {
    True -> 2 + int.random(4)
    // Power users: 2-5 activities
    False -> 1 + int.random(2)
    // Regular users: 1-2 activities
  }

  list.range(1, num_activities)
  |> list.each(fn(activity_num) {
    let activity_type = int.random(10)

    case activity_type {
      // 30% Create a post
      0 | 1 | 2 -> {
        let subreddit = pick_random_subreddit(is_power_user)
        let title = generate_title(cycle * 100 + activity_num)
        let content = generate_content(cycle * 100 + activity_num)

        case
          create_post(username, subreddit, title, content, api_host, api_port)
        {
          Ok(response_body) -> {
            let decoder = {
              use id <- decode.field("id", decode.string)
              decode.success(id)
            }
            case json.parse(from: response_body, using: decoder) {
              Ok(id) -> process.send(post_tracker, AddPost(subreddit, id))
              Error(_) -> Nil
            }
          }
          Error(_) -> Nil
        }
        process.sleep(int.random(300) + 100)
      }

      // 20% Comment on a post
      3 | 4 -> {
        let reply_subject = process.new_subject()
        process.send(post_tracker, GetRandomPost(reply_subject))

        case process.receive(reply_subject, 5000) {
          Ok(Ok(#(_subreddit, post_id))) -> {
            let _ =
              comment_on_post(
                username,
                post_id,
                "Great post! Interesting thoughts.",
                api_host,
                api_port,
              )
            process.sleep(int.random(200) + 50)
          }
          _ -> Nil
        }
      }

      // 20% Vote on posts
      5 | 6 -> {
        let reply_subject = process.new_subject()
        process.send(post_tracker, GetRandomPost(reply_subject))

        case process.receive(reply_subject, 5000) {
          Ok(Ok(#(_subreddit, post_id))) -> {
            let is_upvote = int.random(2) == 0
            let _ = vote_post(username, post_id, is_upvote, api_host, api_port)
            process.sleep(int.random(100) + 50)
          }
          _ -> Nil
        }
      }

      // 20% Send direct message
      7 | 8 -> {
        // Note: num_clients is not available here, use a reasonable range
        let recipient = "user" <> int.to_string(int.random(100) + 1)
        let _ =
          send_direct_message(
            username,
            recipient,
            "Hey! How's it going?",
            api_host,
            api_port,
          )
        process.sleep(int.random(200) + 50)
      }

      // 10% Get feed
      _ -> {
        let _ = get_feed(username, api_host, api_port)
        process.sleep(int.random(100) + 50)
      }
    }
  })
}

// Zipf distribution for subreddit selection
fn pick_random_subreddit(is_power_user: Bool) -> String {
  case is_power_user {
    True -> pick_subreddit_zipf()
    False -> {
      // Regular users: 70% Zipf, 30% uniform random
      case int.random(10) < 7 {
        True -> pick_subreddit_zipf()
        False ->
          list.shuffle(subreddits_by_rank)
          |> list.first
          |> result.map(fn(s) { s.0 })
          |> result.unwrap("gleam")
      }
    }
  }
}

fn calculate_zipf_distribution() -> List(Float) {
  let ranks = list.range(1, list.length(subreddits_by_rank))
  let weights = list.map(ranks, fn(rank) { 1.0 /. int.to_float(rank) })
  let total = list.fold(weights, 0.0, fn(acc, w) { acc +. w })
  list.map(weights, fn(w) { w /. total })
}

fn pick_subreddit_zipf() -> String {
  let distribution = calculate_zipf_distribution()
  select_by_cumulative_probability(
    subreddits_by_rank,
    distribution,
    float.random(),
    0.0,
  )
}

fn select_by_cumulative_probability(
  subreddits: List(#(String, String, Int)),
  probabilities: List(Float),
  target: Float,
  cumulative: Float,
) -> String {
  case subreddits, probabilities {
    [], _ -> "gleam"
    _, [] -> "gleam"
    [#(name, _, _), ..rest_subs], [p, ..rest_probs] -> {
      let new_cumulative = cumulative +. p
      case target <=. new_cumulative {
        True -> name
        False ->
          select_by_cumulative_probability(
            rest_subs,
            rest_probs,
            target,
            new_cumulative,
          )
      }
    }
  }
}

fn generate_title(index: Int) -> String {
  let titles = [
    "Check out this amazing feature!",
    "Discussion: Best practices",
    "Help needed with implementation",
    "TIL: Interesting fact",
    "Question about this topic",
    "Sharing my recent project",
    "Performance optimization tips",
    "New release announcement",
  ]

  list.shuffle(titles)
  |> list.first
  |> result.map(fn(t) { t <> " #" <> int.to_string(index) })
  |> result.unwrap("Post #" <> int.to_string(index))
}

fn generate_content(index: Int) -> String {
  "This is the content for post #"
  <> int.to_string(index)
  <> ". Lorem ipsum dolor sit amet, consectetur adipiscing elit."
}

fn report_membership_distribution(api_host: String, api_port: Int) {
  list.each(subreddits_by_rank, fn(subreddit) {
    let #(name, _, rank) = subreddit
    case get_subreddit_member_count(name, api_host, api_port) {
      Ok(count) -> {
        io.println(
          "Rank "
          <> int.to_string(rank)
          <> " | r/"
          <> string.pad_end(name, 15, " ")
          <> " | Members: "
          <> int.to_string(count),
        )
      }
      Error(_) -> Nil
    }
  })
}

fn report_engine_metrics(api_host: String, api_port: Int) {
  case get_engine_metrics(api_host, api_port) {
    Ok(metrics_json) -> {
      let decoder = {
        use total_users <- decode.field("total_users", decode.int)
        use total_posts <- decode.field("total_posts", decode.int)
        use total_comments <- decode.field("total_comments", decode.int)
        use total_messages <- decode.field("total_messages", decode.int)

        decode.success(#(
          total_users,
          total_posts,
          total_comments,
          total_messages,
        ))
      }

      case json.parse(from: metrics_json, using: decoder) {
        Ok(#(users, posts, comments, messages)) -> {
          io.println("  Users:    " <> int.to_string(users))
          io.println("  Posts:    " <> int.to_string(posts))
          io.println("  Comments: " <> int.to_string(comments))
          io.println("  Messages: " <> int.to_string(messages))
        }
        Error(_) -> {
          io.println("Raw metrics: " <> metrics_json)
        }
      }
    }
    Error(_) -> {
      io.println("Could not retrieve engine metrics")
    }
  }
}

// HTTP API Helpers

fn register_user(
  username: String,
  api_host: String,
  api_port: Int,
) -> Result(String, String) {
  let body = "username=" <> uri.percent_encode(username)
  post_request("/users", body, None, api_host, api_port)
}

fn create_subreddit(
  username: String,
  name: String,
  description: String,
  api_host: String,
  api_port: Int,
) -> Result(String, String) {
  let body =
    "user_id="
    <> uri.percent_encode("user_" <> username)
    <> "&name="
    <> uri.percent_encode(name)
    <> "&description="
    <> uri.percent_encode(description)
  post_request("/subreddits", body, Some(username), api_host, api_port)
}

fn join_subreddit(
  username: String,
  subreddit: String,
  api_host: String,
  api_port: Int,
) -> Result(String, String) {
  put_request(
    "/users/"
      <> uri.percent_encode("user_" <> username)
      <> "/subscriptions/"
      <> uri.percent_encode("r_" <> subreddit),
    "",
    Some(username),
    api_host,
    api_port,
  )
}

fn create_post(
  username: String,
  subreddit: String,
  title: String,
  content: String,
  api_host: String,
  api_port: Int,
) -> Result(String, String) {
  let body =
    "user_id="
    <> uri.percent_encode("user_" <> username)
    <> "&title="
    <> uri.percent_encode(title)
    <> "&content="
    <> uri.percent_encode(content)

  post_request(
    "/subreddits/" <> uri.percent_encode("r_" <> subreddit) <> "/posts",
    body,
    Some(username),
    api_host,
    api_port,
  )
}

fn comment_on_post(
  username: String,
  post_id: String,
  content: String,
  api_host: String,
  api_port: Int,
) -> Result(String, String) {
  let body =
    "user_id="
    <> uri.percent_encode("user_" <> username)
    <> "&content="
    <> uri.percent_encode(content)

  post_request(
    "/posts/" <> uri.percent_encode(post_id) <> "/comments",
    body,
    Some(username),
    api_host,
    api_port,
  )
}

fn vote_post(
  username: String,
  post_id: String,
  is_upvote: Bool,
  api_host: String,
  api_port: Int,
) -> Result(String, String) {
  let body =
    "user_id="
    <> uri.percent_encode("user_" <> username)
    <> "&vote="
    <> case is_upvote {
      True -> "upvote"
      False -> "downvote"
    }

  post_request(
    "/posts/" <> uri.percent_encode(post_id) <> "/votes",
    body,
    Some(username),
    api_host,
    api_port,
  )
}

fn send_direct_message(
  from: String,
  to: String,
  content: String,
  api_host: String,
  api_port: Int,
) -> Result(String, String) {
  let body =
    "from_user_id="
    <> uri.percent_encode("user_" <> from)
    <> "&to_user_id="
    <> uri.percent_encode("user_" <> to)
    <> "&content="
    <> uri.percent_encode(content)

  post_request(
    "/users/" <> uri.percent_encode("user_" <> to) <> "/dms",
    body,
    Some(from),
    api_host,
    api_port,
  )
}

fn get_feed(
  username: String,
  api_host: String,
  api_port: Int,
) -> Result(String, String) {
  get_request(
    "/users/" <> uri.percent_encode("user_" <> username) <> "/feed",
    Some(username),
    api_host,
    api_port,
  )
}

fn get_subreddit_member_count(
  subreddit: String,
  api_host: String,
  api_port: Int,
) -> Result(Int, String) {
  case
    get_request(
      "/subreddits/" <> uri.percent_encode("r_" <> subreddit) <> "/members",
      None,
      api_host,
      api_port,
    )
  {
    Ok(body) -> {
      let decoder = {
        use member_count <- decode.field("member_count", decode.int)
        decode.success(member_count)
      }

      case json.parse(from: body, using: decoder) {
        Ok(count) -> Ok(count)
        Error(_) -> Error("Failed to decode member count")
      }
    }
    Error(e) -> Error(e)
  }
}

fn get_engine_metrics(api_host: String, api_port: Int) -> Result(String, String) {
  get_request("/metrics", None, api_host, api_port)
}

fn post_request(
  path: String,
  body: String,
  _auth_user: Option(String),
  api_host: String,
  api_port: Int,
) -> Result(String, String) {
  let req =
    request.new()
    |> request.set_method(http.Post)
    |> request.set_scheme(http.Http)
    |> request.set_host(api_host)
    |> request.set_port(api_port)
    |> request.set_path(path)
    |> request.set_body(body)
    |> request.set_header("content-type", "application/x-www-form-urlencoded")

  case httpc.send(req) {
    Ok(resp) ->
      case resp.status {
        200 | 201 -> Ok(resp.body)
        _ ->
          Error(
            "Request failed with status "
            <> int.to_string(resp.status)
            <> ": "
            <> resp.body,
          )
      }
    Error(_) -> Error("HTTP request failed")
  }
}

fn get_request(
  path: String,
  _auth_user: Option(String),
  api_host: String,
  api_port: Int,
) -> Result(String, String) {
  let req =
    request.new()
    |> request.set_method(http.Get)
    |> request.set_scheme(http.Http)
    |> request.set_host(api_host)
    |> request.set_port(api_port)
    |> request.set_path(path)

  case httpc.send(req) {
    Ok(resp) ->
      case resp.status {
        200 -> Ok(resp.body)
        _ -> Error("Request failed with status " <> int.to_string(resp.status))
      }
    Error(_) -> Error("HTTP request failed")
  }
}

fn put_request(
  path: String,
  body: String,
  _auth_user: Option(String),
  api_host: String,
  api_port: Int,
) -> Result(String, String) {
  let req =
    request.new()
    |> request.set_method(http.Put)
    |> request.set_scheme(http.Http)
    |> request.set_host(api_host)
    |> request.set_port(api_port)
    |> request.set_path(path)
    |> request.set_body(body)
    |> request.set_header("content-type", "application/x-www-form-urlencoded")

  case httpc.send(req) {
    Ok(resp) ->
      case resp.status {
        200 -> Ok(resp.body)
        _ -> Error("Request failed with status " <> int.to_string(resp.status))
      }
    Error(_) -> Error("HTTP request failed")
  }
}
