///|
/// Undo logs for tracking changes in a data structure.
pub enum Undo[T] {
  NewElem(Int)
  SetElem(Int, T)
}

///|
typealias Int as Snapshot

///|
pub fn[T] newElem(index : Int) -> Undo[T] {
  NewElem(index)
}

///|
pub fn[T] setElem(index : Int, value : T) -> Undo[T] {
  SetElem(index, value)
}

///|
/// UndoLogs is a structure that keeps track of changes made to a data structure.
pub struct UndoLogs[T] {
  logs : Array[Undo[T]]
  mut num_open_snapshots : Snapshot
}

///|
pub fn[T] new(capacity~ : Int = 0) -> UndoLogs[T] {
  { logs: Array::new(capacity~), num_open_snapshots: 0 }
}

///|
pub fn[T] from_iter(iter : Iter[Undo[T]], capacity~ : Int = 0) -> UndoLogs[T] {
  let logs = new(capacity~)
  logs.extend(iter)
  logs
}

///|
/// Checks UndoLogs for an open snapshot.
/// Returns true if there is at least one open snapshot.
/// 
/// Example:
/// 
/// ```moonbit
/// test "UndoLogs::in_snapshot" {
///   let logs = new()
///   logs.push(newElem(0))
///   logs.push(setElem(1, "test"))
///   assert_false!(logs.in_snapshot())
///   let _ = logs.start_snapshot()
///   assert_true!(logs.in_snapshot())
/// }
/// ```
pub fn[T] in_snapshot(self : UndoLogs[T]) -> Bool {
  self.num_open_snapshots > 0
}

///|
/// Returns the number of actions in the undo log.
/// 
/// Example:
/// 
/// ```moonbit
/// test "UndoLogs::length" {
///   let logs = new()
///   logs.push(newElem(0))
///   logs.push(setElem(1, "test"))
///   assert_eq!(logs.length(), 2)
/// }
pub fn[T] length(self : UndoLogs[T]) -> Int {
  self.logs.length()
}

///|
/// Returns the number of open snapshots.
/// 
/// Example:
/// 
/// ```moonbit
/// test "num_open_snapshots" {
///   let logs = new()
///   let _ = logs.start_snapshot()
///   assert_true!(logs.num_open_snapshots() == 1)
///   logs.push(newElem(0))
///   let s1 = logs.start_snapshot()
///   logs.push(setElem(1, "test"))
///   logs.commit(s1)
/// }
/// ```
pub fn[T] num_open_snapshots(self : UndoLogs[T]) -> Int {
  self.num_open_snapshots
}

///|
/// Pushes a new undo log entry onto the logs.
/// 
/// Example:
/// 
/// ```moonbit
/// test "UndoLogs::push" {
///   let logs = new()
///   logs.push(newElem(0))
///   logs.push(setElem(1, "test"))
///   assert_eq!(logs.length(), 2)
/// }
/// ```
pub fn[T] push(self : UndoLogs[T], log : Undo[T]) -> Unit {
  self.logs.push(log)
}

///|
/// Clears the undo logs and resets open snapshots.
/// 
/// Example:
/// 
/// ```moonbit
/// test "UndoLogs::clear" {
///   let logs = new()
///   let _ = logs.start_snapshot()
///   logs.push(newElem(0))
///   let _ = logs.start_snapshot()
///   logs.push(setElem(1, "test"))
///   logs.clear()
///   assert_true!(logs.logs.length() == 0)
///   assert_true!(logs.num_open_snapshots == 0)
/// }
/// ```
pub fn[T] clear(self : UndoLogs[T]) -> Unit {
  self.logs.clear()
  self.num_open_snapshots = 0
}

///|
/// Extends the undo logs with an iterable of undo actions.
///
/// Example:
/// 
/// ```moonbit
///  let logs = new()
///  let new_logs = [newElem(0), setElem(1, "test")]
///  logs.extend(new_logs.iter())
///  assert_true!(logs.logs.length() == 2)
///  inspect!(logs.logs[0], content="NewElem(0)")
///  inspect!(logs.logs[1], content="SetElem(1, test)")
/// ```
pub fn[T] extend(self : UndoLogs[T], logs : Iter[Undo[T]]) -> Unit {
  logs.each(fn(log) { self.push(log) })
}

// Snapshots

///|
/// Return the actions since the given snapshot.
/// 
/// Example:
/// 
/// ```moonbit
/// test "UndoLogs::action_since_snapshot" {
///   let logs = new()
///   let s1 = logs.start_snapshot()
///   logs.push(newElem(0))
///   logs.push(setElem(1, "test"))
///   let actions = logs.action_since_snapshot(s1)
///   assert_eq!(actions.length(), 2)
///   inspect!(actions[0], content="NewElem(0)")
///   inspect!(actions[1], content="SetElem(1, test)")
/// }
/// ```
pub fn[T] action_since_snapshot(
  self : UndoLogs[T],
  snapshot : Snapshot
) -> ArrayView[Undo[T]] {
  self.logs[snapshot:]
}

