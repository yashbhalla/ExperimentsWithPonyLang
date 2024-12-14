/*
use "net"
use "json"
use "http_server"

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


*/
use "net"
use "json"
use "promises"

actor ApiClient
  let _env: Env
  let _host: String
  let _port: String

  new create(env: Env, host: String, port: String) =>
    _env = env
    _host = host
    _port = port

  be register_account(username: String, password: String) =>
    recover
      let json = JsonObject
      json.update("username", username)
      json.update("password", password)
      make_request("/register", json)
    end

  be create_subreddit(name: String) =>
    recover
      let json = JsonObject
      json.update("name", name)
      make_request("/create_subreddit", json)
    end

  be join_subreddit(username: String, subreddit_name: String) =>
    recover
      let json = JsonObject
      json.update("username", username)
      json.update("subreddit_name", subreddit_name)
      make_request("/join_subreddit", json)
    end

  be post_in_subreddit(username: String, subreddit_name: String, content: String) =>
    recover
      let json = JsonObject
      json.update("username", username)
      json.update("subreddit_name", subreddit_name)
      json.update("content", content)
      make_request("/post", json)
    end

  be comment_on_post(username: String, subreddit_name: String, post_index: USize, content: String) =>
    recover
      let json = JsonObject
      json.update("username", username)
      json.update("subreddit_name", subreddit_name)
      json.update("post_index", post_index.u64())
      json.update("content", content)
      make_request("/comment", json)
    end

  be upvote_post(username: String, subreddit_name: String, post_index: USize) =>
    recover
      let json = JsonObject
      json.update("username", username)
      json.update("subreddit_name", subreddit_name)
      json.update("post_index", post_index.u64())
      make_request("/upvote", json)
    end

  be downvote_post(username: String, subreddit_name: String, post_index: USize) =>
    recover
      let json = JsonObject
      json.update("username", username)
      json.update("subreddit_name", subreddit_name)
      json.update("post_index", post_index.u64())
      make_request("/downvote", json)
    end

  be send_direct_message(sender: String, receiver: String, content: String) =>
    let json = JsonObject
    json.update("sender", sender)
    json.update("receiver", receiver)
    json.update("content", content)
    make_request("/send_message", json)

  be get_direct_messages(username: String) =>
    make_request("/messages?username=" + username, None, false)

  be get_feed(username: String) =>
    recover
      make_request("/feed?username=" + username, None, false)
    end

  fun ref get_messages(username: String): Promise[Array[JsonObject]]  =>
    recover
      make_request("/messages?username=" + username, None, false)
    end

  be make_request(endpoint: String, body: (JsonObject val | None), is_post: Bool = true) =>
    let promise = Promise[(Array[JsonObject] | None)]
    let url = "http://" + _host + ":" + _port + endpoint

    try
      let auth = TCPConnectAuth(_env.root as AmbientAuth)
      let notify = ApiClientNotify(promise, is_post, body)
      let conn = TCPConnection(auth, consume notify, _host, _port)
      
      let request = if is_post then
        match body
        | let json_body: JsonObject =>
          "POST " + endpoint + " HTTP/1.1\r\n" +
          "Content-Type: application/json\r\n" +
          "Content-Length: " + json_body.string().size().string() + "\r\n\r\n" +
          json_body.string()
        else
          "POST " + endpoint + " HTTP/1.1\r\n\r\n"
        end
      else
        "GET " + endpoint + " HTTP/1.1\r\n\r\n"
      end

      conn.write(request.array())
    else
      promise.reject("Failed to create connection")
    end

    promise

class ApiClientNotify is TCPConnectionNotify
  let _promise: Promise[(Array[JsonObject] | None)]
  let _is_post: Bool
  let _body: (JsonObject | None)
  var _response: String = ""

  new iso create(promise: Promise[(Array[JsonObject] | None)], is_post: Bool, body: (JsonObject val | None)) =>
    _promise = promise
    _is_post = is_post
    _body = body

  fun ref received(conn: TCPConnection ref, data: Array[U8] iso, times: USize): Bool =>
    _response = _response + String.from_array(consume data)
    true

  fun ref connect_failed(conn: TCPConnection ref) =>
    _promise.reject("Connection failed")

  fun ref closed(conn: TCPConnection ref) =>
    try
      let parsed = JsonDoc.from_string(_response)?.data.as_array()?
      _promise.fulfill(parsed)
    else
      _promise.reject("Failed to parse response")
    end



