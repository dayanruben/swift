// RUN: %target-run-simple-swift(-Xfrontend -enable-experimental-concurrency %import-libdispatch -parse-as-library)

// REQUIRES: executable_test
// REQUIRES: concurrency
// REQUIRES: libdispatch

actor Counter {
  private var value = 0
  private let scratchBuffer: UnsafeMutableBufferPointer<Int>

  init(maxCount: Int) {
    scratchBuffer = .allocate(capacity: maxCount)
    scratchBuffer.initialize(repeating: 0)
  }

  func next() -> Int {
    let current = value

    // Make sure we haven't produced this value before
    assert(scratchBuffer[current] == 0)
    scratchBuffer[current] = 1

    value = value + 1
    return current
  }
}


func worker(identity: Int, counters: [Counter], numIterations: Int) async {
  for i in 0..<numIterations {
    let counterIndex = Int.random(in: 0 ..< counters.count)
    let counter = counters[counterIndex]
    let nextValue = await counter.next()
    print("Worker \(identity) calling counter \(counterIndex) produced \(nextValue)")
  }
}

func runTest(numCounters: Int, numWorkers: Int, numIterations: Int) async {
  // Create counter actors.
  var counters: [Counter] = []
  for i in 0..<numCounters {
    counters.append(Counter(maxCount: numWorkers * numIterations))
  }

  // Create a bunch of worker threads.
  var workers: [Task.Handle<Void, Error>] = []
  for i in 0..<numWorkers {
    workers.append(
      Task.runDetached { [counters] in
        await Task.sleep(UInt64.random(in: 0..<100) * 1_000_000)
        await worker(identity: i, counters: counters, numIterations: numIterations)
      }
    )
  }

  // Wait until all of the workers have finished.
  for worker in workers {
    try! await worker.get()
  }

  print("DONE!")
}

@main struct Main {
  static func main() async {
    await runTest(numCounters: 10, numWorkers: 100, numIterations: 1000)
  }
}
