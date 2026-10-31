///|
pub(all) struct Assignment {
  order : Array[Int32]
  tasks : Array[Task]
}

// Audsley's lowest-priority-first assignment, restricted to independent,
// preemptive tasks with no blocking or release jitter. Input is never mutated.

///|
pub fn assign_priorities(tasks : Array[Task]) -> Assignment? raise ModelError {
  validate(tasks)
  if tasks.length() > 16 {
    raise ResourceLimit
  }
  for t in tasks {
    if t.jitter != 0 || t.blocking != 0 {
      raise InvalidModel
    }
  }
  let remaining : Array[Int32] = []
  for i in 0..<tasks.length() {
    remaining.push(i)
  }
  let low_first : Array[Int32] = []
  while !remaining.is_empty() {
    let mut selected = -1
    for index in 0..<remaining.length() {
      let candidate = remaining[index]
      let trial : Array[Task] = []
      for other in remaining {
        if other != candidate {
          trial.push(tasks[other])
        }
      }
      trial.push(tasks[candidate])
      let response = fixed_priority(trial)
      if response[response.length() - 1].meets_deadline {
        selected = index
        break
      }
    }
    if selected < 0 {
      return None
    }
    low_first.push(remaining[selected])
    ignore(remaining.remove(selected))
  }
  let order : Array[Int32] = []
  for i = low_first.length() - 1; i >= 0; i = i - 1 {
    order.push(low_first[i])
  }
  Some({ order, tasks: order.map(fn(i) { tasks[i] }), })
}

// Largest integer WCET for one task for which every task passes this RTA.
// The other budgets and priority order are fixed. None means even cost=1
// cannot make this complete model pass; this is not WCET measurement.

///|
pub fn maximum_cost(
  tasks : Array[Task],
  index : Int32,
) -> Int32? raise ModelError {
  validate(tasks)
  if index < 0 || index >= tasks.length() || tasks.length() > 16 {
    raise InvalidModel
  }
  let mut low = 1
  let mut high = tasks[index].deadline
  let mut best = 0
  while low <= high {
    let mid = low + (high - low) / 2
    let trial = tasks.copy()
    trial[index] = { ..tasks[index], cost: mid, }
    if fixed_priority(trial).all(fn(r) { r.meets_deadline }) {
      best = mid
      low = mid + 1
    } else {
      high = mid - 1
    }
  }
  if best == 0 {
    None
  } else {
    Some(best)
  }
}