///|
/// Checks if there are any changes since the given snapshot.
/// 
/// Example:
/// 
/// ```moonbit
/// test "UndoLogs::has_changes" {
///   let logs = new()
///   let s1 = logs.start_snapshot()
///   assert_false!(logs.has_changes(s1))
///   logs.push(setElem(2, "another_test"))
///   assert_true!(logs.has_changes(s1))
/// }
/// ```
pub fn[T] has_changes(self : UndoLogs[T], snapshot : Snapshot) -> Bool {
  self.action_since_snapshot(snapshot).length() > 0
}

///|
/// Starts a new snapshot and returns its identifier.
/// 
/// Example:
/// 
/// ```moonbit
/// test "UndoLogs::start_snapshot" {
///   let logs = new()
///   let s1 = logs.start_snapshot()
///   logs.push(newElem(0))
///   logs.push(setElem(1, "test"))
///   inspect!(logs.action_since_snapshot(s1), content="[NewElem(0), SetElem(1, test)]")
/// }
/// ```
pub fn[T] start_snapshot(self : UndoLogs[T]) -> Snapshot {
  self.num_open_snapshots += 1
  self.logs.length()
}

///|
/// Asserts that the given snapshot is valid.
fn[T] assert_valid_snapshot(self : UndoLogs[T], snapshot : Snapshot) -> Unit {
  guard self.logs.length() > snapshot else { abort("Invalid snapshot") }
  guard self.num_open_snapshots > 0 else { abort("No open snapshots") }
}

///|
/// Commits the current snapshot information. 
/// When the current snapshot is the root snapshot, it clears all logs.
/// 
/// Example:
/// 
/// ```moonbit
/// test "UndoLogs::commit" {
///   let logs = new()
///   let s1 = logs.start_snapshot()
///   logs.push(newElem(0))
///   logs.push(setElem(1, "test"))
///   logs.commit(s1)
///   assert_eq!(logs.length(), 0)
/// }
/// ```
pub fn[T] commit(self : UndoLogs[T], snapshot : Snapshot) -> Unit {
  self.assert_valid_snapshot(snapshot)
  if self.num_open_snapshots == 1 {
    // The root snapshot. It's safe to clear the undo log because
    // there's no snapshot further out that we might need to roll back to.
    guard snapshot == 0 else { abort("Invalid snapshot") }
    self.logs.clear()
  }
  self.num_open_snapshots -= 1
}

///|
/// Rolls back the undo logs to the given snapshot.
/// Returns the actions that were rolled back.
/// 
/// Example:
/// 
/// ```moonbit
/// test "UndoLogs::rollback_to" {
///   let logs = new()
///   let _ = logs.start_snapshot()
///   logs.push(newElem(0))
///   logs.push(setElem(1, "test"))
///   let s3 = logs.start_snapshot()
///   logs.push(setElem(3, "another_rollback_test"))
///   logs.push(newElem(4))
///   inspect!(
///     logs.rollback_to(s3),
///     content="[SetElem(3, another_rollback_test), NewElem(4)]",
///   )
/// }
/// ```
pub fn[T] rollback_to(
  self : UndoLogs[T],
  snapshot : Snapshot
) -> Array[Undo[T]] {
  self.assert_valid_snapshot(snapshot)
  let logs = self.action_since_snapshot(snapshot).to_array()
  for _ in 0..<logs.length() {
    let _ = self.pop()

  }
  logs
}

///|
/// Pops the last undo log entry from the logs.
/// 
/// Example:
/// 
/// ```moonbit
/// test "UndoLogs::pop" {
///   let logs = new()
///   logs.push(newElem(0))
///   logs.push(setElem(1, "test"))
///   let popped = logs.pop().unwrap()
///   assert_eq!(popped, setElem(1, "test"))
///   assert_eq!(logs.length(), 1)
/// }
/// ```
pub fn[T] pop(self : UndoLogs[T]) -> Undo[T]? {
  self.logs.pop()
}

///|
/// Returns the last undo log entry.
/// 
/// Example:
/// 
/// ```moonbit
/// test "UndoLogs::last" {
///   let logs = new()
///   logs.push(newElem(0))
///   logs.push(setElem(1, "test"))
///   let last = logs.last().unwrap()
///   assert_eq!(last, setElem(1, "test"))
/// }
/// ```
pub fn[T] last(self : UndoLogs[T]) -> Undo[T]? {
  self.logs.last()
}

///|
pub fn[T] iter(self : UndoLogs[T]) -> Iter[Undo[T]] {
  self.logs.iter()
}

///|
pub impl[T : Eq] Eq for Undo[T] with op_equal(self, other : Undo[T]) -> Bool {
  match (self, other) {
    (NewElem(index1), NewElem(index2)) => index1 == index2
    (SetElem(index1, value1), SetElem(index2, value2)) =>
      index1 == index2 && value1 == value2
    _ => false
  }
}

///|
pub impl[T : Show] Show for Undo[T] with to_string(self) {
  match self {
    NewElem(index) => "NewElem(" + index.to_string() + ")"
    SetElem(index, value) =>
      "SetElem(" + index.to_string() + ", " + value.to_string() + ")"
  }
}

///|
pub impl[T : Show] Show for Undo[T] with output(self, logger : &Logger) {
  logger.write_string(self.to_string())
}

///|
pub impl[T : Show] Show for UndoLogs[T] with output(self, logger : &Logger) {
  logger..write_iter(
    self.logs.iter(),
    prefix="UndoLogs[ ",
    suffix=" ]",
    sep=", ",
  )
}
