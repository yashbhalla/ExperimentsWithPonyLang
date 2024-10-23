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
  let _m: USize = 160 // 160-bit identifier space

  new create(env: Env, num_nodes: USize, num_requests: USize) =>
    _env = env
    _num_nodes = num_nodes
    _num_requests = num_requests
    _node_ids = Array[U64](num_nodes)
    _nodes = Map[U64, ChordNode]
    _rng = Rand(Time.nanos().u64())

  be initialize() =>
    for i in Range(0, _num_nodes) do
      let id = _rng.u64() % (U64(1) << _m)
      let node = ChordNode(this, id, _m)
      _node_ids.push(id)
      _nodes(id) = node
    end

    try
      bubble_sort(_node_ids)?

      for i in Range(0, _num_nodes) do
        let node = _nodes(_node_ids(i)?)?
        node.join(_nodes(_node_ids(0)?)?)
      end

      for node in _nodes.values() do
        node.stabilize()
        node.fix_fingers()
      end

      Timer(Time.from_seconds(5), {() => 
        for node in _nodes.values() do
          node.simulate_requests(_num_requests)
        end
      })
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
      _nodes(origin)?.do_lookup(key, origin, hops)
    else
      _env.out.print("Error during lookup")
    end

actor ChordNode
  let _network: ChordNetwork
  let _id: U64
  var _successor: (ChordNode | None) = None
  var _predecessor: (ChordNode | None) = None
  let _finger_table: Array[ChordNode]
  let _m: USize
  let _rng: Rand

  new create(network: ChordNetwork, node_id: U64, m: USize) =>
    _network = network
    _id = node_id
    _m = m
    _finger_table = Array[ChordNode](_m)
    _rng = Rand(Time.nanos().u64())

  be join(node: ChordNode) =>
    node.find_successor(_id, this)

  be found_successor(s: ChordNode) =>
    _successor = s
    s.notify(this)

  be notify(predecessor: ChordNode) =>
    if (_predecessor is None) or (predecessor._id > (_predecessor as ChordNode)._id) then
      _predecessor = predecessor
    end

  be stabilize() =>
    match _successor
    | let s: ChordNode =>
      s.get_predecessor(this)
    end

  be got_predecessor(predecessor: (ChordNode | None)) =>
    match predecessor
    | let p: ChordNode =>
      if (p._id > _id) and (p._id < (_successor as ChordNode)._id) then
        _successor = p
        p.notify(this)
      end  
    end  
   Timer(Time.from_seconds(1), {() => this.stabilize()})

  be fix_fingers() =>
    for i in Range(0, \_m) do  
      let next\_id = (\_id + (U64(1) << i)) % (U64(1) << \_m)
      find\_successor(next\_id, this~update\_finger(i))
    end  
    Timer(Time.from\_seconds(1), {() => this.fix\_fingers()})

  be update_finger(i: USize, node: ChordNode) =>  
    \_finger\_table(i) = node

  be find_successor(id: U64, requester: ChordNode) =>  
    if between_right_inclusive(id, \_id, (\_successor as ChordNode).\_id) then  
      requester.found\_successor(\_successor as ChordNode)
    else  
      let closest = closest_preceding_node(id)
      closest.find_successor(id, requester)
    end

  fun ref closest_preceding_node(id: U64): ChordNode =>  
    for i in Range((\_m - 1), 0, -1) do  
      if (\_finger_table(i).\_id > \_id) and (\_finger_table(i).\_id < id) then  
        return \_finger_table(i)
      end  
    end  
  this

  be get_predecessor(requester: ChordNode) =>  
    requester.got_predecessor(\_predecessor)

  be simulate_requests(num_requests: USize) =>  
    for \_ in Range(0, num\_requests) do  
      let key = \_rng.u64() % (U64(1) << \_m)
      \_network.lookup(key, \_id, 0)
      Timer(Time.from\_seconds(1), {() =>   
      let key = \_rng.u64() % (U64(1) << \_m)
      \_network.lookup(key, \_id, 0)
      })
    end

  be do_lookup(key: U64, origin: U64, hops: U64) =>  
    if between_right_inclusive(key, \_id, (\_successor as ChordNode).\_id) then   
      \_network.report_hops(hops + 1)
    else   
      let next_node = closest_preceding_node(key)
      \_network.lookup(key, next_node.\_id, hops + 1)
    end  

  fun between_right_inclusive(key: U64, start: U64, end_: U64): Bool =>  
    if start < end then   
      (start < key) and (key <= end_)
    else   
      (start < key) or (key <= end_)
    end
