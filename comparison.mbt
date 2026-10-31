///|
pub(all) struct TaskChange {
  name : String
  before_feasible : Bool
  after_feasible : Bool
  before_upper : Int64?
  after_upper : Int64?
  slack_before : Int64?
  slack_after : Int64?
}

// Match configurations by stable task name, independently of priority order.
// Only true converged bounds participate in slack calculations.

///|
pub fn compare(
  before : Array[Task],
  after : Array[Task],
) -> Array[TaskChange] raise ModelError {
  let old = fixed_priority(before)
  let current = fixed_priority(after)
  if before.length() != after.length() {
    raise InvalidModel
  }
  let out : Array[TaskChange] = []
  for i in 0..<before.length() {
    let mut index = -1
    for j in 0..<after.length() {
      if before[i].name == after[j].name {
        index = j
        break
      }
    }
    if index < 0 {
      raise InvalidModel
    }
    let a = old[i]
    let b = current[index]
    out.push({
      name: a.name,
      before_feasible: a.meets_deadline,
      after_feasible: b.meets_deadline,
      before_upper: if a.meets_deadline {
        Some(a.bound)
      } else {
        None
      },
      after_upper: if b.meets_deadline {
        Some(b.bound)
      } else {
        None
      },
      slack_before: if a.meets_deadline {
        Some(before[i].deadline.to_int64() - a.bound)
      } else {
        None
      },
      slack_after: if b.meets_deadline {
        Some(after[index].deadline.to_int64() - b.bound)
      } else {
        None
      },
    })
  }
  out
}
