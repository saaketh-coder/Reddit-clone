import gleam/dict
import gleam/erlang/process.{type Subject}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/string
import types.{
  type Comment, type DirectMessage, type EngineMessage, type EngineState,
  type EngineStats, type Post, type Subreddit, type User, type UserMessage,
  Comment, CreateComment, CreatePost, CreateSubreddit, DirectMessage,
  EngineState, GetDirectMessages, GetFeed, GetStats, GetSubredditMemberCount,
  GetUserKarma, JoinSubreddit, LeaveSubreddit, RegisterUser, SearchSubreddits,
  SearchUsers, SendDirectMessage, SetUserOffline, SetUserOnline, Shutdown,
  Subreddit, User, VoteComment, VotePost,
}

pub fn start() -> Result(
  actor.Started(Subject(EngineMessage)),
  actor.StartError,
) {
  let initial_state =
    EngineState(
      users: dict.new(),
      subreddits: dict.new(),
      posts: dict.new(),
      comments: dict.new(),
      direct_messages: dict.new(),
      user_actors: dict.new(),
      next_post_id: 1,
      next_comment_id: 1,
      next_message_id: 1,
    )

  actor.new(initial_state)
  |> actor.on_message(handle_message)
  |> actor.start
}

fn handle_message(
  state: EngineState,
  message: EngineMessage,
) -> actor.Next(EngineState, EngineMessage) {
  case message {
    RegisterUser(username, reply) -> {
      let result = register_user(state, username)
      case result {
        Ok(#(user, new_state)) -> {
          process.send(reply, Ok(user))
          actor.continue(new_state)
        }
        Error(err) -> {
          process.send(reply, Error(err))
          actor.continue(state)
        }
      }
    }

    CreateSubreddit(user_id, name, description, reply) -> {
      let result = create_subreddit(state, user_id, name, description)
      case result {
        Ok(#(subreddit, new_state)) -> {
          process.send(reply, Ok(subreddit))
          actor.continue(new_state)
        }
        Error(err) -> {
          process.send(reply, Error(err))
          actor.continue(state)
        }
      }
    }

    JoinSubreddit(user_id, subreddit_id, reply) -> {
      let result = join_subreddit(state, user_id, subreddit_id)
      case result {
        Ok(new_state) -> {
          process.send(reply, Ok("Successfully joined subreddit"))
          actor.continue(new_state)
        }
        Error(err) -> {
          process.send(reply, Error(err))
          actor.continue(state)
        }
      }
    }

    LeaveSubreddit(user_id, subreddit_id, reply) -> {
      let result = leave_subreddit(state, user_id, subreddit_id)
      case result {
        Ok(new_state) -> {
          process.send(reply, Ok("Successfully left subreddit"))
          actor.continue(new_state)
        }
        Error(err) -> {
          process.send(reply, Error(err))
          actor.continue(state)
        }
      }
    }

    CreatePost(user_id, subreddit_id, title, content, is_repost, reply) -> {
      let result =
        create_post(state, user_id, subreddit_id, title, content, is_repost)
      case result {
        Ok(#(post, new_state)) -> {
          process.send(reply, Ok(post))
          // Notify subscribers
          notify_subscribers(new_state, subreddit_id, post)
          actor.continue(new_state)
        }
        Error(err) -> {
          process.send(reply, Error(err))
          actor.continue(state)
        }
      }
    }

    CreateComment(user_id, post_id, content, parent_comment_id, reply) -> {
      let result =
        create_comment(state, user_id, post_id, content, parent_comment_id)
      case result {
        Ok(#(comment, new_state)) -> {
          process.send(reply, Ok(comment))
          actor.continue(new_state)
        }
        Error(err) -> {
          process.send(reply, Error(err))
          actor.continue(state)
        }
      }
    }

    VotePost(user_id, post_id, is_upvote, reply) -> {
      let result = vote_post(state, user_id, post_id, is_upvote)
      case result {
        Ok(new_state) -> {
          process.send(reply, Ok("Vote recorded"))
          actor.continue(new_state)
        }
        Error(err) -> {
          process.send(reply, Error(err))
          actor.continue(state)
        }
      }
    }

    VoteComment(user_id, comment_id, is_upvote, reply) -> {
      let result = vote_comment(state, user_id, comment_id, is_upvote)
      case result {
        Ok(new_state) -> {
          process.send(reply, Ok("Vote recorded"))
          actor.continue(new_state)
        }
        Error(err) -> {
          process.send(reply, Error(err))
          actor.continue(state)
        }
      }
    }

    GetFeed(user_id, reply) -> {
      let result = get_feed(state, user_id)
      process.send(reply, result)
      actor.continue(state)
    }

    SendDirectMessage(from_user_id, to_user_id, content, parent_id, reply) -> {
      let result =
        send_direct_message(state, from_user_id, to_user_id, content, parent_id)
      case result {
        Ok(#(message, new_state)) -> {
          process.send(reply, Ok(message))
          // Notify recipient if online
          notify_direct_message(new_state, message)
          actor.continue(new_state)
        }
        Error(err) -> {
          process.send(reply, Error(err))
          actor.continue(state)
        }
      }
    }

    GetDirectMessages(user_id, reply) -> {
      let result = get_direct_messages(state, user_id)
      process.send(reply, result)
      actor.continue(state)
    }

    SetUserOnline(user_id, user_actor) -> {
      let new_state = set_user_online(state, user_id, user_actor)
      actor.continue(new_state)
    }

    SetUserOffline(user_id) -> {
      let new_state = set_user_offline(state, user_id)
      actor.continue(new_state)
    }

    GetStats(reply) -> {
      let stats = get_stats(state)
      process.send(reply, stats)
      actor.continue(state)
    }

    SearchUsers(query, reply) -> {
      let results = search_users(state, query)
      process.send(reply, results)
      actor.continue(state)
    }

    SearchSubreddits(query, reply) -> {
      let results = search_subreddits(state, query)
      process.send(reply, results)
      actor.continue(state)
    }

    GetUserKarma(user_id, reply) -> {
      let result = get_user_karma(state, user_id)
      process.send(reply, result)
      actor.continue(state)
    }

    GetSubredditMemberCount(subreddit_id, reply) -> {
      let result = get_subreddit_member_count(state, subreddit_id)
      process.send(reply, result)
      actor.continue(state)
    }

    Shutdown -> {
      io.println("Engine shutting down...")
      actor.stop()
    }
  }
}

