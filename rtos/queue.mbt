///|
pub fn Kernel::queue(self : Kernel, id : Int32, capacity : Int32) -> Int32 {
  if id < 0 ||
    id >= 4 ||
    capacity < 1 ||
    capacity > 16 ||
    self.queue_cap[id] != 0 {
    return -1
  }
  self.queue_cap[id] = capacity
  0
}

///|
fn push_word(k : Kernel, id : Int32, value : Int32) -> Unit {
  let pos = (k.queue_head[id] + k.queue_count[id]) % k.queue_cap[id]
  k.queue_data[id * 16 + pos] = value
  k.queue_count[id] += 1
}

///|
pub fn Kernel::send(
  self : Kernel,
  task : Int32,
  id : Int32,
  value : Int32,
  timeout : Int32,
) -> Int32 {
  if !valid_task(self, task) ||
    !runnable(self, task) ||
    id < 0 ||
    id >= 4 ||
    self.queue_cap[id] == 0 ||
    timeout < -1 ||
    timeout > 1000000 {
    return -1
  }
  let receiver = waiter(self, 5, id)
  if receiver >= 0 {
    self.mail[receiver] = value
    wake(self, receiver, 0)
    self.result[task] = 0
    return 0
  }
  if self.queue_count[id] < self.queue_cap[id] {
    push_word(self, id, value)
    self.result[task] = 0
    return 0
  }
  self.wait_value[task] = value
  block(self, task, 4, id, timeout)
}
// External interrupt producer, bounded and nonblocking, with the same wake path.

///|
pub fn Kernel::send_isr(self : Kernel, id : Int32, value : Int32) -> Int32 {
  if id < 0 || id >= 4 || self.queue_cap[id] == 0 {
    return -1
  }
  let receiver = waiter(self, 5, id)
  if receiver >= 0 {
    self.mail[receiver] = value
    wake(self, receiver, 0)
    return 0
  }
  if self.queue_count[id] == self.queue_cap[id] {
    return -3
  }
  push_word(self, id, value)
  0
}

///|
pub fn Kernel::receive(
  self : Kernel,
  task : Int32,
  id : Int32,
  timeout : Int32,
) -> Int32 {
  if !valid_task(self, task) ||
    !runnable(self, task) ||
    id < 0 ||
    id >= 4 ||
    self.queue_cap[id] == 0 ||
    timeout < -1 ||
    timeout > 1000000 {
    return -1
  }
  if self.queue_count[id] > 0 {
    self.mail[task] = self.queue_data[id * 16 + self.queue_head[id]]
    self.queue_head[id] = (self.queue_head[id] + 1) % self.queue_cap[id]
    self.queue_count[id] -= 1
    let sender = waiter(self, 4, id)
    if sender >= 0 {
      push_word(self, id, self.wait_value[sender])
      wake(self, sender, 0)
    }
    self.result[task] = 0
    return 0
  }
  block(self, task, 5, id, timeout)
}

///|
pub fn Kernel::queue_size(self : Kernel, id : Int32) -> Int32 {
  if id < 0 || id >= 4 || self.queue_cap[id] == 0 {
    -1
  } else {
    self.queue_count[id]
  }
}
