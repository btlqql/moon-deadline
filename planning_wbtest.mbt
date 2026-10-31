///|
test "Audsley rescues the wrong priority order and budget search respects all tasks" {
  let tasks : Array[Task] = [
    { name: "slow", cost: 2, period: 10, deadline: 10, jitter: 0, blocking: 0, },
    { name: "urgent", cost: 1, period: 4, deadline: 2, jitter: 0, blocking: 0, },
  ]
  assert_false(fixed_priority(tasks)[1].meets_deadline)
  guard assign_priorities(tasks) is Some(a) else { fail("assignment required") }
  assert_eq(a.order[0], 1)
  assert_true(fixed_priority(a.tasks).all(fn(r) { r.meets_deadline }))
  assert_eq(maximum_cost(a.tasks, 0), Some(2))
  assert_eq(tasks[0].name, "slow")
}

///|
test "no priority order can schedule overload" {
  let tasks : Array[Task] = [
    { name: "a", cost: 3, period: 4, deadline: 4, jitter: 0, blocking: 0, },
    { name: "b", cost: 3, period: 4, deadline: 4, jitter: 0, blocking: 0, },
  ]
  assert_true(assign_priorities(tasks) is None)
  assert_eq(maximum_cost(tasks, 1), Some(1))
}
