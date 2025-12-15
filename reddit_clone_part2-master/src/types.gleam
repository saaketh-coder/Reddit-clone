import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/option.{type Option}

// Unique identifiers
pub type UserId =
  String

pub type SubredditId =
  String

pub type PostId =
  String

pub type CommentId =
  String

pub type MessageId =
  String

// Core data structures
pub type User {
  User(
    id: UserId,
    username: String,
    karma: Int,
    subscribed_subreddits: List(SubredditId),
    is_online: Bool,
  )
}

pub type Subreddit {
  Subreddit(
    id: SubredditId,
    name: String,
    description: String,
    members: List(UserId),
    posts: List(PostId),
    created_by: UserId,
    created_at: Int,
  )
}

pub type Post {
  Post(
    id: PostId,
    subreddit_id: SubredditId,
    author_id: UserId,
    title: String,
    content: String,
    upvotes: Int,
    downvotes: Int,
    comments: List(CommentId),
    created_at: Int,
    is_repost: Bool,
  )
}

pub type Comment {
  Comment(
    id: CommentId,
    post_id: PostId,
    author_id: UserId,
    content: String,
    parent_id: Option(CommentId),
    upvotes: Int,
    downvotes: Int,
    replies: List(CommentId),
    created_at: Int,
  )
}

pub type DirectMessage {
  DirectMessage(
    id: MessageId,
    from_user_id: UserId,
    to_user_id: UserId,
    content: String,
    parent_message_id: Option(MessageId),
    created_at: Int,
    is_read: Bool,
  )
}

// Engine state
pub type EngineState {
  EngineState(
    users: Dict(UserId, User),
    subreddits: Dict(SubredditId, Subreddit),
    posts: Dict(PostId, Post),
    comments: Dict(CommentId, Comment),
    direct_messages: Dict(MessageId, DirectMessage),
    user_actors: Dict(UserId, Subject(UserMessage)),
    next_post_id: Int,
    next_comment_id: Int,
    next_message_id: Int,
  )
}

// Messages for the Engine Actor
pub type EngineMessage {
  // User registration
  RegisterUser(username: String, reply: Subject(Result(User, String)))

  // Subreddit operations
  CreateSubreddit(
    user_id: UserId,
    name: String,
    description: String,
    reply: Subject(Result(Subreddit, String)),
  )
  JoinSubreddit(
    user_id: UserId,
    subreddit_id: SubredditId,
    reply: Subject(Result(String, String)),
  )
  LeaveSubreddit(
    user_id: UserId,
    subreddit_id: SubredditId,
    reply: Subject(Result(String, String)),
  )

  // Post operations
  CreatePost(
    user_id: UserId,
    subreddit_id: SubredditId,
    title: String,
    content: String,
    is_repost: Bool,
    reply: Subject(Result(Post, String)),
  )

  // Comment operations
  CreateComment(
    user_id: UserId,
    post_id: PostId,
    content: String,
    parent_comment_id: Option(CommentId),
    reply: Subject(Result(Comment, String)),
  )

  // Vote operations
  VotePost(
    user_id: UserId,
    post_id: PostId,
    is_upvote: Bool,
    reply: Subject(Result(String, String)),
  )
  VoteComment(
    user_id: UserId,
    comment_id: CommentId,
    is_upvote: Bool,
    reply: Subject(Result(String, String)),
  )

  // Feed operations
  GetFeed(user_id: UserId, reply: Subject(Result(List(Post), String)))

  // Direct message operations
  SendDirectMessage(
    from_user_id: UserId,
    to_user_id: UserId,
    content: String,
    parent_message_id: Option(MessageId),
    reply: Subject(Result(DirectMessage, String)),
  )
  GetDirectMessages(
    user_id: UserId,
    reply: Subject(Result(List(DirectMessage), String)),
  )

  // User connection status
  SetUserOnline(user_id: UserId, actor: Subject(UserMessage))
  SetUserOffline(user_id: UserId)

  // Statistics
  GetStats(reply: Subject(EngineStats))

  // Search operations
  SearchUsers(query: String, reply: Subject(List(String)))
  SearchSubreddits(query: String, reply: Subject(List(#(SubredditId, String))))

  // Additional queries
  GetUserKarma(user_id: UserId, reply: Subject(Result(Int, String)))
  GetSubredditMemberCount(
    subreddit_id: SubredditId,
    reply: Subject(Result(Int, String)),
  )

  // Shutdown
  Shutdown
}

// Messages for User Actor
pub type UserMessage {
  // Notifications
  NewPostNotification(post: Post)
  NewCommentNotification(comment: Comment, post: Post)
  NewDirectMessage(message: DirectMessage)

  // Requests
  PerformAction(action: UserAction, reply: Subject(Result(String, String)))

  // Control
  GoOffline
  Terminate
}

pub type UserAction {
  PostAction(subreddit_id: SubredditId, title: String, content: String)
  CommentAction(post_id: PostId, content: String, parent_id: Option(CommentId))
  VotePostAction(post_id: PostId, is_upvote: Bool)
  VoteCommentAction(comment_id: CommentId, is_upvote: Bool)
  SendMessageAction(to_user_id: UserId, content: String)
  JoinSubredditAction(subreddit_id: SubredditId)
  LeaveSubredditAction(subreddit_id: SubredditId)
}

// Statistics
pub type EngineStats {
  EngineStats(
    total_users: Int,
    online_users: Int,
    total_subreddits: Int,
    total_posts: Int,
    total_comments: Int,
    total_messages: Int,
  )
}

// Performance metrics
pub type PerformanceMetrics {
  PerformanceMetrics(
    total_operations: Int,
    successful_operations: Int,
    failed_operations: Int,
    start_time: Int,
    end_time: Int,
    operations_per_second: Float,
  )
}
