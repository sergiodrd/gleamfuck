import gleam/list

pub opaque type Tape {
  Tape(l: List(Int), rc: List(Int))
}

pub fn new(size: Int) -> Tape {
  Tape(l: [], rc: list.repeat(0, times: size))
}

pub fn inc(tape: Tape) -> Tape {
  case tape.rc {
    [] ->
      panic as "gleamfuck panic!!: internal representation of tape is invalid"
    [x, ..rest] -> Tape(l: tape.l, rc: [x + 1, ..rest])
  }
}

pub fn dec(tape: Tape) -> Tape {
  case tape.rc {
    [] ->
      panic as "gleamfuck panic!!: internal representation of tape is invalid"
    [x, ..rest] -> Tape(l: tape.l, rc: [x - 1, ..rest])
  }
}

pub fn left(tape: Tape) -> Tape {
  case tape.l {
    [] -> tape
    [x, ..rest] -> Tape(l: rest, rc: [x, ..tape.rc])
  }
}

pub fn right(tape: Tape) -> Tape {
  case tape.rc {
    [] ->
      panic as "gleamfuck panic!!: internal representation of tape is invalid"
    [x, ..rest] -> Tape(l: [x, ..tape.l], rc: rest)
  }
}

pub fn get(tape: Tape) -> Int {
  case tape.rc {
    [] ->
      panic as "gleamfuck panic!!: internal representation of tape is invalid"
    [x, ..] -> x
  }
}

pub fn set(tape: Tape, value: Int) -> Tape {
  case tape.rc {
    [] ->
      panic as "gleamfuck panic!!: internal representation of tape is invalid"
    [_, ..rest] -> Tape(l: tape.l, rc: [value, ..rest])
  }
}
