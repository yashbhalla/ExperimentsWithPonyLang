use "collections"
use "random"
use "time"

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
  let _node_ids: Array[U64] val
  let _nodes: Map[U64, ChordNode]
  let _num_nodes: USize
  let _num_requests: USize
  var _total_hops: U64 = 0
  var _total_requests: U64 = 0
  let _rng: Rand
  let _m: USize = 64 // Assuming 64-bit identifiers

  new create(env: Env, num_nodes: USize, num_requests: USize) =>
    _env = env
    _num_nodes = num_nodes
    _num_requests = num_requests
    _rng = Rand(Time.nanos().u64())
    
    _node_ids = recover val
      let arr = Array[U64](_num_nodes)
      for i in Range(0, _num_nodes) do
        arr.push(_rng.u64())
      end
      sort(arr)
      arr
    end
    _nodes = Map[U64, ChordNode]

  fun sort(arr: Array[U64]): Array[U64] =>
    let n = arr.size()
    for i in Range(0, n) do
      for j in Range(0, n - i - 1) do
        try
          if arr(j)? > arr(j + 1)? then
            let temp = arr(j)?
            arr(j)? = arr(j + 1)?
            arr(j + 1)? = temp
          end
        end
      end
    end
    arr

  be initialize() =>
    for id in _node_ids.values() do
      let node = ChordNode(this, id, _m)
      _nodes(id) = node
    end

    try
      for i in Range(0, _num_nodes) do
        let next = (i + 1) % _num_nodes
        _nodes(_node_ids(i)?)?.set_successor(_node_ids(next)?)
      end

      // Initialize finger tables
      for node_id in _node_ids.values() do
        _nodes(node_id)?.initialize_finger_table(_node_ids)
      end

      for node in _nodes.values() do
        node.simulate_requests(_num_requests)
      end
    else
      _env.out.print("Error during initialization")
    end

  be report_hops(hops: U64) =>
    _total_hops = _total_hops + hops
    _total_requests = _total_requests + 1
    if _total_requests == (_num_nodes * _num_requests).u64() then
      let avg_hops = _total_hops.f64() / _total_requests.f64()
      _env.out.print("Average number of hops: " + avg_hops.string())
    end

  be lookup(key: U64, origin: U64, hops: U64) =>
    try
      _nodes(origin)?.do_lookup(key, origin, hops)
    else
      _env.out.print("Error during lookup")
    end

actor ChordNode
  let _network: ChordNetwork
  let _id: U64
  var _successor_id: U64 = 0
  let _rng: Rand
  let _finger_table: Array[U64] ref
  let _m: USize

  new create(network: ChordNetwork, node_id: U64, m: USize) =>
    _network = network
    _id = node_id
    _rng = Rand(Time.nanos().u64())
    _m = m
    _finger_table = Array[U64].init(0, m)

  be set_successor(succ_id: U64) =>
    _successor_id = succ_id
    _finger_table(0) = succ_id

  be initialize_finger_table(node_ids: Array[U64] val) =>
    for i in Range(0, _m) do
      let finger_start = (_id + (1 << i.u64())) and ((1 << _m.u64()) - 1)
      _finger_table(i) = find_successor(finger_start, node_ids)
    end

  fun find_successor(id: U64, node_ids: Array[U64] val): U64 =>
    for node_id in node_ids.values() do
      if between_right_inclusive(id) then
        return node_id
      end
    end
    node_ids(0)?

  be simulate_requests(num_requests: USize) =>
    for _ in Range(0, num_requests) do
      let key = _rng.u64()
      _network.lookup(key, _id, 0)
    end

  be do_lookup(key: U64, origin: U64, hops: U64) =>
    if between_right_inclusive(key) then
      _network.report_hops(hops + 1)
    else
      let next_node = closest_preceding_finger(key)
      _network.lookup(key, next_node, hops + 1)
    end

  fun closest_preceding_finger(id: U64): U64 =>
    var i: USize = _m - 1
    while i > 0 do
      if between_right_inclusive(_finger_table(i)) then
        return _finger_table(i)
      end
      i = i - 1
    end
    _successor_id

  fun between_right_inclusive(key: U64): Bool =>
    if _id < _successor_id then
      (_id < key) and (key <= _successor_id)
    else
      (_id < key) or (key <= _successor_id)
    end