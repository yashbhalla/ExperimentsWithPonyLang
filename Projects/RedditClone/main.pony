use "time"

actor Main
  new create(env: Env) =>
    let engine = RedditEngine
    let simulator = Simulator(env, engine, 500, 100, 120)
    simulator.run()