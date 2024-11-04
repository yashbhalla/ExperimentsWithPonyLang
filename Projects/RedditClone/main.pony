

actor Main
  new create(env: Env) =>
    let engine = RedditEngine
    let simulator = Simulator(env, engine, 1000, 50, 60)
    simulator.run()