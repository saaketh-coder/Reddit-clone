// Scalable simulator using short-lived processes (like 900K reference implementation)
import engine
import gleam/erlang/process.{type Subject}
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None}
import gleam/string
import types.{
  type EngineMessage, CreateComment, CreatePost, CreateSubreddit, GetStats,
  JoinSubreddit, RegisterUser, SendDirectMessage, VotePost,
}

pub type SimulationResult {
  SimulationResult(
    total_users: Int,
    total_posts: Int,
    total_comments: Int,
    total_messages: Int,
    duration_ms: Int,
    operations_per_second: Float,
  )
}

// Get real random functions
@external(erlang, "rand", "uniform")
fn erlang_rand_uniform(max: Int) -> Int

@external(erlang, "rand", "uniform")
fn erlang_rand_uniform_float() -> Float

@external(erlang, "erlang", "monotonic_time")
fn erlang_monotonic_time(unit: Int) -> Int

fn get_random_int(max: Int) -> Int {
  case max {
    0 -> 0
    _ -> erlang_rand_uniform(max) - 1
  }
}

fn random_float() -> Float {
  erlang_rand_uniform_float()
}

// Zipf distribution for realistic subreddit popularity
fn zipf_weights(num_subreddits: Int) -> List(Float) {
  let weights =
    list.range(1, num_subreddits)
    |> list.map(fn(rank) { 1.0 /. int.to_float(rank) })

  let total =
    weights
    |> list.fold(0.0, float.add)

  weights
  |> list.map(fn(w) { w /. total })
}

fn select_zipf_index(weights: List(Float)) -> Int {
  let rand = random_float()
  let #(selected, _) =
    list.fold(weights, #(0, 0.0), fn(acc, weight) {
      let #(current_idx, cumulative) = acc
      let new_cumulative = cumulative +. weight
      case rand <=. new_cumulative && current_idx == 0 {
        True -> #(
          list.length(weights) - list.length(weights) + current_idx,
          new_cumulative,
        )
        False -> #(current_idx + 1, new_cumulative)
      }
    })
  selected
}

// Short-lived user simulation (spawns, does activities, terminates)
fn simulate_user(
  user_id: Int,
  engine: Subject(EngineMessage),
  subreddits: List(String),
  zipf_weights: List(Float),
  is_power_user: Bool,
  completion_subject: Subject(String),
) -> Nil {
  let username = int.to_string(user_id)
  // Just use number, engine will prefix "user_"

  // 1. Register user
  io.println("[REG] " <> username <> " registering...")
  let reply_reg = process.new_subject()
  process.send(engine, RegisterUser(username, reply_reg))

  // Get the actual user_id from registration response
  let user_id_str = case process.receive_forever(reply_reg) {
    Ok(user) -> {
      io.println(
        "[REG] " <> username <> " registered successfully as " <> user.id,
      )
      user.id
      // This is the actual user_id like "user_0"
    }
    Error(err) -> {
      io.println("[REG] " <> username <> " registration failed: " <> err)
      // Signal completion and exit
      process.send(completion_subject, username)
      panic as "Registration failed"
    }
  }

  // 2. Join subreddits and track which ones we joined
  let num_to_join = case is_power_user {
    True -> 5 + get_random_int(4)
    // Power users: 5-8 subreddits
    False -> 2 + get_random_int(3)
    // Regular users: 2-4 subreddits
  }

  let joined_subreddits =
    list.range(1, num_to_join)
    |> list.filter_map(fn(_) {
      let subreddit_idx = case is_power_user {
        True -> select_zipf_index(zipf_weights)
        // Power users follow Zipf
        False -> {
          // Regular users: 70% Zipf, 30% uniform
          case random_float() <. 0.7 {
            True -> select_zipf_index(zipf_weights)
            False -> get_random_int(list.length(subreddits))
          }
        }
      }

      case list_at(subreddits, subreddit_idx) {
        Ok(subreddit) -> {
          let reply_join = process.new_subject()
          io.println(
            "[JOIN] " <> user_id_str <> " attempting to join " <> subreddit,
          )
          process.send(
            engine,
            JoinSubreddit(user_id_str, subreddit, reply_join),
          )
          let join_result = process.receive_forever(reply_join)
          case join_result {
            Ok(_success_msg) -> {
              io.println(
                "[JOIN SUCCESS] " <> user_id_str <> " joined " <> subreddit,
              )
              Ok(subreddit)
            }
            Error(err_msg) -> {
              io.println(
                "[JOIN FAILED] "
                <> user_id_str
                <> " failed to join "
                <> subreddit
                <> ": "
                <> err_msg,
              )
              Error(Nil)
            }
          }
        }
        Error(_) -> Error(Nil)
      }
    })

  // Make sure user joined at least one subreddit
  case list.is_empty(joined_subreddits) {
    True -> {
      io.println(
        "[ERROR] " <> user_id_str <> " failed to join any subreddits, exiting",
      )
      process.send(completion_subject, username)
      Nil
    }
    False -> {
      // 3. Perform online/offline cycles
      let cycles = case is_power_user {
        True -> 5 + get_random_int(5)
        // 5-10 cycles
        False -> 2 + get_random_int(3)
        // 2-5 cycles
      }

      list.range(1, cycles)
      |> list.each(fn(_cycle) {
        // Online duration
        let online_duration = case is_power_user {
          True -> 2000 + get_random_int(3000)
          // 2-5 seconds
          False -> 1000 + get_random_int(2000)
          // 1-3 seconds
        }

        // Perform activities while online - pass joined subreddits only
        perform_online_activities(
          engine,
          user_id_str,
          joined_subreddits,
          zipf_weights,
          is_power_user,
          online_duration,
        )

        // Offline duration (simulate inactivity)
        let offline_duration = case is_power_user {
          True -> 500 + get_random_int(1000)
          // 0.5-1.5 seconds
          False -> 1000 + get_random_int(2000)
          // 1-3 seconds
        }
        process.sleep(offline_duration)
      })

      // Signal completion
      process.send(completion_subject, username)
    }
  }
}

