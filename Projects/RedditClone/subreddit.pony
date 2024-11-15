use "collections"

class SubReddit is (Hashable & Equatable[SubReddit])
  let name: String
  let members: Array[Account] = Array[Account]
  let posts: List[Post] = List[Post]

  new create(name': String) =>
    name = name'

  fun hash(): USize =>
    name.hash()

  fun eq(that: SubReddit): Bool =>
    this.name == that.name