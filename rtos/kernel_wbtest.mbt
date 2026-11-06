///|
test "higher-priority readiness and equal-priority round robin" {
  let k = Kernel::new()
  assert_eq(k.create(0, 31), 0)
  assert_eq(k.create(1, 5), 0)
  assert_eq(k.create(2, 5), 0)
  assert_eq(k.pick(), 1)
  assert_eq(k.advance(1), 0)
  assert_eq(k.pick(), 2)
  assert_eq(k.create(3, 1), 0)
  assert_eq(k.pick(), 3)
  assert_eq(k.sleep(3, 2), 1)
  assert_eq(k.pick(), 2)
  assert_eq(k.advance(2), 0)
  assert_eq(k.pick(), 3)
}

///|
test "queue blocked send is transferred once and timed-out send is removed" {
  let k = Kernel::new()
  ignore(k.create(1, 1))
  ignore(k.create(2, 2))
  ignore(k.queue(0, 1))
  assert_eq(k.send(1, 0, 41, 0), 0)
  assert_eq(k.send(1, 0, 42, 10), 1)
  assert_eq(k.receive(2, 0, 0), 0)
  assert_eq(k.received(2), 41)
  assert_eq(k.completion(1), 0)
  assert_eq(k.receive(2, 0, 0), 0)
  assert_eq(k.received(2), 42)
  ignore(k.send(1, 0, 43, 0))
  assert_eq(k.send(1, 0, 44, 2), 1)
  ignore(k.advance(2))
  assert_eq(k.completion(1), -2)
  ignore(k.receive(2, 0, 0))
  assert_eq(k.received(2), 43)
  assert_eq(k.queue_size(0), 0)
}

///|
test "transitive priority inheritance releases on timeout and rejects cycles" {
  let k = Kernel::new()
  ignore(k.create(1, 1))
  ignore(k.create(2, 5))
  ignore(k.create(3, 10))
  ignore(k.mutex(0))
  ignore(k.mutex(1))
  ignore(k.lock(3, 0, -1))
  ignore(k.lock(2, 1, -1))
  assert_eq(k.lock(2, 0, -1), 1)
  assert_eq(k.lock(1, 1, 2), 1)
  assert_eq(k.priority(3), 1)
  assert_eq(k.priority(2), 1)
  assert_eq(k.lock(3, 1, -1), -5)
  ignore(k.advance(2))
  assert_eq(k.priority(3), 5)
  ignore(k.unlock(3, 0))
  assert_eq(k.owner(0), 2)
  assert_eq(k.priority(3), 10)
}

///|
test "timeout wrapping and same-tick token conservation" {
  let k = Kernel::new()
  ignore(k.create(1, 1))
  ignore(k.semaphore(0, 0, 1))
  k.clock = 4294967294L
  assert_eq(k.take(1, 0, 3), 1)
  ignore(k.advance(2))
  assert_eq(k.task_state(1), 3)
  ignore(k.advance(1))
  assert_eq(k.now(), 1L)
  assert_eq(k.completion(1), -2)
  assert_eq(k.give(0), 0)
  assert_eq(k.semaphore_count(0), 1)
  assert_eq(k.take(1, 0, 0), 0)
  assert_eq(k.semaphore_count(0), 0)
}

///|
test "exit cancels pending IPC and transfers owned mutexes before task reuse" {
  let k = Kernel::new()
  ignore(k.create(1, 10))
  ignore(k.create(2, 1))
  ignore(k.create(3, 5))
  ignore(k.mutex(0))
  ignore(k.queue(0, 1))
  ignore(k.lock(1, 0, -1))
  ignore(k.lock(2, 0, -1))
  assert_eq(k.priority(1), 1)
  ignore(k.send(3, 0, 11, 0))
  ignore(k.send(3, 0, 12, -1))
  assert_eq(k.exit_task(3), 0)
  assert_eq(k.receive(1, 0, 0), 0)
  assert_eq(k.received(1), 11)
  assert_eq(k.queue_size(0), 0)
  assert_eq(k.exit_task(1), 0)
  assert_eq(k.owner(0), 2)
  assert_eq(k.completion(2), 0)
  assert_eq(k.create(1, 7), 0)
  assert_eq(k.received(1), 0)
  assert_eq(k.priority(1), 7)
  assert_eq(k.unlock(1, 0), -4)
  assert_eq(k.unlock(2, 0), 0)
}

