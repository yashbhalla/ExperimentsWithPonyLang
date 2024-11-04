use "collections"
use "time"

actor RedditEngine
  let accounts: Map[String, Account] = Map[String, Account]
  let subreddits: Map[String, SubReddit] = Map[String, SubReddit]

  new create() =>
    None

  fun ref register_account(username: String, password: String): Bool =>
    if not accounts.contains(username) then
      let account = Account(username, password)
      accounts(username) = account
      true
    else
      false
    end

  fun ref create_subreddit(name: String): Bool =>
    if not subreddits.contains(name) then
      let subreddit = SubReddit(name)
      subreddits(name) = subreddit
      true
    else
      false
    end

  fun ref join_subreddit(username: String, subreddit_name: String): Bool =>
    try
      let account = accounts(username)?
      let subreddit = subreddits(subreddit_name)?
      if not subreddit.members.contains(account) then
        subreddit.members.set(account)
        account.subscriptions.set(subreddit)
        true
      else
        false
      end
    else
      false
    end

  fun ref leave_subreddit(username: String, subreddit_name: String): Bool =>
    try
      let account = accounts(username)?
      let subreddit = subreddits(subreddit_name)?
      if subreddit.members.contains(account) then
        subreddit.members.unset(account)
        account.subscriptions.unset(subreddit)
        true
      else
        false
      end
    else
      false
    end

  fun ref post_in_subreddit(username: String, subreddit_name: String, content: String): Bool =>
    try
      let account = accounts(username)?
      let subreddit = subreddits(subreddit_name)?
      let post = Post(account, content)
      subreddit.posts.push(post)
      true
    else
      false
    end

  fun ref comment_on_post(username: String, subreddit_name: String, post_index: USize, content: String): Bool =>
    try
      let account = accounts(username)?
      let subreddit = subreddits(subreddit_name)?
      let post = subreddit.posts(post_index)?
      let comment = Comment(account, content)
      post.comments.push(comment)
      true
    else
      false
    end

  fun ref upvote_post(username: String, subreddit_name: String, post_index: USize): Bool =>
    try
      let subreddit = subreddits(subreddit_name)?
      let post = subreddit.posts(post_index)?
      post.upvotes = post.upvotes + 1
      post.author.karma = post.author.karma + 1
      true
    else
      false
    end

  fun ref downvote_post(username: String, subreddit_name: String, post_index: USize): Bool =>
    try
      let subreddit = subreddits(subreddit_name)?
      let post = subreddit.posts(post_index)?
      post.downvotes = post.downvotes + 1
      post.author.karma = post.author.karma - 1
      true
    else
      false
    end

  fun ref get_feed(username: String): Array[Post] =>
    let feed = Array[Post]
    try
      let account = accounts(username)?
      for subreddit in account.subscriptions.values() do
        for post in subreddit.posts.values() do
          feed.push(post)
        end
      end
    end
    feed

  fun ref send_direct_message(sender: String, receiver: String, content: String): Bool =>
    try
      let sender_account = accounts(sender)?
      let receiver_account = accounts(receiver)?
      let message = Message(sender_account, receiver_account, content)
      receiver_account.messages.push(message)
      true
    else
      false
    end

  fun ref get_direct_messages(username: String): Array[Message] =>
    try
      accounts(username)?.messages.values()
    else
      Array[Message]
    end