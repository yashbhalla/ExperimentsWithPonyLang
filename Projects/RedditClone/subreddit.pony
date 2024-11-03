use "collections"

class SubReddit
  let name: String
  let members: Set[Account] = Set[Account]
  let posts: List[Post] = List[Post]

  new create(name': String) =>
    name = name'