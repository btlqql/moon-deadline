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
  let tasks : Array[@core.Task] = []
  for item in arr(field(j, "tasks")) {
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
  let horizon = integer(field(j, "horizon"))
  let response = @core.fixed_priority(tasks).map(fn(r) {
    Json::object({
      "name": Json(r.name),
      "bound": Json(r.bound),
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
  Json::object({
    "ok": Json(true),
    "response": Json(response),
    "simulation": simulation,
    "edf_window_witness": demand,
    "horizon": Json(horizon),
    "window_only": Json(true),
  })
}
