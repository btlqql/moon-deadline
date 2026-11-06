// Fixed capacities: 16 tasks, 8 semaphores/mutexes, 4 queues x 16 words.
// Lower numeric priority runs first. Every mutation must be serialized by HAL.
///|
pub struct Kernel {
  state : FixedArray[Int32]
  base : FixedArray[Int32]
  effective : FixedArray[Int32]
  ready : FixedArray[Int64]
  wait_kind : FixedArray[Int32]
  wait_obj : FixedArray[Int32]
  wait_value : FixedArray[Int32]
  deadline : FixedArray[Int64]
  timed : FixedArray[Int32]
  result : FixedArray[Int32]
  mail : FixedArray[Int32]
  sem_count : FixedArray[Int32]
  sem_max : FixedArray[Int32]
  mutex_owner : FixedArray[Int32]
  queue_cap : FixedArray[Int32]
  queue_head : FixedArray[Int32]
  queue_count : FixedArray[Int32]
  queue_data : FixedArray[Int32]
  mut current : Int32
  mut clock : Int64
  mut serial : Int64
  mut switches : Int32
}

///|
pub fn Kernel::new() -> Kernel {
  {
    state: FixedArray::make(16, 0),
    base: FixedArray::make(16, 31),
    effective: FixedArray::make(16, 31),
    ready: FixedArray::make(16, 0L),
    wait_kind: FixedArray::make(16, 0),
    wait_obj: FixedArray::make(16, -1),
    wait_value: FixedArray::make(16, 0),
    deadline: FixedArray::make(16, 0L),
    timed: FixedArray::make(16, 0),
    result: FixedArray::make(16, 0),
    mail: FixedArray::make(16, 0),
    sem_count: FixedArray::make(8, 0),
    sem_max: FixedArray::make(8, 0),
    mutex_owner: FixedArray::make(8, -2),
    queue_cap: FixedArray::make(4, 0),
    queue_head: FixedArray::make(4, 0),
    queue_count: FixedArray::make(4, 0),
    queue_data: FixedArray::make(64, 0),
    current: -1,
    clock: 0L,
    serial: 0L,
    switches: 0,
  }
}

///|
fn valid_task(k : Kernel, id : Int32) -> Bool {
  id >= 0 && id < 16 && k.state[id] > 0 && k.state[id] != 4
}

///|
fn runnable(k : Kernel, id : Int32) -> Bool {
  k.state[id] == 1 || k.state[id] == 2
}

///|
fn enqueue(k : Kernel, id : Int32) -> Unit {
  k.serial += 1L
  k.ready[id] = k.serial
  k.state[id] = 1
}

///|
fn wake(k : Kernel, id : Int32, result : Int32) -> Unit {
  k.wait_kind[id] = 0
  k.wait_obj[id] = -1
  k.timed[id] = 0
  k.result[id] = result
  enqueue(k, id)
}

///|
fn block(
  k : Kernel,
  id : Int32,
  kind : Int32,
  obj : Int32,
  timeout : Int32,
) -> Int32 {
  // timeout -1=infinite, 0=poll, positive=relative ticks (< half wrap range).
  if timeout == 0 {
    return -3
  }
  if timeout < -1 || timeout > 1000000 {
    return -1
  }
  k.state[id] = 3
  k.wait_kind[id] = kind
  k.wait_obj[id] = obj
  k.result[id] = 1
  k.timed[id] = if timeout > 0 { 1 } else { 0 }
  if timeout > 0 {
    k.deadline[id] = (k.clock + timeout.to_int64()) % 4294967296L
  }
  1
}

///|
pub fn Kernel::create(self : Kernel, id : Int32, priority : Int32) -> Int32 {
  if id < 0 ||
    id >= 16 ||
    priority < 0 ||
    priority > 31 ||
    (self.state[id] != 0 && self.state[id] != 4) {
    return -1
  }
  self.base[id] = priority
  self.effective[id] = priority
  self.wait_kind[id] = 0
  self.timed[id] = 0
  self.wait_obj[id] = -1
  self.wait_value[id] = 0
  self.deadline[id] = 0L
  self.result[id] = 0
  self.mail[id] = 0
  enqueue(self, id)
  0
}

