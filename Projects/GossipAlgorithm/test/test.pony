use "collections"
use "random"
use "time"
use "files"

trait Actor
  be add_neighbor(neighbor: Actor tag)
  be receive_rumor()
  be receive_pair(s: F64, w: F64)
  be simulate_failure(failure_prob: F64)
  be report_convergence(main: Main tag)

actor GossipActor is Actor
  let _id: USize
  let _neighbors: Array[Actor tag] = Array[Actor tag]
  var _rumor_count: USize = 0
  var _active: Bool = true
  var _failed: Bool = false
  var _main: (Main tag | None) = None

  new create(id: USize, main: Main tag) =>
    _id = id
    _main = main

  be add_neighbor(neighbor: Actor tag) =>
    _neighbors.push(neighbor)

  be start_gossip() =>
    receive_rumor()

  be receive_rumor() =>
    if not _failed then
      _rumor_count = _rumor_count + 1
      if _rumor_count >= 10 then
        _active = false
        try (_main as Main tag).report_convergence() end
      elseif _active and (_neighbors.size() > 0) then
        let rand = Rand(Time.nanos().u64())
        try
          let neighbor = _neighbors(rand.int(_neighbors.size().u64()).usize())?
          neighbor.receive_rumor()
        end
      end
    end

  be receive_pair(s: F64, w: F64) =>
    None // Do nothing for GossipActor

  be simulate_failure(failure_prob: F64) =>
    let rand = Rand(Time.nanos().u64())
    if rand.real() < failure_prob then
      _failed = true

  be report_convergence(main: Main tag) =>
    if not _active and not _failed then
      main.report_convergence()
    end

actor PushSumActor is Actor
  let _id: USize
  let _neighbors: Array[Actor tag] = Array[Actor tag]
  var _s: F64
  var _w: F64 = 1.0
  var _ratio: F64
  var _unchanged_count: USize = 0
  var _active: Bool = true
  var _failed: Bool = false
  var _main: (Main tag | None) = None
  let _log: File

  new create(id: USize, main: Main tag) =>
    _id = id
    _s = id.f64()
    _ratio = _s / _w
    _main = main
    _log = File(FilePath(FileAuth.create(), "push_sum_" + id.string() + ".log"))
    _log.print("Initial s: " + _s.string() + ", w: " + _w.string() + ", ratio: " + _ratio.string())

  be add_neighbor(neighbor: Actor tag) =>
    _neighbors.push(neighbor)

  be start_push_sum() =>
    send_pair()

  be receive_rumor() =>
    None // Do nothing for PushSumActor

  be receive_pair(s_received: F64, w_received: F64) =>
    if not _failed then
      let old_ratio = _ratio
      _s = _s + s_received
      _w = _w + w_received
      _ratio = _s / _w

      _log.print("Received s: " + s_received.string() + ", w: " + w_received.string())
      _log.print("Updated s: " + _s.string() + ", w: " + _w.string() + ", ratio: " + _ratio.string())

      if (_ratio - old_ratio).abs() < 1e-10 then
        _unchanged_count = _unchanged_count + 1
      else
        _unchanged_count = 0
      end

      if _unchanged_count >= 3 then
        _active = false
        _log.print("Converged! Final ratio: " + _ratio.string())
        try (_main as Main tag).report_convergence() end
      elseif _active then
        send_pair()
      end
    end

  fun ref send_pair() =>
    if _neighbors.size() > 0 then
      let rand = Rand(Time.nanos().u64())
      try
        let neighbor = _neighbors(rand.int(_neighbors.size().u64()).usize())?
        _s = _s / 2
        _w = _w / 2
        _log.print("Sending s: " + _s.string() + ", w: " + _w.string() + " to neighbor " + neighbor.string())
        neighbor.receive_pair(_s, _w)
      end
    end

  be simulate_failure(failure_prob: F64) =>
    let rand = Rand(Time.nanos().u64())
    if rand.real() < failure_prob then
      _failed = true

  be report_convergence(main: Main tag) =>
    if not _active and not _failed then
      main.report_convergence()
    end

