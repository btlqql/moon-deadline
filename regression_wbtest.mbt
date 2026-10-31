///|
test "comparison rejects changed identities instead of silently aligning rows" {
  let a : Task = {
    name: "a",
    cost: 1,
    period: 4,
    deadline: 4,
    jitter: 0,
    blocking: 0,
  }
  let b : Task = { ..a, name: "b", }
  assert_true(
    try {
      ignore(compare([a], [b]))
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      ignore(fixed_priority([a, a]))
      false
    } catch {
      _ => true
    },
  )
}

///|
test "jitter and blocking do not become a false finite response guarantee" {
  let a : Task = {
    name: "a",
    cost: 2,
    period: 10,
    deadline: 3,
    jitter: 1,
    blocking: 1,
  }
  let r = fixed_priority([a])[0]
  assert_false(r.meets_deadline)
  assert_eq(r.bound, 4L)
  assert_true(
    try {
      ignore(assign_priorities([a]))
      false
    } catch {
      _ => true
    },
  )
}