/*

use "net"
use "json"
use "promises"

actor ApiClient
  let _env: Env
  let _host: String
  let _port: String

  be send_direct_message(sender: String, receiver: String, content: String) =>
    let body = JsonObject
    body.data.update("sender", sender)
    body.data.update("receiver", receiver)
    body.data.update("content", content)
    make_request("/send_message", body)

  be get_direct_messages(username: String) =>
    make_request("/messages?username=" + username, None)

  new create(env: Env, host: String, port: String) =>
    _env = env
    _host = host
    _port = port

  be register_account(username: String, password: String) =>
    let json = JsonObject
    json.data.update("username", username)
    json.data.update("password", password)
    make_request("/register", json)

  be create_subreddit(name: String) =>
    let json = JsonObject
    json.data.update("name", name)
    make_request("/create_subreddit", json)

  be join_subreddit(username: String, subreddit_name: String) =>
    let json = JsonObject
    json.data.update("username", username)
    json.data.update("subreddit_name", subreddit_name)
    make_request("/join_subreddit", json)

  be post_in_subreddit(username: String, subreddit_name: String, content: String) =>
    let json = JsonObject
    json.data.update("username", username)
    json.data.update("subreddit_name", subreddit_name)
    json.data.update("content", content)
    make_request("/post", json)

  be comment_on_post(username: String, subreddit_name: String, post_index: USize, content: String) =>
    let json = JsonObject
    json.data.update("username", username)
    json.data.update("subreddit_name", subreddit_name)
    json.data.update("post_index", post_index.string())
    json.data.update("content", content)
    make_request("/comment", json)

  be upvote_post(username: String, subreddit_name: String, post_index: USize) =>
    let json = JsonObject
    json.data.update("username", username)
    json.data.update("subreddit_name", subreddit_name)
    json.data.update("post_index", post_index.string())
    make_request("/upvote", json)

  be downvote_post(username: String, subreddit_name: String, post_index: USize) =>
    let json = JsonObject
    json.data.update("username", username)
    json.data.update("subreddit_name", subreddit_name)
    json.data.update("post_index", post_index.string())
    make_request("/downvote", json)

  be get_feed(username: String) =>
    make_request("/feed?username=" + username, None)

  be get_messages(username: String) =>
    make_request("/messages?username=" + username, None)

  fun ref make_request(endpoint: String, body: (JsonObject | None), is_post: Bool = true) =>
    try
      let auth = TCPConnectAuth(_env.root as AmbientAuth)
      let notifier = ApiClientNotifier(body, is_post)
      let conn = TCPConnection(auth, consume notifier, _host, _port)
      let request = if is_post then
        match body
        | let json_body: JsonObject =>
          "POST " + endpoint + " HTTP/1.1\r\n" +
          "Content-Type: application/json\r\n" +
          "Content-Length: " + json_body.string().size().string() + "\r\n\r\n" +
          json_body.string()
        else
          "POST " + endpoint + " HTTP/1.1\r\n\r\n"
        end
      else
        "GET " + endpoint + " HTTP/1.1\r\n\r\n"
      end
      conn.write(request.array())
    end

class ApiClientNotifier is TCPConnectionNotify
  let _body: (JsonObject | None)
  let _is_post: Bool
  var _response: String = ""

  new iso create(body: (JsonObject val | None), is_post: Bool) =>
    _body = body
    _is_post = is_post

  fun ref received(conn: TCPConnection ref, data: Array[U8] iso, times: USize): Bool =>
    _response = _response + String.from_array(consume data)
    true

  fun ref connect_failed(conn: TCPConnection ref) =>
    None

  fun ref closed(conn: TCPConnection ref) =>
    try
      let parsed = JsonDoc.from_string(_response)?.data
      match parsed
      | let arr: JsonArray => None // Handle array response
      | let obj: JsonObject => None // Handle object response
      else
        None // Handle other cases
      end
    else
      None // Handle parsing error
    end
*/