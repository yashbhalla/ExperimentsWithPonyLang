use "collections"

class SubReddit is (Hashable & Equatable[SubReddit])
  let name: String
  let members: Array[Account] = Array[Account]
  let posts: Array[Post ref] = Array[Post ref]

  new create(name': String) =>
    name = name'

  fun hash(): USize =>
    name.hash()

  fun eq(that: SubReddit box): Bool =>
    this.name == that.name