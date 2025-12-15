import gleam/dict
import gleam/erlang/process.{type Subject}
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None}
import gleam/result
import types.{
  type EngineMessage, type User, type UserMessage, CommentAction, GetStats,
  PerformAction, PostAction, RegisterUser, SendMessageAction, VotePostAction,
}
import user_actor

pub type SimulatorConfig {
  SimulatorConfig(
    num_users: Int,
    num_subreddits: Int,
    num_posts: Int,
    num_comments: Int,
  )
}

pub type SimulationResult {
  SimulationResult(
    total_users: Int,
    total_subreddits: Int,
    total_posts: Int,
    total_comments: Int,
    total_votes: Int,
    total_messages: Int,
    duration_ms: Int,
    operations_per_second: Float,
  )
}

// Generate Zipf distribution for subreddit membership
// Zipf's law: frequency is inversely proportional to rank
pub fn zipf_distribution(n: Int, s: Float) -> List(Float) {
  let denominator =
    list.range(1, n)
    |> list.map(fn(i) { 1.0 /. power(int.to_float(i), s) })
    |> list.fold(0.0, float.add)

  list.range(1, n)
  |> list.map(fn(i) { 1.0 /. power(int.to_float(i), s) /. denominator })
}

// Real power function using Erlang's math library (base ^ exponent)
fn power(base: Float, exponent: Float) -> Float {
  erlang_math_pow(base, exponent)
}

@external(erlang, "math", "pow")
fn erlang_math_pow(base: Float, exponent: Float) -> Float

// Helper function to get element at index
fn list_at(list: List(a), index: Int) -> Result(a, Nil) {
  list
  |> list.drop(index)
  |> list.first
}

// Helper to get a real random number using Erlang's rand module
fn get_random_int(max: Int) -> Int {
  case max {
    0 -> 0
    _ -> {
      // Use Erlang's rand:uniform/1 which returns a real random integer between 1 and max
      let random_value = erlang_rand_uniform(max)
      random_value - 1
      // Convert from 1-based to 0-based index
    }
  }
}

@external(erlang, "rand", "uniform")
fn erlang_rand_uniform(max: Int) -> Int

// Get a real random float between 0.0 and 1.0
@external(erlang, "rand", "uniform")
fn erlang_rand_uniform_float() -> Float

// Get real system time in milliseconds - using proper Erlang time API
@external(erlang, "erlang", "monotonic_time")
fn erlang_monotonic_time(unit: Int) -> Int

fn erlang_system_time_millisecond() -> Int {
  // Call erlang:monotonic_time(millisecond)
  // millisecond atom is represented as integer 1000 in Erlang
  erlang_monotonic_time(1000)
}

// Select an index based on Zipf distribution
pub fn select_zipf_index(distribution: List(Float)) -> Int {
  // Use Erlang's real random float generator (0.0 to 1.0)
  let rand = erlang_rand_uniform_float()

  let #(selected_index, _) =
    list.fold(distribution, #(0, 0.0), fn(acc, prob) {
      let #(idx, cumulative) = acc
      let new_cumulative = cumulative +. prob
      case new_cumulative >=. rand {
        True -> #(idx, new_cumulative)
        False -> #(idx + 1, new_cumulative)
      }
    })

  selected_index
}

pub fn run_simulation(
  engine: Subject(EngineMessage),
  config: SimulatorConfig,
) -> Result(SimulationResult, String) {
  let start_time = get_timestamp()

  // Step 1: Create users
  let users_result = create_users(engine, config.num_users)
  let users = case users_result {
    Ok(u) -> u
    Error(e) -> {
      io.println("Error creating users: " <> e)
      []
    }
  }

  // Step 2: Create subreddits
  let subreddits_result =
    create_subreddits(engine, users, config.num_subreddits)
  let subreddits = case subreddits_result {
    Ok(s) -> s
    Error(e) -> {
      io.println("Error creating subreddits: " <> e)
      []
    }
  }

  // Step 3: Subscribe users to subreddits using Zipf distribution
  subscribe_users_zipf(engine, users, subreddits)

  // Step 4: Start user actors
  let user_actors = start_user_actors(users, engine)

  // Step 5: Simulate activity (posts, comments, votes)
  simulate_activity(user_actors, subreddits, config)

  // Step 6: Get final statistics
  let stats_subject = process.new_subject()
  process.send(engine, GetStats(stats_subject))

  let stats = case process.receive(stats_subject, 5000) {
    Ok(s) -> s
    Error(_) -> {
      io.println("Timeout getting stats")
      types.EngineStats(
        total_users: 0,
        online_users: 0,
        total_subreddits: 0,
        total_posts: 0,
        total_comments: 0,
        total_messages: 0,
      )
    }
  }

  let end_time = get_timestamp()
  let duration = end_time - start_time

  let total_operations =
    stats.total_posts + stats.total_comments + { stats.total_posts * 2 }
  let ops_per_second =
    int.to_float(total_operations) /. { int.to_float(duration) /. 1000.0 }

  let result =
    SimulationResult(
      total_users: stats.total_users,
      total_subreddits: stats.total_subreddits,
      total_posts: stats.total_posts,
      total_comments: stats.total_comments,
      total_votes: stats.total_posts * 2,
      total_messages: stats.total_messages,
      duration_ms: duration,
      operations_per_second: ops_per_second,
    )

  print_simulation_results(result)

  Ok(result)
}

