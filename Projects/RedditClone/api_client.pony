use "http"
use "json"

actor ApiClient
  let _env: Env
  let _http: HTTPClient

  new create(env: Env, host: String, port: String) =>
    _env = env
    _http = HTTPClient(env.root as AmbientAuth)

  be register_account(username: String, password: String) =>
    let url = URL.build("http://localhost:8080/register")?
    let body = JsonObject
    body.update("username", username)
    body.update("password", password)
    let req = Payload.request("POST", url)
    req.update("Content-Type", "application/json")
    req.update("body", body.string())
    _http(consume req, {(res: Payload val) =>
      _env.out.print("Response: " + res.status.string() + " " + res.body)
    })

  be create_subreddit(name: String) =>
    let url = URL.build("http://localhost:8080/create_subreddit")?
    let body = JsonObject
    body.update("name", name)
    let req = Payload.request("POST", url)
    req.update("Content-Type", "application/json")
    req.update("body", body.string())
    _http(consume req, {(res: Payload val) =>
      _env.out.print("Response: " + res.status.string() + " " + res.body)
    })

  be join_subreddit(username: String, subreddit_name: String) =>
    let url = URL.build("http://localhost:8080/join_subreddit")?
    let body = JsonObject
    body.update("username", username)
    body.update("subreddit_name", subreddit_name)
    let req = Payload.request("POST", url)
    req.update("Content-Type", "application/json")
    req.update("body", body.string())
    _http(consume req, {(res: Payload val) =>
      _env.out.print("Response: " + res.status.string() + " " + res.body)
    })

  be post_in_subreddit(username: String, subreddit_name: String, content: String) =>
    let url = URL.build("http://localhost:8080/post")?
    let body = JsonObject
    body.update("username", username)
    body.update("subreddit_name", subreddit_name)
    body.update("content", content)
    let req = Payload.request("POST", url)
    req.update("Content-Type", "application/json")
    req.update("body", body.string())
    _http(consume req, {(res: Payload val) =>
      _env.out.print("Response: " + res.status.string() + " " + res.body)
    })

  be comment_on_post(username: String, subreddit_name: String, post_index: USize, content: String) =>
    let url = URL.build("http://localhost:8080/comment")?
    let body = JsonObject
    body.update("username", username)
    body.update("subreddit_name", subreddit_name)
    body.update("post_index", post_index.string())
    body.update("content", content)
    let req = Payload.request("POST", url)
    req.update("Content-Type", "application/json")
    req.update("body", body.string())
    _http(consume req, {(res: Payload val) =>
      _env.out.print("Response: " + res.status.string() + " " + res.body)
    })

  be upvote_post(username: String, subreddit_name: String, post_index: USize) =>
    let url = URL.build("http://localhost:8080/upvote")?
    let body = JsonObject
    body.update("username", username)
    body.update("subreddit_name", subreddit_name)
    body.update("post_index", post_index.string())
    let req = Payload.request("POST", url)
    req.update("Content-Type", "application/json")
    req.update("body", body.string())
    _http(consume req, {(res: Payload val) =>
      _env.out.print("Response: " + res.status.string() + " " + res.body)
    })

  be get_feed(username: String) =>
    let url = URL.build("http://localhost:8080/feed?username=" + username)?
    let req = Payload.request("GET", url)
    _http(consume req, {(res: Payload val) =>
      _env.out.print("Response: " + res.status.string() + " " + res.body)
    })

  be send_direct_message(sender: String, receiver: String, content: String) =>
    let url = URL.build("http://localhost:8080/send_message")?
    let body = JsonObject
    body.update("sender", sender)
    body.update("receiver", receiver)
    body.update("content", content)
    let req = Payload.request("POST", url)
    req.update("Content-Type", "application/json")
    req.update("body", body.string())
    _http(consume req, {(res: Payload val) =>
      _env.out.print("Response: " + res.status.string() + " " + res.body)
    })

  be get_direct_messages(username: String) =>
    let url = URL.build("http://localhost:8080/messages?username=" + username)?
    let req = Payload.request("GET", url)
    _http(consume req, {(res: Payload val) =>
      _env.out.print("Response: " + res.status.string() + " " + res.body)
    })