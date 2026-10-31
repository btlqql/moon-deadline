///|
pub(all) suberror ModelError {
  InvalidModel
  ResourceLimit
}

// Array order is decreasing priority. All times use one caller-chosen unit.

///|
pub(all) struct Task {
  name : String
  cost : Int32
  period : Int32
  deadline : Int32
  jitter : Int32
  blocking : Int32
}

///|
pub(all) struct Response {
  name : String
  bound : Int64
  meets_deadline : Bool
  iterations : Array[Int64]
}

///|
fn validate(tasks : Array[Task]) -> Unit raise ModelError {
  if tasks.is_empty() || tasks.length() > 64 {
    raise InvalidModel
  }
  for i in 0..<tasks.length() {
    let t = tasks[i]
    if t.name.is_empty() ||
      t.cost <= 0 ||
      t.period <= 0 ||
      t.period > 1000000 ||
      t.deadline <= 0 ||
      t.deadline > t.period ||
      t.jitter < 0 ||
      t.jitter > t.deadline ||
      t.blocking < 0 ||
      t.blocking > 1000000 {
      raise InvalidModel
    }
    if t.cost > 1000000 {
      raise InvalidModel
    }
    for j in 0..<i {
      if tasks[j].name == t.name {
        raise InvalidModel
      }
    }
  }
}

// Sufficient bound with release jitter and externally justified blocking.
// For independent preemptive tasks with J=B=0 this is the classic exact RTA.

///|
pub fn fixed_priority(tasks : Array[Task]) -> Array[Response] raise ModelError {
  validate(tasks)
  let out : Array[Response] = []
  for i in 0..<tasks.length() {
    let task = tasks[i]
    let base = task.cost.to_int64() + task.blocking.to_int64()
    let mut w = base
    let steps = [w]
    let mut converged = false
    for _ in 0..<10000 {
      if w + task.jitter.to_int64() > task.deadline.to_int64() {
        break
      }
      let mut next = base
      for j in 0..<i {
        let hp = tasks[j]
        let p = hp.period.to_int64()
        next += (w + hp.jitter.to_int64() + p - 1L) / p * hp.cost.to_int64()
      }
      if next == w {
        converged = true
        break
      }
      steps.push(next)
      w = next
    }
    if !converged && w + task.jitter.to_int64() <= task.deadline.to_int64() {
      raise ResourceLimit
    }
    out.push({
      name: task.name,
      bound: w + task.jitter.to_int64(),
      meets_deadline: converged,
      iterations: steps,
    })
  }
  out
}

///|
pub(all) struct DemandWitness {
  interval : Int32
  demand : Int64
}

// A failing interval disproves EDF feasibility. None means only this window
// passed, unless a separately justified feasibility horizon was supplied.

///|
pub fn edf_window(
  tasks : Array[Task],
  horizon : Int32,
) -> DemandWitness? raise ModelError {
  validate(tasks)
  if horizon <= 0 || horizon > 1000000 {
    raise ResourceLimit
  }
  for t in tasks {
    if t.jitter != 0 || t.blocking != 0 {
      raise InvalidModel
    }
  }
  for time in 1..<(horizon + 1) {
    let mut demand = 0L
    for t in tasks {
      if time >= t.deadline {
        demand += ((time - t.deadline) / t.period + 1).to_int64() *
          t.cost.to_int64()
      }
    }
    if demand > time.to_int64() {
      return Some({ interval: time, demand, })
    }
  }
  None
}

///|
pub(all) struct Tick {
  time : Int32
  task : Int32 // -1 means idle
}

///|
pub(all) struct Simulation {
  ticks : Array[Tick]
  missed_tasks : Array[Int32]
}

// Synchronous periodic releases, fixed priority, no jitter/blocking.
// This is a concrete finite trace, never an all-time schedulability proof.

///|
pub fn simulate(
  tasks : Array[Task],
  horizon : Int32,
) -> Simulation raise ModelError {
  validate(tasks)
  if horizon <= 0 || horizon > 100000 {
    raise ResourceLimit
  }
  for t in tasks {
    if t.jitter != 0 || t.blocking != 0 {
      raise InvalidModel
    }
  }
  let remaining = Array::make(tasks.length(), 0)
  let due = Array::make(tasks.length(), 0)
  let misses : Array[Int32] = []
  let ticks : Array[Tick] = []
  for time in 0..<(horizon + 1) {
    for i in 0..<tasks.length() {
      if remaining[i] > 0 && due[i] == time && !misses.contains(i) {
        misses.push(i)
      }
    }
    if time == horizon {
      break
    }
    for i in 0..<tasks.length() {
      if time % tasks[i].period == 0 {
        // Once a deadline is missed retain a witness and stop this trace;
        // a single-slot queue must never silently discard overdue work.
        if remaining[i] > 0 {
          return { ticks, missed_tasks: misses, }
        }
        remaining[i] = tasks[i].cost
        due[i] = time + tasks[i].deadline
      }
    }
    let mut chosen = -1
    for i in 0..<tasks.length() {
      if remaining[i] > 0 {
        chosen = i
        break
      }
    }
    if chosen >= 0 {
      remaining[chosen] -= 1
    }
    ticks.push({ time, task: chosen, })
  }
  { ticks, missed_tasks: misses, }
}