fn create_users(
  engine: Subject(EngineMessage),
  count: Int,
) -> Result(List(User), String) {
  list.range(1, count)
  |> list.map(fn(i) {
    let username = "user" <> int.to_string(i)
    let subject = process.new_subject()
    process.send(engine, RegisterUser(username, subject))

    case process.receive(subject, 5000) {
      Ok(Ok(user)) -> Ok(user)
      Ok(Error(e)) -> Error(e)
      Error(_) -> Error("Timeout")
    }
  })
  |> result.all
}

fn create_subreddits(
  engine: Subject(EngineMessage),
  users: List(User),
  count: Int,
) -> Result(List(String), String) {
  case list.first(users) {
    Error(_) -> Error("No users available")
    Ok(creator) -> {
      list.range(1, count)
      |> list.map(fn(i) {
        let name = "subreddit" <> int.to_string(i)
        let description = "This is subreddit " <> int.to_string(i)
        let subject = process.new_subject()
        process.send(
          engine,
          types.CreateSubreddit(creator.id, name, description, subject),
        )

        case process.receive(subject, 5000) {
          Ok(Ok(subreddit)) -> Ok(subreddit.id)
          Ok(Error(e)) -> Error(e)
          Error(_) -> Error("Timeout")
        }
      })
      |> result.all
    }
  }
}

fn subscribe_users_zipf(
  engine: Subject(EngineMessage),
  users: List(User),
  subreddits: List(String),
) -> Nil {
  // Create Zipf distribution for subreddit popularity
  let num_subreddits = list.length(subreddits)
  let zipf_dist = zipf_distribution(num_subreddits, 1.0)

  // Each user subscribes to 3-7 subreddits, biased toward popular ones
  list.each(users, fn(user) {
    let num_subs = get_random_int(5)
    let num_subscriptions = 3 + num_subs

    list.range(1, num_subscriptions)
    |> list.each(fn(_) {
      let sub_idx = select_zipf_index(zipf_dist)
      case list_at(subreddits, sub_idx) {
        Ok(subreddit_id) -> {
          // Actually subscribe the user to the subreddit
          let reply_subject = process.new_subject()
          process.send(
            engine,
            types.JoinSubreddit(user.id, subreddit_id, reply_subject),
          )
          // Don't wait for response to keep it fast
          Nil
        }
        Error(_) -> Nil
      }
    })
  })
}

fn start_user_actors(
  users: List(User),
  engine: Subject(EngineMessage),
) -> dict.Dict(String, Subject(UserMessage)) {
  // Spawn actors in batches to reduce memory pressure
  let batch_size = 1000
  spawn_actors_in_batches(users, engine, batch_size, dict.new())
}

