use "random"
use "collections"
use "time"

actor Simulator
  let _env: Env
  let _engine: RedditEngine
  let _rand: Random
  let _num_users: USize
  let _num_subreddits: USize
  let _simulation_time: I64
  let _users: Array[String] = Array[String]
  let _subreddits: Array[String] = Array[String]

  new create(env: Env, engine: RedditEngine, num_users: USize, num_subreddits: USize, simulation_time: I64) =>
    _env = env
    _engine = engine
    _rand = Random(Time.nanos())
    _num_users = num_users
    _num_subreddits = num_subreddits
    _simulation_time = simulation_time

  be run() =>
    // Implementation here

  // Other methods...