use "collections"
use "time"

actor RedditEngine
  let accounts: Map[String, Account] = Map[String, Account]
  let subreddits: Map[String, SubReddit] = Map[String, SubReddit]

  new create() =>
    None

  be register_account(username: String val, password: String val) =>
    if not accounts.contains(username) then
      let account = Account(username, password)
      accounts(username) = account
    end

  be create_subreddit(name: String val) =>
    if not subreddits.contains(name) then
      let subreddit = SubReddit(name)
      subreddits(name) = subreddit
    end

  be join_subreddit(username: String val, subreddit_name: String val) =>
    try
      let account = accounts(username)?
      let subreddit = subreddits(subreddit_name)?
      if not subreddit.members.contains(account) then
        subreddit.members.push(account)
        account.subscriptions.push(subreddit)
      end
    end

  be leave_subreddit(username: String val, subreddit_name: String val) =>
    try
      let account = accounts(username)?
      let subreddit = subreddits(subreddit_name)?
      let index = subreddit.members.find(account)
      if index != -1 then 
        subreddit.members.remove(index, 1)
      end
      let sub_index = account.subscriptions.find(subreddit)
      if sub_index != -1 then 
        account.subscriptions.remove(sub_index, 1)
      end
    end

  be post_in_subreddit(username: String val, subreddit_name: String val, content: String val) =>
    try
      let account = accounts(username)?
      let subreddit = subreddits(subreddit_name)?
      let post = Post(account, content)
      subreddit.posts.push(post)
    end

  be comment_on_post(username: String val, subreddit_name: String val, post_index: USize, content: String val) =>
    try
      let account = accounts(username)?
      let subreddit = subreddits(subreddit_name)?
      let post = subreddit.posts(post_index)?
      let comment = Comment(account, content)
      post.comments.push(comment)
    end

  be upvote_post(username: String val, subreddit_name: String val, post_index: USize) =>
    try
      let subreddit = subreddits(subreddit_name)?
      let post = subreddit.posts(post_index)?
      post.upvotes = post.upvotes + 1
      post.author.karma = post.author.karma + 1
    end

  be downvote_post(username: String val, subreddit_name: String val, post_index: USize) =>
    try
      let subreddit = subreddits(subreddit_name)?
      let post = subreddit.posts(post_index)?
      post.downvotes = post.downvotes + 1
      post.author.karma = post.author.karma - 1
    end

  fun get_feed(username: String val): Array[Post] =>
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

  be send_direct_message(sender: String val, receiver: String val, content: String val) =>
    try
      let sender_account = accounts(sender)?
      let receiver_account = accounts(receiver)?
      let message = Message(sender_account, receiver_account, content)
      receiver_account.messages.push(message)
    end

  fun get_direct_messages(username: String val): Array[Message] =>
    try
      let messages = Array[Message]
      for message in accounts(username)?.messages.values() do
        messages.push(message)
      end
      messages
    else
      Array[Message]
    end