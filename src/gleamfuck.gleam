import gleam/io
import gleam/list
import gleam/result
import gleam/string
import tape.{type Tape}

const debug = False

fn debug_log(msg: a) {
  case debug {
    True -> {
      io.debug(msg)
      Nil
    }
    False -> Nil
  }
}

fn debug_log_interpreter(
  name: String,
  program: Program,
  tape: Tape,
  stack: Stack,
) {
  debug_log(#(
    name,
    string.join(program, ""),
    tape,
    list.map(stack, fn(x) { string.join(x, "") }),
  ))
}

@external(javascript, "./ffi.mjs", "get_input")
fn get_input() -> String

type Interpreter =
  fn(Program, Tape, Stack) -> ProgramResult

type Inst =
  String

type Program =
  List(Inst)

type ProgramResult =
  Result(Nil, String)

type Stack =
  List(Program)

fn add(program: Program, tape: Tape, stack: Stack) -> ProgramResult {
  debug_log_interpreter("add", program, tape, stack)
  interpret(program, tape.inc(tape), stack)
}

fn sub(program: Program, tape: Tape, stack: Stack) -> ProgramResult {
  debug_log_interpreter("sub", program, tape, stack)
  interpret(program, tape.dec(tape), stack)
}

fn right(program: Program, tape: Tape, stack: Stack) -> ProgramResult {
  debug_log_interpreter("right", program, tape, stack)
  interpret(program, tape.right(tape), stack)
}

fn left(program: Program, tape: Tape, stack: Stack) -> ProgramResult {
  debug_log_interpreter("left", program, tape, stack)
  interpret(program, tape.left(tape), stack)
}

fn print(program: Program, tape: Tape, stack: Stack) -> ProgramResult {
  debug_log_interpreter("print", program, tape, stack)
  tape
  |> tape.get
  |> string.utf_codepoint
  |> result.map(fn(x) { [x] })
  |> result.unwrap(string.to_utf_codepoints("�"))
  |> string.from_utf_codepoints
  |> io.print

  interpret(program, tape, stack)
}

fn input(program: Program, tape: Tape, stack: Stack) -> ProgramResult {
  debug_log_interpreter("input", program, tape, stack)
  let tape =
    get_input()
    |> string.to_graphemes
    |> list.first
    |> result.map(fn(grapheme) {
      grapheme
      |> string.to_utf_codepoints
      |> list.first
      |> result.map(fn(codepoint) { string.utf_codepoint_to_int(codepoint) })
      |> result.unwrap(0)
    })
    |> result.unwrap(0)
    |> tape.set(tape, _)

  interpret(program, tape, stack)
}

fn skip(program: Program, seen: Int) -> Result(Program, Nil) {
  debug_log(#("skip", string.join(program, ""), seen))
  case program, seen {
    [], _ -> Error(Nil)
    ["]", ..rest], 0 -> Ok(rest)
    ["[", ..rest], _ -> skip(rest, seen + 1)
    ["]", ..rest], _ -> skip(rest, seen - 1)
    [_, ..rest], _ -> skip(rest, seen)
  }
}

fn bra(program: Program, tape: Tape, stack: Stack) -> ProgramResult {
  debug_log_interpreter("bra", program, tape, stack)
  case program, tape.get(tape) {
    [], _ -> Error("[ERROR]: unmatched '[' detected.")
    _, 0 ->
      case skip(program, 0) {
        Ok(next) -> interpret(next, tape, stack)
        Error(Nil) -> Error("[ERROR]: unmatched '[' detected.")
      }
    _, _ -> interpret(program, tape, [program, ..stack])
  }
}

fn ket(program: Program, tape: Tape, stack: Stack) -> ProgramResult {
  debug_log_interpreter("ket", program, tape, stack)
  case tape.get(tape), stack {
    _, [] -> Error("[ERROR]: unmatched ']' detected.")
    0, [_, ..rest] -> interpret(program, tape, rest)
    _, [top, ..] -> interpret(top, tape, stack)
  }
}

fn decode(inst: Inst) -> Interpreter {
  debug_log(#("decode", inst))
  case inst {
    "+" -> add
    "-" -> sub
    ">" -> right
    "<" -> left
    "." -> print
    "," -> input
    "[" -> bra
    "]" -> ket
    _ -> interpret
  }
}

fn interpret(program: Program, tape: Tape, stack: Stack) -> ProgramResult {
  debug_log_interpreter("interpret", program, tape, stack)
  case program {
    [] -> Ok(Nil)
    [inst, ..rest] -> decode(inst)(rest, tape, stack)
  }
}

fn run(program: String) {
  case interpret(string.to_graphemes(program), tape.new(100), []) {
    Ok(Nil) -> Nil
    Error(msg) -> io.println_error("\n\n" <> msg)
  }
}

pub fn main() {
  let program =
    "++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++."
  run(program)
}
