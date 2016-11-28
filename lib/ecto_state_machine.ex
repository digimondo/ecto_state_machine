defmodule EctoStateMachine do
  defmacro __using__(opts) do
    column = Keyword.get(opts, :column, :state)
    states = Keyword.get(opts, :states)
    events = Keyword.get(opts, :events)
      |> Enum.map(fn(event) ->
        event
          |> Keyword.put(:is_custom_callback, Keyword.has_key?(event, :callback))
          |> Keyword.put_new(:callback, quote do: fn(model) -> model end)
      end)
      |> Enum.map(fn(event) ->
        Keyword.update!(event, :callback, &Macro.escape/1)
      end)

    quote bind_quoted: [states: states, events: events, column: column] do
      alias Ecto.Changeset

      events
      |> Enum.each(fn(event) ->
        unless event[:to] in states do
          raise "Target state :#{event[:to]} is not present in @states"
        end

        def unquote(event[:name])(model) do
          model
          |> Changeset.change(%{ unquote(column) => "#{unquote(event[:to])}" })
          |> unquote(event[:callback]).()
          |> unquote(:"validate_state_transition_#{column}")(unquote(event), model)
        end

        def unquote(:"can_#{event[:name]}?")(model) do
          :"#{Map.get(model, unquote(column))}" in unquote(event[:from])
        end
      end)

      defp unquote(:"validate_state_transition_#{column}")(changeset, event, model) do
        change = Map.get(model, unquote(column))

        if :"#{change}" in event[:from] do
          changeset
        else
          changeset
          |> Changeset.add_error(unquote(column),
            "You can't move state from :#{change} to :#{event[:to]}"
            )
        end
      end

      @doc "Returning the config from EctoStateMachine for given column atom."
      def esm_config(unquote(column)) do
        %{
          module: __MODULE__,
          column: unquote(column),
          states: unquote(states),
          events: unquote(events) |> Enum.map(&Enum.into(&1, %{})),
        }
      end
    end
  end

  @doc """
    Creating a GraphViz definition from a config given by esm_config.
  """
  def config_to_dot(%{module: module, column: column, states: states, events: events}) when states != [] do

    transition_strings = events
      |> Enum.flat_map(fn(%{from: states_from, name: transition_name, to: state_to, is_custom_callback: custom_callback}) ->
        states_from
          |> Enum.map(fn(state_from) ->
            {transition_name, state_from, state_to, custom_callback}
          end)
      end)
      |> Enum.map(fn({transition_name, state_from, state_to, custom_callback}) ->
        case custom_callback do
          true -> "#{state_from} -> #{state_to}  [style=\"bold\", label=< <B>#{transition_name}</B> >]"
          false -> "#{state_from} -> #{state_to}  [label=<#{transition_name}>]"
        end
      end)

    "digraph G {
      // initial node
      \"\" [shape=none];
      \"\" -> \"#{states |> List.first}\";

      // Transitions.
      #{transition_strings |> Enum.join(" ; ")}

      // title
      labelloc=\"t\";
      label=\"#{module} #{column}\";
    }"
  end

end
