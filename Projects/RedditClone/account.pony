use "collections"

class Account
  let username: String
  let password: String
  var karma: I64 = 0
  let subscriptions: Set[SubReddit] = Set[SubReddit]
  let messages: List[Message] = List[Message]

  new create(username': String, password': String) =>
    username = username'
    password = password'