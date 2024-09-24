use "collections"
use "random"
use "time"
use "promises"

actor Main
  new create(env: Env) =>
    if env.args.size() != 4 then
      env.out.print("Usage: project2 numNodes topology algorithm")
      return
    end

    let num_nodes = try env.args(1)?.usize()? else 10 end
    let topology = try env.args(2)? else "full" end
    let algorithm = try env.args(3)? else "gossip" end

    let nodes = Array[Actor tag](num_nodes)

    // Create nodes
    for i in Range(0, num_nodes) do
      if algorithm == "gossip" then
        nodes.push(GossipActor(i))
      else
        nodes.push(PushSumActor(i))
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

    // Start algorithm
    let start_time = Time.nanos()
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

    // Wait for convergence (this is a simplification, you'd need a proper termination detection mechanism)
    Timers.apply(recover Timers.create() end)
      .apply(Timer(Nanos.from_seconds(10),
        {() =>
          let end_time = Time.nanos()
          env.out.print("Convergence time: " + ((end_time - start_time).f64() / 1e9).string() + " seconds")
        }))

  fun build_full_network(nodes: Array[Actor tag]) =>
    for i in Range(0, nodes.size()) do
      try
        let node = nodes(i)?
        for j in Range(0, nodes.size()) do
          if i != j then
            try node.add_neighbor(nodes(j)?) end
          end
        end
      end
    end

  fun build_3d_grid(nodes: Array[Actor tag]) =>
    let size = (nodes.size().f64().pow(1/3).ceil()).usize()
    for i in Range(0, nodes.size()) do
      try
        let node = nodes(i)?
        let x = i % size
        let y = (i / size) % size
        let z = i / (size * size)
        if x > 0 then node.add_neighbor(nodes(i-1)?) end
        if x < (size-1) then node.add_neighbor(nodes(i+1)?) end
        if y > 0 then node.add_neighbor(nodes(i-size)?) end
        if y < (size-1) then node.add_neighbor(nodes(i+size)?) end
        if z > 0 then node.add_neighbor(nodes(i-(size*size))?) end
        if z < (size-1) then node.add_neighbor(nodes(i+(size*size))?) end
      end
    end

  fun build_line(nodes: Array[Actor tag]) =>
    for i in Range(0, nodes.size()) do
      try
        let node = nodes(i)?
        if i > 0 then node.add_neighbor(nodes(i-1)?) end
        if i < (nodes.size()-1) then node.add_neighbor(nodes(i+1)?) end
      end
    end

  fun build_imperfect_3d_grid(nodes: Array[Actor tag]) =>
    build_3d_grid(nodes)
    let rand = Rand(Time.nanos().u64())
    for i in Range(0, nodes.size()) do
      try
        let node = nodes(i)?
        let random_neighbor = rand.int(nodes.size().u64()).usize()
        if random_neighbor != i then
          node.add_neighbor(nodes(random_neighbor)?)
        end
      end
    end


trait Actor
  be add_neighbor(neighbor: Actor tag)
  be receive_rumor()
  be receive_pair(s: F64, w: F64)

actor GossipActor is Actor
  let _id: USize
  let _neighbors: Array[Actor tag] = Array[Actor tag]
  var _rumor_count: USize = 0
  var _active: Bool = true

  new create(id: USize) =>
    _id = id

  be add_neighbor(neighbor: Actor tag) =>
    _neighbors.push(neighbor)

  be start_gossip() =>
    receive_rumor()

  be receive_rumor() =>
    _rumor_count = _rumor_count + 1
    if _rumor_count >= 10 then
      _active = false
    elseif _active and (_neighbors.size() > 0) then
      let rand = Rand(Time.nanos().u64())
      try
        let neighbor = _neighbors(rand.int(_neighbors.size().u64()).usize())?
        neighbor.receive_rumor()
      end
    end

  be receive_pair(s: F64, w: F64) =>
    // Do nothing for GossipActor

actor PushSumActor is Actor
  let _id: USize
  let _neighbors: Array[Actor tag] = Array[Actor tag]
  var _s: F64
  var _w: F64 = 1.0
  var _ratio: F64
  var _unchanged_count: USize = 0
  var _active: Bool = true

  new create(id: USize) =>
    _id = id
    _s = id.f64()
    _ratio = _s / _w

  be add_neighbor(neighbor: Actor tag) =>
    _neighbors.push(neighbor)

  be start_push_sum() =>
    send_pair()

  be receive_rumor() =>
    None // Do nothing for PushSumActor

  be receive_pair(s_received: F64, w_received: F64) =>
    let old_ratio = _ratio
    _s = _s + s_received
    _w = _w + w_received
    _ratio = _s / _w

    if (_ratio - old_ratio).abs() < 1e-10 then
      _unchanged_count = _unchanged_count + 1
    else
      _unchanged_count = 0
    end

    if _unchanged_count >= 3 then
      _active = false
    elseif _active then
      send_pair()
    end

  fun ref send_pair() =>
    if _neighbors.size() > 0 then
      let rand = Rand(Time.nanos().u64())
      try
        let neighbor = _neighbors(rand.int(_neighbors.size().u64()).usize())?
        _s = _s / 2
        _w = _w / 2
        neighbor.receive_pair(_s, _w)
      end
    end