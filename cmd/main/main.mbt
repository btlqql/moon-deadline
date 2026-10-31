///|
extern "js" fn read_input(path : String) -> String =
  #| p => {const f=process.getBuiltinModule('fs'); const s=f.statSync(p); if(s.size>16000000)throw Error('input exceeds 16 MB');return f.readFileSync(p,'utf8');}

///|
extern "js" fn status(code : Int32) -> Unit =
  #| n => {process.exitCode=n;}

///|
fn field(j : Json, name : String) -> Json raise {
  guard j is Object(o) else { fail("expected object") }
  guard o.get(name) is Some(v) else { fail("missing field " + name) }
  v
}

///|
fn arr(j : Json) -> Array[Json] raise {
  guard j is Array(a) else { fail("expected array") }
  a
}

///|
fn num(j : Json) -> Double raise {
  guard j is Number(n, ..) else { fail("expected number") }
  if n != n || n - n != 0.0 {
    fail("nonfinite number")
  }
  n
}

///|
fn integer(j : Json) -> Int32 raise {
  let n = num(j)
  if n < -1000000.0 || n > 1000000.0 || n.to_int().to_double() != n {
    fail("expected bounded integer")
  }
  n.to_int()
}

///|
fn main {
  try {
    let args = @env.args()
    if args.length() < 3 {
      fail("usage: moon run cmd/main --target js -- request.json")
    }
    let request = @json.parse(read_input(args[args.length() - 1]))
    println(execute(request).stringify())
  } catch {
    error => {
      println(
        Json::object({ "ok": Json(false), "error": Json(error.to_string()) }).stringify(),
      )
      status(1)
    }
  }
}

///|
fn execute(j : Json) -> Json raise {
  let tasks = parse_tasks(field(j, "tasks"))
  let horizon = integer(field(j, "horizon"))
  let response = @core.fixed_priority(tasks).map(fn(r) {
    Json::object({
      "name": Json(r.name),
      "bound": Json(r.bound),
      "response_upper_bound": if r.meets_deadline {
        Json(r.bound)
      } else {
        Json::null()
      },
      "exceeded_deadline_iterate": if r.meets_deadline {
        Json::null()
      } else {
        Json(r.bound)
      },
      "meets_deadline": Json(r.meets_deadline),
      "iterations": Json(r.iterations),
    })
  })
  // RTA accepts jitter/blocking; simulation and EDF window require zero.
  let simple = tasks.all(fn(t) { t.jitter == 0 && t.blocking == 0 })
  let simulation = if simple {
    let s = @core.simulate(tasks, horizon)
    Json::object({
      "missed_tasks": Json(s.missed_tasks),
      "trace": Json(s.ticks.map(fn(t) { t.task })),
      "simulated_until": Json(s.ticks.length()),
      "stopped_early": Json(s.ticks.length() < horizon),
    })
  } else {
    Json::null()
  }
  let demand = if simple {
    match @core.edf_window(tasks, horizon) {
      None => Json::null()
      Some(w) =>
        Json::object({ "interval": Json(w.interval), "demand": Json(w.demand) })
    }
  } else {
    Json::null()
  }
  let planning = if j is Object(fields) && fields.get("optimize") is Some(True) {
    let assignment = match @core.assign_priorities(tasks) {
      None => Json::null()
      Some(a) =>
        Json::object({
          "order": Json(a.order),
          "names": Json(a.tasks.map(fn(t) { t.name })),
          "responses": Json(
            @core.fixed_priority(a.tasks).map(fn(r) { r.bound }),
          ),
        })
    }
    let budgets : Array[Json] = []
    for i in 0..<tasks.length() {
      budgets.push(
        match @core.maximum_cost(tasks, i) {
          None => Json::null()
          Some(v) => Json(v)
        },
      )
    }
    Json::object({
      "assignment": assignment,
      "maximum_cost_in_original_order": Json(budgets),
    })
  } else {
    Json::null()
  }
  let comparison = if j is Object(fields) && fields.get("before") is Some(old) {
    Json(
      @core.compare(parse_tasks(old), tasks).map(fn(c) {
        Json::object({
          "name": Json(c.name),
          "before_feasible": Json(c.before_feasible),
          "after_feasible": Json(c.after_feasible),
          "before_upper": Json(c.before_upper),
          "after_upper": Json(c.after_upper),
          "slack_before": Json(c.slack_before),
          "slack_after": Json(c.slack_after),
        })
      }),
    )
  } else {
    Json::null()
  }
  Json::object({
    "ok": Json(true),
    "response": Json(response),
    "simulation": simulation,
    "edf_window_witness": demand,
    "horizon": Json(horizon),
    "window_only": Json(true),
    "planning": planning,
    "comparison": comparison,
  })
}

///|
fn parse_tasks(j : Json) -> Array[@core.Task] raise {
  let tasks : Array[@core.Task] = []
  for item in arr(j) {
    guard field(item, "name") is String(name) else {
      fail("expected task name")
    }
    tasks.push({
      name,
      cost: integer(field(item, "cost")),
      period: integer(field(item, "period")),
      deadline: integer(field(item, "deadline")),
      jitter: integer(field(item, "jitter")),
      blocking: integer(field(item, "blocking")),
    })
  }
  tasks
}