// Perform activities during online period
fn perform_online_activities(
  engine: Subject(EngineMessage),
  user_id: String,
  subreddits: List(String),
  zipf_weights: List(Float),
  is_power_user: Bool,
  duration_ms: Int,
) -> Nil {
  let start_time = erlang_monotonic_time(1000)
  let end_time = start_time + duration_ms

  // Keep track of posts created by this user for commenting/voting
  perform_activities_loop(
    engine,
    user_id,
    subreddits,
    zipf_weights,
    is_power_user,
    end_time,
    [],
  )
}

fn perform_activities_loop(
  engine: Subject(EngineMessage),
  user_id: String,
  subreddits: List(String),
  zipf_weights: List(Float),
  is_power_user: Bool,
  end_time: Int,
  created_posts: List(String),
) -> Nil {
  let current_time = erlang_monotonic_time(1000)

  case current_time >= end_time {
    True -> Nil
    False -> {
      // Pick random subreddit
      let subreddit_idx = case is_power_user {
        True -> select_zipf_index(zipf_weights)
        False -> {
          case random_float() <. 0.7 {
            True -> select_zipf_index(zipf_weights)
            False -> get_random_int(list.length(subreddits))
          }
        }
      }

      case list_at(subreddits, subreddit_idx) {
        Ok(subreddit) -> {
          // Choose activity based on probability
          let rand = random_float()
          let new_posts = case rand {
            r if r <. 0.4 -> {
              // 40% - Create post (WAIT for response to get post ID)
              let title = "Post from " <> user_id
              let content = "Content from " <> user_id <> " in r/" <> subreddit
              let reply = process.new_subject()
              io.println(
                "[DEBUG] " <> user_id <> " creating post in " <> subreddit,
              )
              process.send(
                engine,
                CreatePost(user_id, subreddit, title, content, False, reply),
              )
              // Wait for response with longer timeout (engine is busy)
              case process.receive(reply, 2000) {
                Ok(Ok(post)) -> {
                  io.println("[SUCCESS] Created post " <> post.id)
                  [post.id, ..created_posts]
                }
                Ok(Error(err)) -> {
                  io.println("[ERROR] Post creation failed: " <> err)
                  created_posts
                }
                Error(_) -> {
                  io.println("[TIMEOUT] Post creation timed out")
                  created_posts
                }
              }
            }
            r if r <. 0.65 -> {
              // 25% - Comment on existing post (WAIT for response)
              // Try own posts first, then guess other posts
              let post_id = case created_posts {
                [my_post, ..] -> my_post
                [] -> {
                  // Guess a random post ID that might exist
                  "post_" <> int.to_string(1 + get_random_int(1000))
                }
              }

              let comment_content = "Comment by " <> user_id
              let reply = process.new_subject()
              io.println(
                "[DEBUG] " <> user_id <> " creating comment on " <> post_id,
              )
              process.send(
                engine,
                CreateComment(user_id, post_id, comment_content, None, reply),
              )
              // Wait for response
              case process.receive(reply, 2000) {
                Ok(Ok(comment)) -> {
                  io.println("[SUCCESS] Created comment " <> comment.id)
                  created_posts
                }
                Ok(Error(err)) -> {
                  io.println("[ERROR] Comment creation failed: " <> err)
                  created_posts
                }
                Error(_) -> {
                  io.println("[TIMEOUT] Comment creation timed out")
                  created_posts
                }
              }
            }
            r if r <. 0.75 -> {
              // 10% - Send DM to another user (use valid user IDs)
              let target_user_id = get_random_int(10_000)
              let target_user = "user_" <> int.to_string(target_user_id)
              // Need full user_id
              let message = "Hello from " <> user_id
              let reply = process.new_subject()
              process.send(
                engine,
                SendDirectMessage(user_id, target_user, message, None, reply),
              )
              // Don't need to wait for DM response
              created_posts
            }
            r if r <. 0.95 -> {
              // 20% - Vote on existing post (WAIT for response)
              // Try own posts first, then guess other posts
              let post_id = case created_posts {
                [my_post, ..] -> my_post
                [] -> {
                  // Guess a random post ID that might exist
                  "post_" <> int.to_string(1 + get_random_int(1000))
                }
              }

              let is_upvote = random_float() >. 0.5
              let reply = process.new_subject()
              process.send(engine, VotePost(user_id, post_id, is_upvote, reply))
              // Wait for response
              case process.receive(reply, 2000) {
                Ok(Ok(_)) -> created_posts
                Ok(Error(_)) -> created_posts
                Error(_) -> created_posts
              }
            }
            _ -> {
              // 5% - Get feed (skip for performance)
              created_posts
            }
          }

          // Small random delay between activities
          process.sleep(100 + get_random_int(200))
          // 100-300ms

          // Continue loop
          perform_activities_loop(
            engine,
            user_id,
            subreddits,
            zipf_weights,
            is_power_user,
            end_time,
            new_posts,
          )
        }
        Error(_) -> Nil
      }
    }
  }
}

