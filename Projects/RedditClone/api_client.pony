use "http_server"
use "json"

actor ApiClient
  let _env: Env
  let _http: HTTPClientWrapper

  new create(env: Env, host: String, port: String) =>
    _env = env
    _http = HTTPClientWrapper(env.root as AmbientAuth)

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
    let url = client_http.URL.build("http://localhost:8080/post")?
    let body = JsonObject
    body.update("username", username)
    body.update("subreddit_name", subreddit_name)
    body.update("content", content)
    let req = client_http.Payload.request("POST", url)
    req.update("Content-Type", "application/json")
    req.update("body", body.string())
    _http(consume req, {(res: client_http.Payload val) =>
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

class HTTPClientWrapper
  let _client: TCPConnectionNotify

  new create(auth: AmbientAuth) =>
    _client = TCPConnectionNotify(auth)

  fun ref send(req: Payload val, callback: {(Payload val)} val) =>
    let conn = TCPConnection(
      auth,
      recover HTTPClientConnectionNotify(req, callback) end
    )
    conn.connect(req.url.host, req.url.service)

class HTTPClientConnectionNotify is TCPConnectionNotify
  let _req: Payload val
  let _callback: {(Payload val)} val

  new iso create(req: Payload val, callback: {(Payload val)} val) =>
    _req = req
    _callback = callback

  fun ref connected(conn: TCPConnection ref) =>
    conn.write(_req.write())

  fun ref received(conn: TCPConnection ref, data: Array[U8] iso, times: USize): Bool =>
    let payload = Payload.response(200, consume data)
    _callback(payload)
    conn.close()
    false

  fun ref connect_failed(conn: TCPConnection ref) =>
    let payload = Payload.response(500, "Connection failed")
    _callback(payload)