use "collections"
use "random"
use "time"
use "promises"

actor Main
  new create(env: Env) =>
    try
      let args = env.args
      let num_nodes = args(1)?.usize()?
      let num_requests = args(2)?.usize()?

      let network = ChordNetwork(env, num_nodes, num_requests)
      network.initialize()
    else
      env.out.print("Usage: project3 numNodes numRequests")
    end

actor ChordNetwork
  let _env: Env
  let _node_ids: Array[U64]
  let _nodes: Map[U64, ChordNode]
  let _num_nodes: USize
  let _num_requests: USize
  var _total_hops: U64 = 0
  var _total_requests: U64 = 0
  let _rng: Rand
  let _m: USize = 64 // Size of the identifier space (64-bit)
  let _timers: Timers = Timers

  new create(env: Env, num_nodes: USize, num_requests: USize) =>
    _env = env
    _num_nodes = num_nodes
    _num_requests = num_requests
    _node_ids = Array[U64](num_nodes)
    _nodes = Map[U64, ChordNode]
    _rng = Rand(Time.nanos().u64())

  be initialize() =>
    _env.out.print("Initializing Chord network with " + _num_nodes.string() + " nodes and " + _num_requests.string() + " requests per node")
    for i in Range(0, _num_nodes) do
      let id = _rng.u64()
      let node = ChordNode(this, id, _m)
      _node_ids.push(id)
      _nodes(id) = node
    end

    try
      bubble_sort(_node_ids)?

      for i in Range(0, _num_nodes) do
        let next = (i + 1) % _num_nodes
        _nodes(_node_ids(i)?)?.set_successor(_node_ids(next)?)
      end

      let node_ids_val = create_immutable_array(_node_ids)

      // Initialize finger tables
      for node in _nodes.values() do
        node.init_finger_table(node_ids_val)
      end

      _env.out.print("Starting simulation")
      for node in _nodes.values() do
        node.simulate_requests(_num_requests)
      end

      // Set a timer to check for completion
      let timer = Timer(
        object iso
          let network: ChordNetwork = this
          fun ref apply(timer: Timer, count: U64): Bool =>
            network.check_completion()
            true
          fun ref cancel(timer: Timer) => None
        end,
        5_000_000_000, // 5 seconds
        5_000_000_000  // 5 seconds
      )
      _timers(consume timer)
    else
      _env.out.print("Error during initialization")
    end

  fun create_immutable_array(arr: Array[U64]): Array[U64] val =>
    let temp = recover Array[U64](arr.size()) end
    for v in arr.values() do
      temp.push(v)
    end
    consume temp

  fun ref bubble_sort(arr: Array[U64]) ? =>
    let n = arr.size()
    for i in Range(0, n) do
      for j in Range(0, n - i - 1) do
        if arr(j)? > arr(j + 1)? then
          let temp = arr(j)?
          arr(j)? = arr(j + 1)?
          arr(j + 1)? = temp
        end
      end
    end

  be report_hops(hops: U64) =>
    _total_hops = _total_hops + hops
    _total_requests = _total_requests + 1
    if (_total_requests % 100) == 0 then
      _env.out.print("Processed " + _total_requests.string() + " requests")
    end
    check_completion()

  be check_completion() =>
    if _total_requests == (_num_nodes * _num_requests).u64() then
      let avg_hops = _total_hops.f64() / _total_requests.f64()
      _env.out.print("Simulation complete")
      _env.out.print("Total requests: " + _total_requests.string())
      _env.out.print("Average number of hops: " + avg_hops.string())
      _timers.dispose()
    end

  be lookup(key: U64, origin: U64, hops: U64) =>
    try
      _nodes(origin)?.do_lookup(key, origin, hops)
    else
      _env.out.print("Error during lookup")
    end

  be report_error(msg: String) =>
    _env.out.print("Error: " + msg)

actor ChordNode
  let _network: ChordNetwork
  let _id: U64
  var _successor_id: U64
  let _finger_table: Array[U64]
  let _m: USize
  let _rng: Rand

  new create(network: ChordNetwork, node_id: U64, m: USize) =>
    _network = network
    _id = node_id
    _successor_id = 0
    _m = m
    _finger_table = Array[U64].init(0, m)
    _rng = Rand(Time.nanos().u64())

  be set_successor(succ_id: U64) =>
    try
      _successor_id = succ_id
      _finger_table(0)? = succ_id
    else
      _network.report_error("Error in set_successor")
    end

  be init_finger_table(node_ids: Array[U64] val) =>
    for i in Range(0, _m) do
      let finger_start = (_id + (U64(1) << i.u64())) and ((U64(1) << _m.u64()) - U64(1))
      try
        _finger_table(i)? = find_successor(finger_start, node_ids)
      else
        _network.report_error("Error in init_finger_table")
      end
    end

  fun find_successor(id: U64, node_ids: Array[U64] val): U64 =>
    for node_id in node_ids.values() do
      if between_right_inclusive(id) then
        return node_id
      end
    end
    _successor_id

  be simulate_requests(num_requests: USize) =>
    for _ in Range(0, num_requests) do
      let key = _rng.u64()
      _network.lookup(key, _id, 0)
    end

  be do_lookup(key: U64, origin: U64, hops: U64) =>
    _network.report_error("Node " + _id.string() + " looking up key " + key.string() + " (hops: " + hops.string() + ")")
    if between_right_inclusive(key) then
      _network.report_hops(hops + 1)
    else
      try
        let next_node = closest_preceding_node(key)?
        _network.lookup(key, next_node, hops + 1)
      else
        _network.report_error("Error in do_lookup")
      end
    end

  fun closest_preceding_node(key: U64): U64 ? =>
    for i in Range(_m - 1, -1, -1) do
      if between(_finger_table(i)?, key) then
        return _finger_table(i)?
      end
    end
    _successor_id

  fun between(id: U64, key: U64): Bool =>
    if _id < id then
      (_id < key) and (key < id)
    else
      (_id < key) or (key < id)
    end

  fun between_right_inclusive(key: U64): Bool =>
    if _id < _successor_id then
      (_id < key) and (key <= _successor_id)
    else
      (_id < key) or (key <= _successor_id)
    end