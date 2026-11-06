// Return codes: 0 success, 1 blocked, -1 invalid, -2 timeout,
// -3 would block/full, -4 not owner, -5 recursive/cyclic mutex acquisition.
///|
fn recompute_priorities(k : Kernel) -> Unit {
  for i in 0..<16 {
    k.effective[i] = k.base[i]
  }
  // Fixed point propagates transitive inheritance over at most 16 tasks.
  for _ in 0..<16 {
    let mut changed = false
    for i in 0..<16 {
      if k.state[i] == 3 && k.wait_kind[i] == 3 {
        let owner = k.mutex_owner[k.wait_obj[i]]
        if owner >= 0 && k.effective[i] < k.effective[owner] {
          k.effective[owner] = k.effective[i]
          changed = true
        }
      }
    }
    if !changed {
      break
    }
  }
}

///|
pub fn Kernel::semaphore(
  self : Kernel,
  id : Int32,
  initial : Int32,
  maximum : Int32,
) -> Int32 {
  if id < 0 ||
    id >= 8 ||
    maximum < 1 ||
    maximum > 1000000 ||
    initial < 0 ||
    initial > maximum ||
    self.sem_max[id] != 0 {
    return -1
  }
  self.sem_count[id] = initial
  self.sem_max[id] = maximum
  0
}

///|
pub fn Kernel::take(
  self : Kernel,
  task : Int32,
  id : Int32,
  timeout : Int32,
) -> Int32 {
  if !valid_task(self, task) ||
    !runnable(self, task) ||
    id < 0 ||
    id >= 8 ||
    self.sem_max[id] == 0 ||
    timeout < -1 ||
    timeout > 1000000 {
    return -1
  }
  if self.sem_count[id] > 0 {
    self.sem_count[id] -= 1
    self.result[task] = 0
    return 0
  }
  block(self, task, 2, id, timeout)
}
// ISR-safe when called through the port's IRQ-masked entry. Never blocks.

///|
pub fn Kernel::give(self : Kernel, id : Int32) -> Int32 {
  if id < 0 || id >= 8 || self.sem_max[id] == 0 {
    return -1
  }
  let task = waiter(self, 2, id)
  if task >= 0 {
    wake(self, task, 0)
    return 0
  }
  if self.sem_count[id] == self.sem_max[id] {
    return -3
  }
  self.sem_count[id] += 1
  0
}

///|
pub fn Kernel::semaphore_count(self : Kernel, id : Int32) -> Int32 {
  if id < 0 || id >= 8 || self.sem_max[id] == 0 {
    -1
  } else {
    self.sem_count[id]
  }
}

///|
pub fn Kernel::mutex(self : Kernel, id : Int32) -> Int32 {
  if id < 0 || id >= 8 || self.mutex_owner[id] != -2 {
    return -1
  }
  self.mutex_owner[id] = -1
  0
}

///|
pub fn Kernel::lock(
  self : Kernel,
  task : Int32,
  id : Int32,
  timeout : Int32,
) -> Int32 {
  if !valid_task(self, task) ||
    !runnable(self, task) ||
    id < 0 ||
    id >= 8 ||
    self.mutex_owner[id] == -2 ||
    timeout < -1 ||
    timeout > 1000000 {
    return -1
  }
  let owner = self.mutex_owner[id]
  if owner < 0 {
    self.mutex_owner[id] = task
    self.result[task] = 0
    return 0
  }
  let mut cursor = owner
  for _ in 0..<16 {
    if cursor == task {
      return -5
    }
    if self.state[cursor] != 3 || self.wait_kind[cursor] != 3 {
      break
    }
    cursor = self.mutex_owner[self.wait_obj[cursor]]
    if cursor < 0 {
      break
    }
  }
  let result = block(self, task, 3, id, timeout)
  recompute_priorities(self)
  result
}

///|
pub fn Kernel::unlock(self : Kernel, task : Int32, id : Int32) -> Int32 {
  if !valid_task(self, task) || id < 0 || id >= 8 || self.mutex_owner[id] == -2 {
    return -1
  }
  if self.mutex_owner[id] != task {
    return -4
  }
  let next = waiter(self, 3, id)
  self.mutex_owner[id] = next
  if next >= 0 {
    wake(self, next, 0)
  }
  recompute_priorities(self)
  0
}

///|
pub fn Kernel::owner(self : Kernel, id : Int32) -> Int32 {
  if id < 0 || id >= 8 {
    -2
  } else {
    self.mutex_owner[id]
  }
}
