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
  let _node_ids: Array[U64]
  let _nodes: Map[U64, ChordNode]
  let _num_nodes: USize
  let _num_requests: USize
  var _total_hops: U64 = 0
  var _total_requests: U64 = 0
  let _rng: Rand
  let _failure_probability: F64 = 0.1 // 10% chance of failure

  new create(env: Env, num_nodes: USize, num_requests: USize) =>
    _env = env
    _num_nodes = num_nodes
    _num_requests = num_requests
    _node_ids = Array[U64](num_nodes)
    _nodes = Map[U64, ChordNode]
    _rng = Rand(Time.nanos().u64())

  be initialize() =>
    for i in Range(0, _num_nodes) do
      let id = _rng.u64()
      let node = ChordNode(this, id)
      _node_ids.push(id)
      _nodes(id) = node
    end

    try
      bubble_sort(_node_ids)?

      for i in Range(0, _num_nodes) do
        let next = (i + 1) % _num_nodes
        _nodes(_node_ids(i)?)?.set_successor(_node_ids(next)?)
      end

      for node in _nodes.values() do
        node.simulate_requests(_num_requests)
      end
    else
      _env.out.print("Error during initialization")
    end

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
    if _total_requests == (_num_nodes * _num_requests).u64() then
      let avg_hops = _total_hops.f64() / _total_requests.f64()
      _env.out.print("Average number of hops: " + avg_hops.string())
    end

  be lookup(key: U64, origin: U64, hops: U64) =>
    try
      if _rng.real() < _failure_probability then
        // Simulate node failure
        _env.out.print("Node " + origin.string() + " has failed during lookup")
        // Try to use the next available node
        let next_node = find_next_available_node(origin)
        _nodes(next_node)?.do_lookup(key, next_node, hops)
      else
        _nodes(origin)?.do_lookup(key, origin, hops)
      end
    else
      _env.out.print("Error during lookup")
    end

  fun find_next_available_node(failed_node: U64): U64 =>
    try
      let failed_index = _node_ids.find(failed_node)?
      var next_index = (failed_index + 1) % _num_nodes
      while next_index != failed_index do
        try
          return _node_ids(next_index)?
        end
        next_index = (next_index + 1) % _num_nodes
      end
    end
    failed_node // If no other node is available, return the failed node

actor ChordNode
  let _network: ChordNetwork
  let _id: U64
  var _successor_id: U64 = 0
  let _rng: Rand
  let _connection_failure_probability: F64 = 0.05 // 5% chance of connection failure

  new create(network: ChordNetwork, node_id: U64) =>
    _network = network
    _id = node_id
    _rng = Rand(Time.nanos().u64())

  be set_successor(succ_id: U64) =>
    _successor_id = succ_id

  be simulate_requests(num_requests: USize) =>
    for _ in Range(0, num_requests) do
      let key = _rng.u64()
      _network.lookup(key, _id, 0)
    end

  be do_lookup(key: U64, origin: U64, hops: U64) =>
    if _rng.real() < _connection_failure_probability then
      // Simulate connection failure
      _network.lookup(key, _successor_id, hops + 1)
    else
      if between_right_inclusive(key) then
        _network.report_hops(hops + 1)
      else
        _network.lookup(key, _successor_id, hops + 1)
      end
    end

  fun between_right_inclusive(key: U64): Bool =>
    if _id < _successor_id then
      (_id < key) and (key <= _successor_id)
    else
      (_id < key) or (key <= _successor_id)
    end