// Helper functions

fn register_user(
  state: EngineState,
  username: String,
) -> Result(#(User, EngineState), String) {
  let user_id = generate_user_id(username)

  case dict.get(state.users, user_id) {
    Ok(_) -> Error("Username already exists")
    Error(_) -> {
      let user =
        User(
          id: user_id,
          username: username,
          karma: 0,
          subscribed_subreddits: [],
          is_online: False,
        )

      let new_state =
        EngineState(..state, users: dict.insert(state.users, user_id, user))

      Ok(#(user, new_state))
    }
  }
}

fn create_subreddit(
  state: EngineState,
  user_id: String,
  name: String,
  description: String,
) -> Result(#(Subreddit, EngineState), String) {
  case dict.get(state.users, user_id) {
    Error(_) -> Error("User not found")
    Ok(_) -> {
      let subreddit_id = generate_subreddit_id(name)

      case dict.get(state.subreddits, subreddit_id) {
        Ok(_) -> Error("Subreddit already exists")
        Error(_) -> {
          let timestamp = get_timestamp()
          let subreddit =
            Subreddit(
              id: subreddit_id,
              name: name,
              description: description,
              members: [user_id],
              posts: [],
              created_by: user_id,
              created_at: timestamp,
            )

          let new_state =
            EngineState(
              ..state,
              subreddits: dict.insert(state.subreddits, subreddit_id, subreddit),
            )

          // Auto-subscribe creator
          let updated_state = case
            join_subreddit(new_state, user_id, subreddit_id)
          {
            Ok(s) -> s
            Error(_) -> new_state
          }

          Ok(#(subreddit, updated_state))
        }
      }
    }
  }
}

fn join_subreddit(
  state: EngineState,
  user_id: String,
  subreddit_id: String,
) -> Result(EngineState, String) {
  case
    dict.get(state.users, user_id),
    dict.get(state.subreddits, subreddit_id)
  {
    Ok(user), Ok(subreddit) -> {
      // Check if already a member
      case list.contains(subreddit.members, user_id) {
        True -> Error("Already a member")
        False -> {
          // Add user to subreddit members
          let updated_subreddit =
            Subreddit(..subreddit, members: [user_id, ..subreddit.members])

          // Add subreddit to user's subscriptions
          let updated_user =
            User(..user, subscribed_subreddits: [
              subreddit_id,
              ..user.subscribed_subreddits
            ])

          let new_state =
            EngineState(
              ..state,
              users: dict.insert(state.users, user_id, updated_user),
              subreddits: dict.insert(
                state.subreddits,
                subreddit_id,
                updated_subreddit,
              ),
            )

          Ok(new_state)
        }
      }
    }
    Error(_), _ -> Error("User not found")
    _, Error(_) -> Error("Subreddit not found")
  }
}

fn leave_subreddit(
  state: EngineState,
  user_id: String,
  subreddit_id: String,
) -> Result(EngineState, String) {
  case
    dict.get(state.users, user_id),
    dict.get(state.subreddits, subreddit_id)
  {
    Ok(user), Ok(subreddit) -> {
      // Remove user from subreddit members
      let updated_subreddit =
        Subreddit(
          ..subreddit,
          members: list.filter(subreddit.members, fn(id) { id != user_id }),
        )

      // Remove subreddit from user's subscriptions
      let updated_user =
        User(
          ..user,
          subscribed_subreddits: list.filter(user.subscribed_subreddits, fn(id) {
            id != subreddit_id
          }),
        )

      let new_state =
        EngineState(
          ..state,
          users: dict.insert(state.users, user_id, updated_user),
          subreddits: dict.insert(
            state.subreddits,
            subreddit_id,
            updated_subreddit,
          ),
        )

      Ok(new_state)
    }
    Error(_), _ -> Error("User not found")
    _, Error(_) -> Error("Subreddit not found")
  }
}

fn create_post(
  state: EngineState,
  user_id: String,
  subreddit_id: String,
  title: String,
  content: String,
  is_repost: Bool,
) -> Result(#(Post, EngineState), String) {
  case
    dict.get(state.users, user_id),
    dict.get(state.subreddits, subreddit_id)
  {
    Ok(_), Ok(subreddit) -> {
      let post_id = "post_" <> int.to_string(state.next_post_id)
      let timestamp = get_timestamp()

      let post =
        types.Post(
          id: post_id,
          subreddit_id: subreddit_id,
          author_id: user_id,
          title: title,
          content: content,
          upvotes: 0,
          downvotes: 0,
          comments: [],
          created_at: timestamp,
          is_repost: is_repost,
        )

      let updated_subreddit =
        Subreddit(..subreddit, posts: [post_id, ..subreddit.posts])

      let new_state =
        EngineState(
          ..state,
          posts: dict.insert(state.posts, post_id, post),
          subreddits: dict.insert(
            state.subreddits,
            subreddit_id,
            updated_subreddit,
          ),
          next_post_id: state.next_post_id + 1,
        )

      Ok(#(post, new_state))
    }
    Error(_), _ -> Error("User not found")
    _, Error(_) -> Error("Subreddit not found")
  }
}

fn create_comment(
  state: EngineState,
  user_id: String,
  post_id: String,
  content: String,
  parent_comment_id: Option(String),
) -> Result(#(Comment, EngineState), String) {
  case dict.get(state.users, user_id), dict.get(state.posts, post_id) {
    Ok(_), Ok(post) -> {
      let comment_id = "comment_" <> int.to_string(state.next_comment_id)
      let timestamp = get_timestamp()

      let comment =
        Comment(
          id: comment_id,
          post_id: post_id,
          author_id: user_id,
          content: content,
          parent_id: parent_comment_id,
          upvotes: 0,
          downvotes: 0,
          replies: [],
          created_at: timestamp,
        )

      let updated_post =
        types.Post(..post, comments: [comment_id, ..post.comments])

      // If it's a reply, update parent comment
      let new_state = case parent_comment_id {
        Some(parent_id) -> {
          case dict.get(state.comments, parent_id) {
            Ok(parent_comment) -> {
              let updated_parent =
                Comment(..parent_comment, replies: [
                  comment_id,
                  ..parent_comment.replies
                ])
              EngineState(
                ..state,
                comments: dict.insert(
                  dict.insert(state.comments, comment_id, comment),
                  parent_id,
                  updated_parent,
                ),
                posts: dict.insert(state.posts, post_id, updated_post),
                next_comment_id: state.next_comment_id + 1,
              )
            }
            Error(_) ->
              EngineState(
                ..state,
                comments: dict.insert(state.comments, comment_id, comment),
                posts: dict.insert(state.posts, post_id, updated_post),
                next_comment_id: state.next_comment_id + 1,
              )
          }
        }
        None ->
          EngineState(
            ..state,
            comments: dict.insert(state.comments, comment_id, comment),
            posts: dict.insert(state.posts, post_id, updated_post),
            next_comment_id: state.next_comment_id + 1,
          )
      }

      Ok(#(comment, new_state))
    }
    Error(_), _ -> Error("User not found")
    _, Error(_) -> Error("Post not found")
  }
}

fn vote_post(
  state: EngineState,
  user_id: String,
  post_id: String,
  is_upvote: Bool,
) -> Result(EngineState, String) {
  case dict.get(state.users, user_id), dict.get(state.posts, post_id) {
    Ok(_), Ok(post) -> {
      let updated_post = case is_upvote {
        True -> types.Post(..post, upvotes: post.upvotes + 1)
        False -> types.Post(..post, downvotes: post.downvotes + 1)
      }

      // Update karma for post author
      let new_state = case dict.get(state.users, post.author_id) {
        Ok(author) -> {
          let karma_change = case is_upvote {
            True -> 1
            False -> -1
          }
          let updated_author =
            User(..author, karma: author.karma + karma_change)
          EngineState(
            ..state,
            users: dict.insert(state.users, post.author_id, updated_author),
            posts: dict.insert(state.posts, post_id, updated_post),
          )
        }
        Error(_) ->
          EngineState(
            ..state,
            posts: dict.insert(state.posts, post_id, updated_post),
          )
      }

      Ok(new_state)
    }
    Error(_), _ -> Error("User not found")
    _, Error(_) -> Error("Post not found")
  }
}

fn vote_comment(
  state: EngineState,
  user_id: String,
  comment_id: String,
  is_upvote: Bool,
) -> Result(EngineState, String) {
  case dict.get(state.users, user_id), dict.get(state.comments, comment_id) {
    Ok(_), Ok(comment) -> {
      let updated_comment = case is_upvote {
        True -> Comment(..comment, upvotes: comment.upvotes + 1)
        False -> Comment(..comment, downvotes: comment.downvotes + 1)
      }

      // Update karma for comment author
      let new_state = case dict.get(state.users, comment.author_id) {
        Ok(author) -> {
          let karma_change = case is_upvote {
            True -> 1
            False -> -1
          }
          let updated_author =
            User(..author, karma: author.karma + karma_change)
          EngineState(
            ..state,
            users: dict.insert(state.users, comment.author_id, updated_author),
            comments: dict.insert(state.comments, comment_id, updated_comment),
          )
        }
        Error(_) ->
          EngineState(
            ..state,
            comments: dict.insert(state.comments, comment_id, updated_comment),
          )
      }

      Ok(new_state)
    }
    Error(_), _ -> Error("User not found")
    _, Error(_) -> Error("Comment not found")
  }
}

fn get_feed(state: EngineState, user_id: String) -> Result(List(Post), String) {
  case dict.get(state.users, user_id) {
    Error(_) -> Error("User not found")
    Ok(user) -> {
      // Get posts from all subscribed subreddits
      let posts =
        list.flat_map(user.subscribed_subreddits, fn(subreddit_id) {
          case dict.get(state.subreddits, subreddit_id) {
            Ok(subreddit) ->
              list.filter_map(subreddit.posts, fn(post_id) {
                dict.get(state.posts, post_id)
              })
            Error(_) -> []
          }
        })

      // Sort by created_at (newest first)
      let sorted_posts =
        list.sort(posts, fn(a, b) { int.compare(b.created_at, a.created_at) })

      Ok(sorted_posts)
    }
  }
}

fn send_direct_message(
  state: EngineState,
  from_user_id: String,
  to_user_id: String,
  content: String,
  parent_id: Option(String),
) -> Result(#(DirectMessage, EngineState), String) {
  case dict.get(state.users, from_user_id), dict.get(state.users, to_user_id) {
    Ok(_), Ok(_) -> {
      let message_id = "msg_" <> int.to_string(state.next_message_id)
      let timestamp = get_timestamp()

      let message =
        DirectMessage(
          id: message_id,
          from_user_id: from_user_id,
          to_user_id: to_user_id,
          content: content,
          parent_message_id: parent_id,
          created_at: timestamp,
          is_read: False,
        )

      let new_state =
        EngineState(
          ..state,
          direct_messages: dict.insert(
            state.direct_messages,
            message_id,
            message,
          ),
          next_message_id: state.next_message_id + 1,
        )

      Ok(#(message, new_state))
    }
    Error(_), _ -> Error("Sender not found")
    _, Error(_) -> Error("Recipient not found")
  }
}

fn get_direct_messages(
  state: EngineState,
  user_id: String,
) -> Result(List(DirectMessage), String) {
  case dict.get(state.users, user_id) {
    Error(_) -> Error("User not found")
    Ok(_) -> {
      let messages =
        dict.values(state.direct_messages)
        |> list.filter(fn(msg) { msg.to_user_id == user_id })
        |> list.sort(fn(a, b) { int.compare(b.created_at, a.created_at) })

      Ok(messages)
    }
  }
}

fn set_user_online(
  state: EngineState,
  user_id: String,
  user_actor: Subject(UserMessage),
) -> EngineState {
  let new_state =
    EngineState(
      ..state,
      user_actors: dict.insert(state.user_actors, user_id, user_actor),
    )

  case dict.get(state.users, user_id) {
    Ok(user) -> {
      let updated_user = User(..user, is_online: True)
      EngineState(
        ..new_state,
        users: dict.insert(new_state.users, user_id, updated_user),
      )
    }
    Error(_) -> new_state
  }
}

fn set_user_offline(state: EngineState, user_id: String) -> EngineState {
  let new_state =
    EngineState(..state, user_actors: dict.delete(state.user_actors, user_id))

  case dict.get(state.users, user_id) {
    Ok(user) -> {
      let updated_user = User(..user, is_online: False)
      EngineState(
        ..new_state,
        users: dict.insert(new_state.users, user_id, updated_user),
      )
    }
    Error(_) -> new_state
  }
}

fn get_stats(state: EngineState) -> EngineStats {
  let online_count =
    dict.values(state.users)
    |> list.filter(fn(user) { user.is_online })
    |> list.length

  types.EngineStats(
    total_users: dict.size(state.users),
    online_users: online_count,
    total_subreddits: dict.size(state.subreddits),
    total_posts: dict.size(state.posts),
    total_comments: dict.size(state.comments),
    total_messages: dict.size(state.direct_messages),
  )
}

fn notify_subscribers(
  state: EngineState,
  subreddit_id: String,
  post: Post,
) -> Nil {
  case dict.get(state.subreddits, subreddit_id) {
    Ok(subreddit) -> {
      list.each(subreddit.members, fn(member_id) {
        case dict.get(state.user_actors, member_id) {
          Ok(actor) -> process.send(actor, types.NewPostNotification(post))
          Error(_) -> Nil
        }
      })
    }
    Error(_) -> Nil
  }
}

fn search_users(state: EngineState, query: String) -> List(String) {
  let lowercase_query = string.lowercase(query)
  dict.filter(state.users, fn(user_id, _user) {
    string.contains(string.lowercase(user_id), lowercase_query)
  })
  |> dict.keys
}

fn search_subreddits(
  state: EngineState,
  query: String,
) -> List(#(String, String)) {
  let lowercase_query = string.lowercase(query)
  dict.filter(state.subreddits, fn(subreddit_id, subreddit) {
    string.contains(string.lowercase(subreddit_id), lowercase_query)
    || string.contains(string.lowercase(subreddit.name), lowercase_query)
    || string.contains(string.lowercase(subreddit.description), lowercase_query)
  })
  |> dict.to_list
  |> list.map(fn(entry) {
    let #(id, subreddit) = entry
    #(id, subreddit.description)
  })
}

fn get_user_karma(state: EngineState, user_id: String) -> Result(Int, String) {
  case dict.get(state.users, user_id) {
    Ok(user) -> Ok(user.karma)
    Error(_) -> Error("User not found")
  }
}

fn get_subreddit_member_count(
  state: EngineState,
  subreddit_id: String,
) -> Result(Int, String) {
  case dict.get(state.subreddits, subreddit_id) {
    Ok(subreddit) -> Ok(list.length(subreddit.members))
    Error(_) -> Error("Subreddit not found")
  }
}

fn notify_direct_message(state: EngineState, message: DirectMessage) -> Nil {
  case dict.get(state.user_actors, message.to_user_id) {
    Ok(actor) -> process.send(actor, types.NewDirectMessage(message))
    Error(_) -> Nil
  }
}

// Utility functions
fn generate_user_id(username: String) -> String {
  "user_" <> string.lowercase(username)
}

fn generate_subreddit_id(name: String) -> String {
  "r_" <> string.lowercase(name)
}

fn get_timestamp() -> Int {
  // Use system time from simulator
  erlang_system_time()
}

@external(erlang, "erlang", "system_time")
fn erlang_system_time() -> Int
