use "time"
use "collections"

class Comment
  let author: Account
  let content: String
  let timestamp: I64
  var upvotes: I64 = 0
  var downvotes: I64 = 0
  let replies: List[Comment] = List[Comment]

  new create(author': Account, content': String) =>
    author = author'
    content = content'
    timestamp = Time.seconds()