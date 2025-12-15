// JSON encoding for Reddit Clone data types  
import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}
import types.{
  type Comment, type DirectMessage, type EngineStats, type Post, type Subreddit,
  type User,
}

// ========== User JSON ==========

pub fn user_to_json(user: User) -> Json {
  json.object([
    #("id", json.string(user.id)),
    #("username", json.string(user.username)),
    #("karma", json.int(user.karma)),
    #(
      "subscribed_subreddits",
      json.array(user.subscribed_subreddits, json.string),
    ),
    #("is_online", json.bool(user.is_online)),
  ])
}

// ========== Subreddit JSON ==========

pub fn subreddit_to_json(subreddit: Subreddit) -> Json {
  json.object([
    #("id", json.string(subreddit.id)),
    #("name", json.string(subreddit.name)),
    #("description", json.string(subreddit.description)),
    #("members", json.array(subreddit.members, json.string)),
    #("posts", json.array(subreddit.posts, json.string)),
    #("created_by", json.string(subreddit.created_by)),
    #("created_at", json.int(subreddit.created_at)),
  ])
}

// ========== Post JSON ==========

pub fn post_to_json(post: Post) -> Json {
  json.object([
    #("id", json.string(post.id)),
    #("subreddit_id", json.string(post.subreddit_id)),
    #("author_id", json.string(post.author_id)),
    #("title", json.string(post.title)),
    #("content", json.string(post.content)),
    #("upvotes", json.int(post.upvotes)),
    #("downvotes", json.int(post.downvotes)),
    #("comments", json.array(post.comments, json.string)),
    #("created_at", json.int(post.created_at)),
    #("is_repost", json.bool(post.is_repost)),
  ])
}

// ========== Comment JSON ==========

fn option_string_to_json(opt: Option(String)) -> Json {
  case opt {
    Some(value) -> json.string(value)
    None -> json.null()
  }
}

pub fn comment_to_json(comment: Comment) -> Json {
  json.object([
    #("id", json.string(comment.id)),
    #("post_id", json.string(comment.post_id)),
    #("author_id", json.string(comment.author_id)),
    #("content", json.string(comment.content)),
    #("parent_id", option_string_to_json(comment.parent_id)),
    #("upvotes", json.int(comment.upvotes)),
    #("downvotes", json.int(comment.downvotes)),
    #("replies", json.array(comment.replies, json.string)),
    #("created_at", json.int(comment.created_at)),
  ])
}

// ========== DirectMessage JSON ==========

pub fn message_to_json(message: DirectMessage) -> Json {
  json.object([
    #("id", json.string(message.id)),
    #("from_user_id", json.string(message.from_user_id)),
    #("to_user_id", json.string(message.to_user_id)),
    #("content", json.string(message.content)),
    #("parent_message_id", option_string_to_json(message.parent_message_id)),
    #("created_at", json.int(message.created_at)),
    #("is_read", json.bool(message.is_read)),
  ])
}

// ========== EngineStats JSON ==========

pub fn stats_to_json(stats: EngineStats) -> Json {
  json.object([
    #("total_users", json.int(stats.total_users)),
    #("online_users", json.int(stats.online_users)),
    #("total_subreddits", json.int(stats.total_subreddits)),
    #("total_posts", json.int(stats.total_posts)),
    #("total_comments", json.int(stats.total_comments)),
    #("total_messages", json.int(stats.total_messages)),
  ])
}

// ========== Helper functions for API responses ==========

pub fn success_response(data: Json) -> Json {
  json.object([#("success", json.bool(True)), #("data", data)])
}

pub fn error_response(message: String) -> Json {
  json.object([
    #("success", json.bool(False)),
    #("error", json.string(message)),
  ])
}

pub fn list_to_json(items: List(a), encoder: fn(a) -> Json) -> Json {
  json.array(items, encoder)
}
