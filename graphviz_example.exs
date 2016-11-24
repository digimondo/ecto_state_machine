
# Generate and write Grpahviz file.
IO.puts "ESM Config:"
dot = Dummy.User.esm_config(:rules)
  |> IO.inspect
  |> EctoStateMachine.config_to_dot
File.write!("dummy_user_rules.gv", dot)

# Running dot to create PND
System.cmd("dot", ["-Tpng", "dummy_user_rules.gv", "-o", "dummy_user_rules.png"])