///|
test "resource validation and polling do not alter waiting tasks" {
  let k = Kernel::new()
  ignore(k.create(1, 1))
  ignore(k.create(2, 2))
  assert_eq(k.create(16, 1), -1)
  assert_eq(k.create(1, 1), -1)
  assert_eq(k.semaphore(0, 2, 1), -1)
  assert_eq(k.semaphore(0, 1, 1), 0)
  assert_eq(k.semaphore(0, 0, 2), -1)
  assert_eq(k.give(0), -3)
  assert_eq(k.take(1, 0, -2), -1)
  assert_eq(k.semaphore_count(0), 1)
  assert_eq(k.take(1, 0, 0), 0)
  assert_eq(k.take(1, 0, 0), -3)
  assert_eq(k.take(1, 0, -1), 1)
  assert_eq(k.take(1, 0, 0), -1)
  assert_eq(k.give(0), 0)
  assert_eq(k.task_state(1), 1)
  assert_eq(k.queue(0, 0), -1)
  assert_eq(k.queue(0, 16), 0)
  assert_eq(k.queue(0, 1), -1)
  assert_eq(k.receive(1, 0, 0), -3)
  assert_eq(k.mutex(0), 0)
  assert_eq(k.lock(1, 0, 0), 0)
  assert_eq(k.lock(1, 0, 0), -5)
  assert_eq(k.unlock(2, 0), -4)
  assert_eq(k.advance(-1), -1)
  assert_eq(k.sleep(2, 1000001), -1)
}

///|
test "all capacities bounded with direct receiver wake and highest-priority handoff" {
  let k = Kernel::new()
  for i in 0..<16 {
    assert_eq(k.create(i, 16 - i), 0)
  }
  for i in 0..<8 {
    assert_eq(k.semaphore(i, 0, 1), 0)
    assert_eq(k.mutex(i), 0)
  }
  for i in 0..<4 {
    assert_eq(k.queue(i, 16), 0)
  }
  for value in 0..<16 {
    assert_eq(k.send_isr(0, value), 0)
  }
  assert_eq(k.send_isr(0, 17), -3)
  for value in 0..<16 {
    assert_eq(k.receive(0, 0, 0), 0)
    assert_eq(k.received(0), value)
  }
  ignore(k.receive(1, 0, -1))
  ignore(k.receive(2, 0, -1))
  assert_eq(k.send_isr(0, 42), 0)
  assert_eq(k.received(2), 42)
  assert_eq(k.task_state(1), 3)
  assert_eq(k.task_state(2), 1)
  ignore(k.take(3, 0, -1))
  ignore(k.take(4, 0, -1))
  ignore(k.give(0))
  assert_eq(k.task_state(4), 1)
  assert_eq(k.task_state(3), 3)
}

///|
test "4096 mixed queue operations agree with independent FIFO state" {
  let k = Kernel::new()
  ignore(k.create(1, 1))
  ignore(k.queue(0, 7))
  let expected = FixedArray::make(7, 0)
  let mut count = 0
  let mut head = 0
  let mut seed = 17
  for step in 0..<4096 {
    seed = (seed * 109 + 89) % 65521
    if seed % 3 != 0 {
      let result = k.send_isr(0, step)
      if count == 7 {
        assert_eq(result, -3)
      } else {
        assert_eq(result, 0)
        expected[(head + count) % 7] = step
        count += 1
      }
    } else {
      let result = k.receive(1, 0, 0)
      if count == 0 {
        assert_eq(result, -3)
      } else {
        assert_eq(result, 0)
        assert_eq(k.received(1), expected[head])
        head = (head + 1) % 7
        count -= 1
      }
    }
    assert_eq(k.queue_size(0), count)
  }
}
