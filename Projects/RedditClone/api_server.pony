use "net"
use "json"
use "http_server"

actor ApiServer
  let _env: Env
  let _engine: RedditEngine tag
  let _server: HTTPServer

  new create(env: Env, engine: RedditEngine tag, host: String, port: String) =>
    _env = env
    _engine = engine
    _server = HTTPServer(env.root as AmbientAuth,
      recover
        let config = ServerConfig(host, port)
        config.handler(ApiHandler(_engine))
        config
      end)

  be run() =>
    _server.listen()

class ApiHandler is HTTPHandler
  let _engine: RedditEngine tag

  new create(engine: RedditEngine tag) =>
    _engine = engine

  fun ref apply(request: Payload val): Payload iso^ =>
    match (request.method, request.url.path)
    | ("POST", "/register") => handle_register(request)
    | ("POST", "/create_subreddit") => handle_create_subreddit(request)
    | ("POST", "/join_subreddit") => handle_join_subreddit(request)
    | ("POST", "/post") => handle_post(request)
    | ("POST", "/comment") => handle_comment(request)
    | ("POST", "/upvote") => handle_upvote(request)
    | ("POST", "/downvote") => handle_downvote(request)
    | ("GET", "/feed") => handle_get_feed(request)
    | ("GET", "/messages") => handle_get_messages(request)
    else
      Payload.response(404, "Not found")
    end

  fun handle_register(request: Payload val): Payload iso^ =>
    try
      let json = JsonDoc.from_string(request.body)?
      let username = json.data.as_object()?.get_string("username")?
      let password = json.data.as_object()?.get_string("password")?
      _engine.register_account(username, password)
      Payload.response(200, "Account registered")
    else
      Payload.response(400, "Invalid request")
    end

  fun handle_create_subreddit(request: Payload val): Payload iso^ =>
    try
      let json = JsonDoc.from_string(request.body)?
      let name = json.data.as_object()?.get_string("name")?
      _engine.create_subreddit(name)
      Payload.response(200, "Subreddit created")
    else
      Payload.response(400, "Invalid request")
    end

  fun handle_join_subreddit(request: Payload val): Payload iso^ =>
    try
      let json = JsonDoc.from_string(request.body)?
      let username = json.data.as_object()?.get_string("username")?
      let subreddit_name = json.data.as_object()?.get_string("subreddit_name")?
      _engine.join_subreddit(username, subreddit_name)
      Payload.response(200, "Joined subreddit")
    else
      Payload.response(400, "Invalid request")
    end

  fun handle_post(request: Payload val): Payload iso^ =>
    try
      let json = JsonDoc.from_string(request.body)?
      let username = json.data.as_object()?.get_string("username")?
      let subreddit_name = json.data.as_object()?.get_string("subreddit_name")?
      let content = json.data.as_object()?.get_string("content")?
      _engine.post_in_subreddit(username, subreddit_name, content)
      Payload.response(200, "Post created")
    else
      Payload.response(400, "Invalid request")
    end

  fun handle_comment(request: Payload val): Payload iso^ =>
    try
      let json = JsonDoc.from_string(request.body)?
      let username = json.data.as_object()?.get_string("username")?
      let subreddit_name = json.data.as_object()?.get_string("subreddit_name")?
      let post_index = json.data.as_object()?.get_u64("post_index")?.usize()?
      let content = json.data.as_object()?.get_string("content")?
      _engine.comment_on_post(username, subreddit_name, post_index, content)
      Payload.response(200, "Comment added")
    else
      Payload.response(400, "Invalid request")
    end

  fun handle_upvote(request: Payload val): Payload iso^ =>
    try
      let json = JsonDoc.from_string(request.body)?
      let username = json.data.as_object()?.get_string("username")?
      let subreddit_name = json.data.as_object()?.get_string("subreddit_name")?
      let post_index = json.data.as_object()?.get_u64("post_index")?.usize()?
      _engine.upvote_post(username, subreddit_name, post_index)
      Payload.response(200, "Post upvoted")
    else
      Payload.response(400, "Invalid request")
    end

  fun handle_downvote(request: Payload val): Payload iso^ =>
    try
      let json = JsonDoc.from_string(request.body)?
      let username = json.data.as_object()?.get_string("username")?
      let subreddit_name = json.data.as_object()?.get_string("subreddit_name")?
      let post_index = json.data.as_object()?.get_u64("post_index")?.usize()?
      _engine.downvote_post(username, subreddit_name, post_index)
      Payload.response(200, "Post downvoted")
    else
      Payload.response(400, "Invalid request")
    end

  fun handle_get_feed(request: Payload val): Payload iso^ =>
    try
      let username = request.url.query.get_or_else("username", "")?
      let feed = _engine.get_feed(username)
      let json = JsonArray
      for post in feed.values() do
        let post_json = JsonObject
        post_json.update("author", post.author.username)
        post_json.update("content", post.content)
        post_json.update("timestamp", post.timestamp.string())
        json.push(post_json)
      end
      Payload.response(200, json.string())
    else
      Payload.response(400, "Invalid request")
    end

  fun handle_get_messages(request: Payload val): Payload iso^ =>
    try
      let username = request.url.query.get_or_else("username", "")?
      let messages = _engine.get_direct_messages(username)
      let json = JsonArray
      for message in messages.values() do
        let message_json = JsonObject
        message_json.update("sender", message.sender.username)
        message_json.update("content", message.content)
        message_json.update("timestamp", message.timestamp.string())
        json.push(message_json)
      end
      Payload.response(200, json.string())
    else
      Payload.response(400, "Invalid request")
    end

