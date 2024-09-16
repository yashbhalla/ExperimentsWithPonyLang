
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
  let envBoss: Env
  let nBoss: U64
  let kBoss: U64
  var workerCount: USize = 4
  var completedWorkers: USize = 0
  let results: Array[U64] = Array[U64]

  new create(env: Env, n: U64, k: U64) =>
    envBoss = env
    nBoss = n
    kBoss = k
   
    let chunkSize = (nBoss / workerCount.u64()).max(1)
    let actualWorkerCount = (((nBoss - 1) / chunkSize) + 1).usize()

    for i in Range[U64](0, nBoss, chunkSize) do
      let start = i + 1
      let endRange = (i + chunkSize).min(nBoss)
      Worker(this, env, start, endRange, kBoss)
    end
    workerCount = actualWorkerCount

  be receiveResult(result: U64) =>
    results.push(result)

  be workerFinished() =>
    completedWorkers = completedWorkers + 1
    if completedWorkers == workerCount then
      printResults()
    end

  fun ref printResults() =>
    Sort[Array[U64], U64](results)
    if results.size() == 0 then
      envBoss.out.print("0")
    else
      for result in results.values() do
        envBoss.out.print(result.string())
      end
    end

actor Worker
  let bossWorker: Boss
  let envWorker: Env
  let startWorker: U64
  let endWorker: U64
  let kWorker: U64

  new create(boss: Boss, env: Env, start: U64, end_range: U64, k: U64) =>
    bossWorker = boss
    envWorker = env
    startWorker = start
    endWorker = end_range
    kWorker = k
    checkRange()

  be checkRange() =>
    for i in Range[U64](startWorker, endWorker + 1) do
      if checkSquareSum(i) then
        bossWorker.receiveResult(i)
      end
    end
    bossWorker.workerFinished()

  fun checkSquareSum(start: U64): Bool =>
    var sum: U64 = 0
    for j in Range[U64](0, kWorker) do
      sum = sum + ((start + j) * (start + j))
    end
    checkPerfectSquare(sum)

  fun checkPerfectSquare(n: U64): Bool =>
    let root: U64 = n.f64().sqrt().floor().u64()
    (root * root) == n

