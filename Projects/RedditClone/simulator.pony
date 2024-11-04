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
    _create_users()
    _create_subreddits()
    _simulate_activity()
    _print_statistics()

  fun ref _create_users() =>
    for i in Range(0, _num_users) do
      let username = "user" + i.string()
      let password = "pass" + i.string()
      _engine.register_account(username, password)
      _users.push(username)
    end

  fun ref _create_subreddits() =>
    for i in Range(0, _num_subreddits) do
      let subreddit_name = "subreddit" + i.string()
      _engine.create_subreddit(subreddit_name)
      _subreddits.push(subreddit_name)
    end

  fun ref _simulate_activity() =>
    let start_time = Time.seconds()
    while (Time.seconds() - start_time) < _simulation_time do
      let action = _rand.int(5)
      match action
      | 0 => _simulate_join_subreddit()
      | 1 => _simulate_leave_subreddit()
      | 2 => _simulate_post()
      | 3 => _simulate_comment()
      | 4 => _simulate_vote()
      end
    end

  fun ref _simulate_join_subreddit() =>
    let user = _random_user()
    let subreddit = _random_subreddit()
    _engine.join_subreddit(user, subreddit)

  fun ref _simulate_leave_subreddit() =>
    let user = _random_user()
    let subreddit = _random_subreddit()
    _engine.leave_subreddit(user, subreddit)

  fun ref _simulate_post() =>
    let user = _random_user()
    let subreddit = _random_subreddit()
    let content = "This is a test post from " + user
    _engine.post_in_subreddit(user, subreddit, content)

  fun ref _simulate_comment() =>
    let user = _random_user()
    let subreddit = _random_subreddit()
    let post_index = _rand.int(_num_users.i32()).usize()
    let content = "This is a test comment from " + user
    _engine.comment_on_post(user, subreddit, post_index, content)

  fun ref _simulate_vote() =>
    let user = _random_user()
    let subreddit = _random_subreddit()
    let post_index = _rand.int(_num_users.i32()).usize()
    if _rand.bool() then
      _engine.upvote_post(user, subreddit, post_index)
    else
      _engine.downvote_post(user, subreddit, post_index)
    end

  fun ref _random_user(): String =>
    try
      _users(_rand.int(_num_users.i32()).usize())?
    else
      ""
    end

  fun ref _random_subreddit(): String =>
    try
      _subreddits(_rand.int(_num_subreddits.i32()).usize())?
    else
      ""
    end

  fun _print_statistics() =>
    _env.out.print("Simulation completed")
    _env.out.print("Number of users: " + _num_users.string())
    _env.out.print("Number of subreddits: " + _num_subreddits.string())
    _env.out.print("Simulation time: " + _simulation_time.string() + " seconds")