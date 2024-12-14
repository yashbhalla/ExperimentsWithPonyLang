use "net"
use "json"
use "time"

actor Main
  new create(env: Env) =>
    let engine = RedditEngine
    let api_server = ApiServer(env, engine, "localhost", "8080")
    api_server.run()

    let client = ApiClient(env, "localhost", "8080")
    
    // Register accounts
    client.register_account("user1", "password1")
    client.register_account("user2", "password2")
    
    // Create subreddits
    client.create_subreddit("funny")
    client.create_subreddit("news")
    
    // Join subreddits
    client.join_subreddit("user1", "funny")
    client.join_subreddit("user2", "news")
    
    // Post in subreddits
    client.post_in_subreddit("user1", "funny", "This is a funny post")
    client.post_in_subreddit("user2", "news", "Breaking news!")
    
    // Comment on posts
    client.comment_on_post("user2", "funny", 0, "Nice post!")
    
    // Upvote and downvote posts
    client.upvote_post("user1", "funny", 0)
    client.downvote_post("user2", "news", 0)
    
    // Get feed for a user
    client.get_feed("user1")
    
    // Send direct messages
    client.send_direct_message("user1", "user2", "Hello!")
    
    // Get direct messages
    client.get_direct_messages("user2")

    // Run simulation
    let simulator = Simulator(env, engine, 1000, 50, 60)
    simulator.run()