actor Main
  let env: Env
  let nodes: Array[Actor tag]
  let start_time: U64
  var converged_count: USize
  let total_nodes: USize
  let failure_prob: F64
  let final_ratios: Array[F64] = Array[F64]

  new create(env': Env) =>
    env = env'
    nodes = Array[Actor tag]
    start_time = Time.nanos()
    converged_count = 0
    total_nodes = 0
    failure_prob = 0.0

    if env.args.size() != 5 then
      env.out.print("Usage: project2 numNodes topology algorithm failureProb")
      return
    end

    let num_nodes = try env.args(1)?.usize()? else 10 end
    let topology = try env.args(2)? else "full" end
    let algorithm = try env.args(3)? else "gossip" end
    failure_prob = try env.args(4)?.f64()? else 0.0 end

    total_nodes = num_nodes

    // Create nodes
    for i in Range(0, num_nodes) do
      if algorithm == "gossip" then
        nodes.push(GossipActor(i, this))
      else
        nodes.push(PushSumActor(i, this))
      end
    end

    // Build topology
    match topology
    | "full" => build_full_network(nodes)
    | "3D" => build_3d_grid(nodes)
    | "line" => build_line(nodes)
    | "imp3D" => build_imperfect_3d_grid(nodes)
    else
      env.out.print("Invalid topology")
      return
    end

    // Simulate failures
    for node in nodes.values() do
      node.simulate_failure(failure_prob)
    end

    // Start algorithm
    let rand = Rand(Time.nanos().u64())
    let starter: USize = rand.int(num_nodes.u64()).usize()

    match algorithm
    | "gossip" =>
      try 
        (nodes(starter)? as GossipActor).start_gossip()
      end
    | "push-sum" =>
      try 
        (nodes(starter)? as PushSumActor).start_push_sum()
      end
    else
      env.out.print("Invalid algorithm")
      return
    end

  be report_convergence() =>
    converged_count = converged_count + 1
    let active_nodes = nodes.size() - (failure_prob * nodes.size().f64()).usize()
    if converged_count == active_nodes then
      let end_time = Time.nanos()
      let convergence_time = end_time - start_time
      env.out.print("Convergence time: " + (convergence_time.f64() / 1_000_000.0).string() + " milliseconds")
      env.out.print("Failure probability: " + failure_prob.string())
      env.out.print("Active nodes: " + active_nodes.string() + "/" + nodes.size().string())
      print_final_ratios()

  fun print_final_ratios() =>
    env.out.print("Final ratios:")
    for ratio in final_ratios.values() do
      env.out.print(ratio.string())
    end
    let avg_ratio = final_ratios.fold[F64]({(sum, x) => sum + x}, 0.0) / final_ratios.size().f64()
    env.out.print("Average ratio: " + avg_ratio.string())

  fun build_full_network(network: Array[Actor tag]) =>
    for i in Range(0, network.size()) do
      try
        let node = network(i)?
        for j in Range(0, network.size()) do
          if i != j then
            try node.add_neighbor(network(j)?) end
          end
        end
      end
    end

  fun build_3d_grid(network: Array[Actor tag]) =>
    let size = (network.size().f64().pow(1/3).ceil()).usize()
    for i in Range(0, network.size()) do
      try
        let node = network(i)?
        let x = i % size
        let y = (i / size) % size
        let z = i / (size * size)
        if x > 0 then node.add_neighbor(network(i-1)?) end
        if x < (size-1) then node.add_neighbor(network(i+1)?) end
        if y > 0 then node.add_neighbor(network(i-size)?) end
        if y < (size-1) then node.add_neighbor(network(i+size)?) end
        if z > 0 then node.add_neighbor(network(i-(size*size))?) end
        if z < (size-1) then node.add_neighbor(network(i+(size*size))?) end
      end
    end

  fun build_line(network: Array[Actor tag]) =>
    for i in Range(0, network.size()) do
      try
        let node = network(i)?
        if i > 0 then node.add_neighbor(network(i-1)?) end
        if i < (network.size()-1) then node.add_neighbor(network(i+1)?) end
      end
    end

  fun build_imperfect_3d_grid(network: Array[Actor tag]) =>
    build_3d_grid(network)
    let rand = Rand(Time.nanos().u64())
    for i in Range(0, network.size()) do
      try
        let node = network(i)?
        let random_neighbor = rand.int(network.size().u64()).usize()
        if random_neighbor != i then
          node.add_neighbor(network(random_neighbor)?)
        end
      end
    end