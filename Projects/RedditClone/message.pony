use "time"

class Message
  let sender: Account
  let receiver: Account
  let content: String
  let timestamp: I64

  new create(sender': Account, receiver': Account, content': String) =>
    sender = sender'
    receiver = receiver'
    content = content'
    timestamp = Time.seconds()