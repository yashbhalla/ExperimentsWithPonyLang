use "time"
use "collections"

class Post
  let author: Account
  let content: String
  let timestamp: I64
  var upvotes: I64 = 0
  var downvotes: I64 = 0
  let comments: List[Comment] = List[Comment]

  new create(author': Account, content': String) =>
    author = author'
    content = content'
    timestamp = Time.seconds()