///|
let kernel : @rt.Kernel = @rt.Kernel::new()

///|
#export_name("rt_create")
pub fn create(id : Int32, p : Int32) -> Int32 {
  kernel.create(id, p)
}

///|
#export_name("rt_pick")
pub fn pick() -> Int32 {
  kernel.pick()
}

///|
#export_name("rt_tick")
pub fn tick() -> Int32 {
  kernel.advance(1)
}

///|
#export_name("rt_sleep")
pub fn sleep(id : Int32, ticks : Int32) -> Int32 {
  kernel.sleep(id, ticks)
}

///|
#export_name("rt_yield")
pub fn yield_task(id : Int32) -> Int32 {
  kernel.yield_task(id)
}

///|
#export_name("rt_exit")
pub fn exit_task(id : Int32) -> Int32 {
  kernel.exit_task(id)
}

///|
#export_name("rt_sem_create")
pub fn sem_create(id : Int32, count : Int32, max : Int32) -> Int32 {
  kernel.semaphore(id, count, max)
}

///|
#export_name("rt_take")
pub fn take(task : Int32, id : Int32, timeout : Int32) -> Int32 {
  kernel.take(task, id, timeout)
}

///|
#export_name("rt_give")
pub fn give(id : Int32) -> Int32 {
  kernel.give(id)
}

///|
#export_name("rt_mutex_create")
pub fn mutex_create(id : Int32) -> Int32 {
  kernel.mutex(id)
}

///|
#export_name("rt_lock")
pub fn lock(task : Int32, id : Int32, timeout : Int32) -> Int32 {
  kernel.lock(task, id, timeout)
}

///|
#export_name("rt_unlock")
pub fn unlock(task : Int32, id : Int32) -> Int32 {
  kernel.unlock(task, id)
}

///|
#export_name("rt_queue_create")
pub fn queue_create(id : Int32, cap : Int32) -> Int32 {
  kernel.queue(id, cap)
}

///|
#export_name("rt_send")
pub fn send(task : Int32, id : Int32, value : Int32, timeout : Int32) -> Int32 {
  kernel.send(task, id, value, timeout)
}

///|
#export_name("rt_receive")
pub fn receive(task : Int32, id : Int32, timeout : Int32) -> Int32 {
  kernel.receive(task, id, timeout)
}

///|
#export_name("rt_isr_send")
pub fn isr_send(id : Int32, value : Int32) -> Int32 {
  kernel.send_isr(id, value)
}

///|
#export_name("rt_result")
pub fn result(id : Int32) -> Int32 {
  kernel.completion(id)
}

///|
#export_name("rt_mail")
pub fn mail(id : Int32) -> Int32 {
  kernel.received(id)
}

///|
#export_name("rt_priority")
pub fn priority(id : Int32) -> Int32 {
  kernel.priority(id)
}

///|
#export_name("rt_state")
pub fn state(id : Int32) -> Int32 {
  kernel.task_state(id)
}

///|
#export_name("rt_clock")
pub fn clock() -> Int32 {
  kernel.now().to_int()
}

///|
#export_name("rt_switches")
pub fn switches() -> Int32 {
  kernel.switch_count()
}
