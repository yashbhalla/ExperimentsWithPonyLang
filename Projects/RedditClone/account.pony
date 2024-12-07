use "collections"

class Account is (Hashable & Equatable[Account])
  let username: String
  let password: String
  var karma: I64 = 0
  let subscriptions: Array[SubReddit] = Array[SubReddit]
  let messages: Array[Message] = Array[Message]

  new create(username': String, password': String) =>
    username = username'
    password = password'

  fun hash(): USize =>
    username.hash()

  fun eq(that: Account box): Bool =>
    this.username == that.username