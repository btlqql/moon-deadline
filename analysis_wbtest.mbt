///|
fn task(name : String, c : Int32, p : Int32, d : Int32) -> Task {
  { name, cost: c, period: p, deadline: d, jitter: 0, blocking: 0, }
}

///|
test "low utilization still misses a constrained deadline" {
  let tasks = [task("control", 2, 10, 2), task("sensor", 2, 20, 3)]
  let r = fixed_priority(tasks)
  assert_true(r[0].meets_deadline)
  assert_false(r[1].meets_deadline)
  assert_eq(r[1].bound, 4L)
  assert_true(simulate(tasks, 20).missed_tasks.contains(1))
  match edf_window(tasks, 20) {
    Some(w) => {
      assert_eq(w.interval, 3)
      assert_eq(w.demand, 4L)
    }
    None => fail("demand witness required")
  }
}

///|
test "critical instant recurrence and exact-boundary completion" {
  let tasks = [task("a", 1, 4, 4), task("b", 2, 5, 5), task("c", 2, 20, 20)]
  let r = fixed_priority(tasks)
  assert_eq(r[2].bound, 8L)
  assert_true(r[2].meets_deadline)
  assert_true(simulate(tasks, 100).missed_tasks.is_empty())
  assert_true(edf_window(tasks, 100) is None)
  assert_true(simulate([task("a", 2, 2, 2)], 2).missed_tasks.is_empty())
}

///|
test "jitter blocking and invalid assumptions" {
  let a : Task = {
    name: "a",
    cost: 1,
    period: 4,
    deadline: 4,
    jitter: 1,
    blocking: 0,
  }
  let b : Task = {
    name: "b",
    cost: 1,
    period: 10,
    deadline: 10,
    jitter: 2,
    blocking: 1,
  }
  assert_eq(fixed_priority([a, b])[1].bound, 5L)
  let rejected = try {
    ignore(simulate([a, b], 10))
    false
  } catch {
    _ => true
  }
  assert_true(rejected)
  let rejected = try {
    ignore(fixed_priority([task("a", 1, 1, 2)]))
    false
  } catch {
    _ => true
  }
  assert_true(rejected)
}
