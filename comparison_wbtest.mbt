///|
test "configuration comparison matches names across priority changes" {
  let before : Array[Task] = [
    { name: "slow", cost: 2, period: 10, deadline: 10, jitter: 0, blocking: 0, },
    { name: "urgent", cost: 1, period: 4, deadline: 2, jitter: 0, blocking: 0, },
  ]
  let result = compare(before, [before[1], before[0]])
  assert_false(result[1].before_feasible)
  assert_true(result[1].after_feasible)
  assert_eq(result[1].before_upper, None)
  assert_eq(result[1].slack_after, Some(1L))
  assert_true(
    try {
      ignore(compare(before, [before[0]]))
      false
    } catch {
      _ => true
    },
  )
}