///|
pub fn Kernel::pick(self : Kernel) -> Int32 {
  let mut best = -1
  for i in 0..<16 {
    if runnable(self, i) &&
      (
        best < 0 ||
        self.effective[i] < self.effective[best] ||
        (
          self.effective[i] == self.effective[best] &&
          self.ready[i] < self.ready[best]
        )
      ) {
      best = i
    }
  }
  if best != self.current {
    if self.current >= 0 && self.state[self.current] == 2 {
      self.state[self.current] = 1
    }
    self.switches += 1
    self.current = best
  }
  if best >= 0 {
    self.state[best] = 2
  }
  best
}

///|
pub fn Kernel::yield_task(self : Kernel, id : Int32) -> Int32 {
  if !valid_task(self, id) || !runnable(self, id) {
    return -1
  }
  enqueue(self, id)
  0
}

///|
pub fn Kernel::sleep(self : Kernel, id : Int32, ticks : Int32) -> Int32 {
  if !valid_task(self, id) || !runnable(self, id) || ticks < 0 {
    return -1
  }
  if ticks == 0 {
    return self.yield_task(id)
  }
  block(self, id, 1, -1, ticks)
}

///|
pub fn Kernel::advance(self : Kernel, ticks : Int32) -> Int32 {
  if ticks < 0 || ticks > 1000000 {
    return -1
  }
  self.clock = (self.clock + ticks.to_int64()) % 4294967296L
  for i in 0..<16 {
    if self.state[i] == 3 &&
      self.timed[i] == 1 &&
      (self.clock - self.deadline[i] + 4294967296L) % 4294967296L < 2147483648L {
      let status = if self.wait_kind[i] == 1 { 0 } else { -2 }
      wake(self, i, status)
    }
  }
  recompute_priorities(self)
  if ticks > 0 && self.current >= 0 && self.state[self.current] == 2 {
    enqueue(self, self.current)
  }
  0
}

///|
pub fn Kernel::now(self : Kernel) -> Int64 {
  self.clock
}

///|
pub fn Kernel::running(self : Kernel) -> Int32 {
  self.current
}

///|
pub fn Kernel::task_state(self : Kernel, id : Int32) -> Int32 {
  if id < 0 || id >= 16 {
    -1
  } else {
    self.state[id]
  }
}

///|
pub fn Kernel::priority(self : Kernel, id : Int32) -> Int32 {
  if !valid_task(self, id) {
    -1
  } else {
    self.effective[id]
  }
}

///|
pub fn Kernel::completion(self : Kernel, id : Int32) -> Int32 {
  if id < 0 || id >= 16 {
    -1
  } else {
    self.result[id]
  }
}

///|
pub fn Kernel::received(self : Kernel, id : Int32) -> Int32 {
  if id < 0 || id >= 16 {
    0
  } else {
    self.mail[id]
  }
}

///|
pub fn Kernel::switch_count(self : Kernel) -> Int32 {
  self.switches
}

// Internal bounded scan handles the same wait ordering for IPC and mutexes.

///|
fn waiter(k : Kernel, kind : Int32, obj : Int32) -> Int32 {
  let mut best = -1
  for i in 0..<16 {
    if k.state[i] == 3 &&
      k.wait_kind[i] == kind &&
      k.wait_obj[i] == obj &&
      (
        best < 0 ||
        k.effective[i] < k.effective[best] ||
        (k.effective[i] == k.effective[best] && k.ready[i] < k.ready[best])
      ) {
      best = i
    }
  }
  best
}

///|
pub fn Kernel::exit_task(self : Kernel, id : Int32) -> Int32 {
  if !valid_task(self, id) {
    return -1
  }
  self.state[id] = 4
  self.wait_kind[id] = 0
  self.timed[id] = 0
  for m in 0..<8 {
    if self.mutex_owner[m] == id {
      let next = waiter(self, 3, m)
      self.mutex_owner[m] = next
      if next >= 0 {
        wake(self, next, 0)
      }
    }
  }
  recompute_priorities(self)
  0
}