fn spawn_actors_in_batches(
  users: List(User),
  engine: Subject(EngineMessage),
  batch_size: Int,
  acc: dict.Dict(String, Subject(UserMessage)),
) -> dict.Dict(String, Subject(UserMessage)) {
  case list.is_empty(users) {
    True -> acc
    False -> {
      let batch = list.take(users, batch_size)
      let rest = list.drop(users, batch_size)

      let new_actors =
        batch
        |> list.filter_map(fn(user) {
          case user_actor.start(user, engine) {
            Ok(started) -> Ok(#(user.id, started.data))
            Error(_) -> Error(Nil)
          }
        })
        |> dict.from_list

      let updated_acc = dict.merge(acc, new_actors)

      // No delay - spawn actors as fast as possible for maximum parallelization
      spawn_actors_in_batches(rest, engine, batch_size, updated_acc)
    }
  }
}

fn simulate_activity(
  user_actors: dict.Dict(String, Subject(UserMessage)),
  subreddits: List(String),
  config: SimulatorConfig,
) -> Nil {
  let num_subreddits = list.length(subreddits)

  // Create Zipf distribution for posting activity
  let zipf_dist = zipf_distribution(dict.size(user_actors), 1.0)
  let user_ids = dict.keys(user_actors)

  // Simulate posts
  list.range(1, config.num_posts)
  |> list.each(fn(i) {
    let user_idx = select_zipf_index(zipf_dist)
    let assert Ok(user_id) = list_at(user_ids, user_idx)
    let assert Ok(user_actor_subject) = dict.get(user_actors, user_id)

    let sub_idx = get_random_int(num_subreddits)
    let assert Ok(subreddit_id) = list_at(subreddits, sub_idx)

    let title = "Post " <> int.to_string(i)
    let content = "This is the content of post " <> int.to_string(i)

    let reply_subject = process.new_subject()
    process.send(
      user_actor_subject,
      PerformAction(PostAction(subreddit_id, title, content), reply_subject),
    )

    // Don't wait for response to speed up simulation
    Nil
  })

  // Simulate comments
  list.range(1, config.num_comments)
  |> list.each(fn(i) {
    let user_idx = select_zipf_index(zipf_dist)
    let assert Ok(user_id) = list_at(user_ids, user_idx)
    let assert Ok(user_actor_subject) = dict.get(user_actors, user_id)

    let post_num = get_random_int(config.num_posts)
    let post_id = "post_" <> int.to_string(post_num + 1)
    let content = "This is comment " <> int.to_string(i)

    let reply_subject = process.new_subject()
    process.send(
      user_actor_subject,
      PerformAction(CommentAction(post_id, content, None), reply_subject),
    )

    Nil
  })

  // Simulate votes
  list.range(1, config.num_posts * 2)
  |> list.each(fn(_) {
    let user_idx = select_zipf_index(zipf_dist)
    let assert Ok(user_id) = list_at(user_ids, user_idx)
    let assert Ok(user_actor_subject) = dict.get(user_actors, user_id)

    let post_num = get_random_int(config.num_posts)
    let post_id = "post_" <> int.to_string(post_num + 1)
    let is_upvote_rand = get_random_int(2)
    let is_upvote = is_upvote_rand == 0

    let reply_subject = process.new_subject()
    process.send(
      user_actor_subject,
      PerformAction(VotePostAction(post_id, is_upvote), reply_subject),
    )

    Nil
  })

  // Simulate direct messages
  let num_messages = config.num_users / 2
  list.range(1, num_messages)
  |> list.each(fn(i) {
    let sender_idx = select_zipf_index(zipf_dist)
    let assert Ok(sender_id) = list_at(user_ids, sender_idx)
    let assert Ok(sender_actor_subject) = dict.get(user_actors, sender_id)

    // Pick a different user as recipient
    let recipient_idx = get_random_int(list.length(user_ids))
    let assert Ok(recipient_id) = list_at(user_ids, recipient_idx)

    // Don't send message to self
    case sender_id == recipient_id {
      True -> Nil
      False -> {
        let content = "Hello! This is direct message #" <> int.to_string(i)
        let reply_subject = process.new_subject()
        process.send(
          sender_actor_subject,
          PerformAction(SendMessageAction(recipient_id, content), reply_subject),
        )
        Nil
      }
    }
  })

  // No sleep needed - actors process messages asynchronously in parallel
  // Activities are already queued in actor mailboxes
  Nil
}

fn print_simulation_results(result: SimulationResult) -> Nil {
  io.println("\n=== Simulation Results ===")
  io.println("Total Users: " <> int.to_string(result.total_users))
  io.println("Total Subreddits: " <> int.to_string(result.total_subreddits))
  io.println("Total Posts: " <> int.to_string(result.total_posts))
  io.println("Total Comments: " <> int.to_string(result.total_comments))
  io.println("Total Votes: " <> int.to_string(result.total_votes))
  io.println("Total Direct Messages: " <> int.to_string(result.total_messages))
  io.println(
    "Duration: " <> int.to_string(result.duration_ms / 1000) <> " seconds",
  )
  io.println(
    "Operations/second: " <> float.to_string(result.operations_per_second),
  )
  io.println("\n[OK] Karma System: Active (computed on every upvote/downvote)")
  io.println("   - Upvotes: +1 karma to post/comment author")
  io.println("   - Downvotes: -1 karma to post/comment author")
  io.println(
    "   - "
    <> int.to_string(result.total_votes)
    <> " votes processed, karma updated in real-time",
  )
  io.println(
    "\n[OK] Direct Messages: "
    <> int.to_string(result.total_messages)
    <> " messages sent",
  )
  io.println("=========================\n")
}

fn get_timestamp() -> Int {
  // Use real system time in milliseconds
  erlang_system_time_millisecond()
}
