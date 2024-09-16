use "collections"

actor Main
  new create(env: Env) =>
    try
      let args = env.args
      let n = args(1)?.u64()?
      let k = args(2)?.u64()?
      Boss(env, n, k)
    else
      env.out.print("Usage: lucas_square_pyramid <N> <k>")
    end

actor Boss
  let _env: Env
  let _n: U64
  let _k: U64
  let _worker_count: USize = 4
  var _completed_workers: USize = 0
  let _results: Array[U64] = Array[U64]

  new create(env: Env, n: U64, k: U64) =>
    _env = env
    _n = n
    _k = k
    
    let chunk_size = (_n / _worker_count.u64()).max(1)
    let actual_worker_count = (((_n - 1) / chunk_size) + 1).usize()
    
    for i in Range[U64](0, _n, chunk_size) do
      let start = i + 1
      let end_range = (i + chunk_size).min(_n)
      Worker(this, _env, start, end_range, _k)
    end
    _worker_count = actual_worker_count

  be receive_result(result: U64) =>
    _results.push(result)

  be worker_finished() =>
    _completed_workers = _completed_workers + 1
    if _completed_workers == _worker_count then
      _print_results()
    end

  fun ref _print_results() =>
    Sort[Array[U64], U64](_results)
    for result in _results.values() do
      _env.out.print(result.string())
    end

actor Worker
  let _boss: Boss
  let _env: Env
  let _start: U64
  let _end: U64
  let _k: U64

  new create(boss: Boss, env: Env, start: U64, end_range: U64, k: U64) =>
    _boss = boss
    _env = env
    _start = start
    _end = end_range
    _k = k
    _check_range()

  be _check_range() =>
    for i in Range[U64](_start, _end + 1) do
      if ((_end + 1) - i) >= _k then
        if _is_square_sum(i) then
          _boss.receive_result(i)
        end
      end
    end
    _boss.worker_finished()

  fun _is_square_sum(start: U64): Bool =>
    var sum: U64 = 0
    for j in Range[U64](0, _k) do
      sum = sum + ((start + j) * (start + j))
    end
    _is_perfect_square(sum)

  fun _is_perfect_square(n: U64): Bool =>
    let root = n.f64().sqrt().u64()
    (root * root) == n