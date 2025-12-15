import argv
import gleam/int
import gleam/result
import scalable_simulator

pub fn main() -> Nil {
  // Parse command-line arguments: [num_users, num_subreddits]
  let args = argv.load().arguments

  let num_users = case args {
    [users, ..] -> int.parse(users) |> result.unwrap(10_000)
    _ -> 10_000
    // Default to 10K users
  }

  let num_subreddits = case args {
    [_, subreddits, ..] -> int.parse(subreddits) |> result.unwrap(10)
    _ -> 10
    // Default to 10 subreddits
  }

  // Run scalable simulation (short-lived processes like the 900K reference)
  let _result =
    scalable_simulator.run_scalable_simulation(num_users, num_subreddits)

  Nil
}
