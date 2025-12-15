import gleam/erlang/process.{type Subject}
import gleam/option.{None}
import gleam/otp/actor
import types.{type EngineMessage, type User, type UserMessage}

pub type UserActorState {
  UserActorState(
    user: User,
    engine: Subject(EngineMessage),
    is_active: Bool,
    pending_notifications: Int,
  )
}

pub fn start(
  user: User,
  engine: Subject(EngineMessage),
) -> Result(actor.Started(Subject(UserMessage)), actor.StartError) {
  let initial_state =
    UserActorState(
      user: user,
      engine: engine,
      is_active: True,
      pending_notifications: 0,
    )

  actor.new(initial_state)
  |> actor.on_message(handle_message)
  |> actor.start
  |> result_map_register(engine, user.id)
}

fn result_map_register(
  result: Result(actor.Started(Subject(UserMessage)), actor.StartError),
  engine: Subject(EngineMessage),
  user_id: String,
) -> Result(actor.Started(Subject(UserMessage)), actor.StartError) {
  case result {
    Ok(started) -> {
      process.send(engine, types.SetUserOnline(user_id, started.data))
      Ok(started)
    }
    Error(e) -> Error(e)
  }
}

fn handle_message(
  state: UserActorState,
  message: UserMessage,
) -> actor.Next(UserActorState, UserMessage) {
  case message {
    types.NewPostNotification(_post) -> {
      case state.is_active {
        True -> {
          // User is online, process notification silently
          actor.continue(state)
        }
        False -> {
          // User is offline, queue notification
          let new_state =
            UserActorState(
              ..state,
              pending_notifications: state.pending_notifications + 1,
            )
          actor.continue(new_state)
        }
      }
    }

    types.NewCommentNotification(_comment, _post) -> {
      case state.is_active {
        True -> {
          actor.continue(state)
        }
        False -> {
          let new_state =
            UserActorState(
              ..state,
              pending_notifications: state.pending_notifications + 1,
            )
          actor.continue(new_state)
        }
      }
    }

    types.NewDirectMessage(_dm) -> {
      case state.is_active {
        True -> {
          actor.continue(state)
        }
        False -> {
          let new_state =
            UserActorState(
              ..state,
              pending_notifications: state.pending_notifications + 1,
            )
          actor.continue(new_state)
        }
      }
    }

    types.PerformAction(action, reply) -> {
      case state.is_active {
        True -> {
          perform_action(state, action, reply)
          actor.continue(state)
        }
        False -> {
          process.send(reply, Error("User is offline"))
          actor.continue(state)
        }
      }
    }

    types.GoOffline -> {
      process.send(state.engine, types.SetUserOffline(state.user.id))
      let new_state = UserActorState(..state, is_active: False)
      actor.continue(new_state)
    }

    types.Terminate -> {
      process.send(state.engine, types.SetUserOffline(state.user.id))
      actor.stop()
    }
  }
}

fn perform_action(
  state: UserActorState,
  action: types.UserAction,
  reply: Subject(Result(String, String)),
) -> Nil {
  case action {
    types.PostAction(subreddit_id, title, content) -> {
      let response_subject = process.new_subject()
      process.send(
        state.engine,
        types.CreatePost(
          state.user.id,
          subreddit_id,
          title,
          content,
          False,
          response_subject,
        ),
      )

      // Wait for response with timeout
      case process.receive(response_subject, 5000) {
        Ok(result) -> {
          case result {
            Ok(_) -> process.send(reply, Ok("Post created successfully"))
            Error(err) -> process.send(reply, Error(err))
          }
        }
        Error(_) -> process.send(reply, Error("Timeout waiting for response"))
      }
    }

    types.CommentAction(post_id, content, parent_id) -> {
      let response_subject = process.new_subject()
      process.send(
        state.engine,
        types.CreateComment(
          state.user.id,
          post_id,
          content,
          parent_id,
          response_subject,
        ),
      )

      case process.receive(response_subject, 5000) {
        Ok(result) -> {
          case result {
            Ok(_) -> process.send(reply, Ok("Comment created successfully"))
            Error(err) -> process.send(reply, Error(err))
          }
        }
        Error(_) -> process.send(reply, Error("Timeout waiting for response"))
      }
    }

    types.VotePostAction(post_id, is_upvote) -> {
      let response_subject = process.new_subject()
      process.send(
        state.engine,
        types.VotePost(state.user.id, post_id, is_upvote, response_subject),
      )

      case process.receive(response_subject, 5000) {
        Ok(result) -> {
          case result {
            Ok(_) -> process.send(reply, Ok("Vote recorded"))
            Error(err) -> process.send(reply, Error(err))
          }
        }
        Error(_) -> process.send(reply, Error("Timeout waiting for response"))
      }
    }

    types.VoteCommentAction(comment_id, is_upvote) -> {
      let response_subject = process.new_subject()
      process.send(
        state.engine,
        types.VoteComment(
          state.user.id,
          comment_id,
          is_upvote,
          response_subject,
        ),
      )

      case process.receive(response_subject, 5000) {
        Ok(result) -> {
          case result {
            Ok(_) -> process.send(reply, Ok("Vote recorded"))
            Error(err) -> process.send(reply, Error(err))
          }
        }
        Error(_) -> process.send(reply, Error("Timeout waiting for response"))
      }
    }

    types.SendMessageAction(to_user_id, content) -> {
      let response_subject = process.new_subject()
      process.send(
        state.engine,
        types.SendDirectMessage(
          state.user.id,
          to_user_id,
          content,
          None,
          response_subject,
        ),
      )

      case process.receive(response_subject, 5000) {
        Ok(result) -> {
          case result {
            Ok(_) -> process.send(reply, Ok("Message sent"))
            Error(err) -> process.send(reply, Error(err))
          }
        }
        Error(_) -> process.send(reply, Error("Timeout waiting for response"))
      }
    }

    types.JoinSubredditAction(subreddit_id) -> {
      let response_subject = process.new_subject()
      process.send(
        state.engine,
        types.JoinSubreddit(state.user.id, subreddit_id, response_subject),
      )

      case process.receive(response_subject, 5000) {
        Ok(result) -> {
          case result {
            Ok(msg) -> process.send(reply, Ok(msg))
            Error(err) -> process.send(reply, Error(err))
          }
        }
        Error(_) -> process.send(reply, Error("Timeout waiting for response"))
      }
    }

    types.LeaveSubredditAction(subreddit_id) -> {
      let response_subject = process.new_subject()
      process.send(
        state.engine,
        types.LeaveSubreddit(state.user.id, subreddit_id, response_subject),
      )

      case process.receive(response_subject, 5000) {
        Ok(result) -> {
          case result {
            Ok(msg) -> process.send(reply, Ok(msg))
            Error(err) -> process.send(reply, Error(err))
          }
        }
        Error(_) -> process.send(reply, Error("Timeout waiting for response"))
      }
    }
  }
}