// Helper to get list element
fn list_at(list: List(a), index: Int) -> Result(a, Nil) {
  list
  |> list.drop(index)
  |> list.first
}

// Wait for user completions
fn wait_for_completions(subject: Subject(String), total: Int, count: Int) -> Nil {
  case count >= total {
    True -> {
      io.println(
        "✓ All " <> int.to_string(total) <> " users completed their cycles",
      )
    }
    False -> {
      case process.receive(subject, 120_000) {
        Ok(_username) -> {
          let new_count = count + 1
          // Print progress every 10%
          let progress = new_count * 100 / total
          let prev_progress = count * 100 / total
          case progress / 10 > prev_progress / 10 {
            True ->
              io.println(
                "Progress: "
                <> int.to_string(progress)
                <> "% ("
                <> int.to_string(new_count)
                <> "/"
                <> int.to_string(total)
                <> " users completed)",
              )
            False -> Nil
          }
          wait_for_completions(subject, total, new_count)
        }
        Error(_) -> {
          io.println(
            "⚠ Timeout waiting for user completions. Got "
            <> int.to_string(count)
            <> "/"
            <> int.to_string(total),
          )
        }
      }
    }
  }
}

// Main simulation runner
pub fn run_scalable_simulation(
  num_users: Int,
  num_subreddits: Int,
) -> SimulationResult {
  io.println("\n=== Scalable Reddit Simulation (Short-lived Processes) ===")
  io.println("Users: " <> int.to_string(num_users))
  io.println("Subreddits: " <> int.to_string(num_subreddits))

  // Start engine
  let assert Ok(engine_started) = engine.start()
  let engine_subject = engine_started.data
  io.println("✓ Engine started")

  // Register admin user
  io.println("\n1. Registering admin user...")
  let admin_reply = process.new_subject()
  process.send(engine_subject, RegisterUser("admin", admin_reply))
  let admin_user = process.receive_forever(admin_reply)
  let admin_id = case admin_user {
    Ok(user) -> {
      io.println("✓ Admin user registered as " <> user.id)
      user.id
    }
    Error(_) -> {
      io.println("ERROR: Failed to register admin")
      "user_admin"
      // fallback
    }
  }

  // Create subreddits
  let subreddits =
    list.range(1, num_subreddits)
    |> list.map(fn(i) { "r_sub_" <> int.to_string(i) })
  // Use proper subreddit IDs

  io.println("\n2. Creating subreddits...")
  list.each(subreddits, fn(sub_id) {
    // Extract name from ID (remove "r_" prefix)
    let name = case string.starts_with(sub_id, "r_") {
      True -> string.drop_start(sub_id, 2)
      False -> sub_id
    }
    let reply = process.new_subject()
    io.println(
      "[CREATE_SUB] Creating subreddit with name="
      <> name
      <> ", expected_id="
      <> sub_id,
    )
    process.send(
      engine_subject,
      CreateSubreddit(admin_id, name, "Subreddit " <> sub_id, reply),
    )
    let result = process.receive_forever(reply)
    case result {
      Ok(sub) ->
        io.println(
          "[CREATE_SUB_SUCCESS] Created subreddit: "
          <> sub.name
          <> " with id="
          <> sub.id,
        )
      Error(err) ->
        io.println("[CREATE_SUB_ERROR] Failed to create subreddit: " <> err)
    }
    Nil
  })
  io.println("✓ Created " <> int.to_string(num_subreddits) <> " subreddits")

  // Calculate Zipf distribution
  let weights = zipf_weights(num_subreddits)

  // Start timing
  let start_time = erlang_monotonic_time(1000)

  io.println(
    "\n3. Spawning " <> int.to_string(num_users) <> " user processes...",
  )

  // Create completion tracking subject
  let completion_subject = process.new_subject()

  // Spawn users in batches to avoid overwhelming the system
  let batch_size = 5000
  let num_batches = { num_users + batch_size - 1 } / batch_size

  list.range(0, num_batches - 1)
  |> list.each(fn(batch_idx) {
    let start_user = batch_idx * batch_size
    let end_user = int.min(start_user + batch_size - 1, num_users - 1)
    let batch_count = end_user - start_user + 1

    io.println(
      "Spawning batch "
      <> int.to_string(batch_idx + 1)
      <> "/"
      <> int.to_string(num_batches)
      <> " (users "
      <> int.to_string(start_user)
      <> "-"
      <> int.to_string(end_user)
      <> ")",
    )

    list.range(start_user, end_user)
    |> list.each(fn(i) {
      let is_power_user = i < { num_users / 10 }
      // Top 10% are power users

      process.spawn_unlinked(fn() {
        simulate_user(
          i,
          engine_subject,
          subreddits,
          weights,
          is_power_user,
          completion_subject,
        )
      })
    })

    io.println("✓ Spawned " <> int.to_string(batch_count) <> " user processes")
  })

  io.println("\n4. Users are performing activities (online/offline cycles)...")

  // Wait for all users to complete
  wait_for_completions(completion_subject, num_users, 0)

  // Give engine MORE time to process remaining messages (important!)
  io.println("\nWaiting for engine to process remaining messages...")
  process.sleep(30_000)
  // 30 seconds for engine to catch up

  // Get final stats
  let stats_subject = process.new_subject()
  process.send(engine_subject, GetStats(stats_subject))

  let stats = process.receive_forever(stats_subject)

  let end_time = erlang_monotonic_time(1000)
  let duration_ms = end_time - start_time

  let total_operations =
    stats.total_posts + stats.total_comments + stats.total_messages

  let operations_per_second = case duration_ms {
    0 -> 0.0
    _ -> {
      int.to_float(total_operations) *. 1000.0 /. int.to_float(duration_ms)
    }
  }

  // Print results
  io.println("\n=== Simulation Complete ===")
  io.println("Total Users: " <> int.to_string(stats.total_users))
  io.println("Total Posts: " <> int.to_string(stats.total_posts))
  io.println("Total Comments: " <> int.to_string(stats.total_comments))
  io.println("Total Direct Messages: " <> int.to_string(stats.total_messages))
  io.println("Duration: " <> int.to_string(duration_ms / 1000) <> " seconds")
  io.println("Operations/second: " <> float.to_string(operations_per_second))

  SimulationResult(
    total_users: stats.total_users,
    total_posts: stats.total_posts,
    total_comments: stats.total_comments,
    total_messages: stats.total_messages,
    duration_ms: duration_ms,
    operations_per_second: operations_per_second,
  )
}
