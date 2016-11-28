defmodule Dummy.User do
  use Dummy.Web, :model

  use EctoStateMachine,
    column: :rules,
    states: [:unconfirmed, :confirmed, :blocked, :admin],
    events: [
      [
        name:     :confirm,
        from:     [:unconfirmed],
        to:       :confirmed,
        callback: fn(model) -> Ecto.Changeset.change(model, confirmed_at: Ecto.DateTime.utc) end
      ], [
        name:     :block,
        from:     [:confirmed, :admin],
        to:       :blocked
      ], [
        name:     :make_admin,
        from:     [:confirmed],
        to:       :admin
      ]
    ]

  use EctoStateMachine,
    column: :level,
    states: [:beginner, :advanced, :expert],
    events: [
      [
        name:     :ascend_advanced,
        from:     [:beginner],
        to:       :advanced
      ], [
        name:     :ascend_expert,
        from:     [:advanced],
        to:       :expert
      ],
    ]

  schema "users" do
    field :rules, :string
    field :level, :string, default: "beginner"
  end
end
