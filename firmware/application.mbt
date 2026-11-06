///|
extern "C" fn operation(code : Int32, a : Int32, b : Int32, c : Int32) -> Int32 = "port_op"

///|
extern "C" fn now() -> Int32 = "port_now"

///|
extern "C" fn mode() -> Int32 = "port_mode"

///|
extern "C" fn busy(until : Int32) -> Int32 = "port_canary"

///|
extern "C" fn check(tag : Int32, value : Int32) -> Unit = "port_check"

///|
extern "C" fn mark(key : Int32, value : Int32) -> Unit = "port_mark"

///|
extern "C" fn read_mark(key : Int32) -> Int32 = "port_read_mark"

///|
extern "C" fn idle() -> Unit = "port_idle"

///|
extern "C" fn limit() -> Int32 = "port_limit"

///|
fn verify(tag : Int32, condition : Bool) -> Unit {
  check(tag, if condition { 1 } else { 0 })
}

// These are actual MoonBit task bodies executed on independent PSP stacks.

///|
#export_name("rt_application")
pub fn application(id : Int32) -> Unit {
  if id == 0 {
    idle()
    return
  }
  match mode() {
    1 =>
      if id == 2 {
        ignore(operation(1, 5, 0, 0))
        mark(0, now())
        verify(101, now() == 5)
      } else {
        let preserved = 1000 + id
        verify(102 + id, busy(40) == 1)
        verify(110 + id, preserved == 1000 + id)
        mark(id, 1)
        if id == 1 {
          verify(120, read_mark(0) == 5)
        }
      }
    2 =>
      if id == 1 {
        verify(201, operation(5, 0, -1, 0) == 0)
        mark(0, 1)
        while now() < 5 {

        }
        verify(202, operation(10, 1, 0, 0) == 1)
        mark(1, now())
        verify(203, operation(6, 0, 0, 0) == 0)
        verify(204, operation(10, 1, 0, 0) == 10)
      } else if id == 2 {
        ignore(operation(1, 1, 0, 0))
        while now() < 8 {

        }
        mark(2, now())
      } else {
        ignore(operation(1, 2, 0, 0))
        verify(205, read_mark(0) == 1)
        verify(206, operation(5, 0, 20, 0) == 0)
        mark(3, now())
        verify(207, now() == 5)
        verify(208, operation(6, 0, 0, 0) == 0)
      }
    3 =>
      if id == 1 {
        for i in 1..<21 {
          verify(301, operation(3, 0, -1, 0) == 0)
          verify(302, operation(7, 0, i, 10) == 0)
        }
      } else if id == 2 {
        for i in 1..<21 {
          verify(303, operation(8, 0, 10, 0) == 0)
          let value = operation(9, 0, 0, 0)
          verify(304, value == i)
          verify(305, operation(7, 1, value * 2, 10) == 0)
        }
      } else {
        for i in 1..<21 {
          verify(306, operation(8, 1, 10, 0) == 0)
          verify(307, operation(9, 0, 0, 0) == i * 2)
          mark(0, i)
        }
      }
    4 =>
      if id == 1 {
        verify(401, operation(3, 0, 3, 0) == -2)
        verify(402, operation(3, 0, 0, 0) == 0)
        verify(403, operation(7, 0, 7, 0) == 0)
        verify(404, operation(7, 0, 8, 2) == -2)
        mark(0, 1)
      } else {
        ignore(operation(1, 6, 0, 0))
        verify(405, operation(8, 0, 0, 0) == 0)
        verify(406, operation(9, 0, 0, 0) == 7)
        verify(407, operation(8, 0, 2, 0) == -2)
        verify(408, operation(8, 0, 0, 0) == 0)
        verify(409, operation(9, 0, 0, 0) == 99)
        mark(1, 1)
      }
    5 => {
      verify(500 + id, busy(limit() - 2) == 1)
      mark(id, 1)
    }
    _ => verify(999, false)
  }
}
