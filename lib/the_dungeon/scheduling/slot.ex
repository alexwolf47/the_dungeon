defmodule TheDungeon.Scheduling.Slot do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "slots" do
    field :date, :date
    field :start_hour, :integer
    field :slot_type, :string
    field :bootcamp_name, :string
    field :max_participants, :integer, default: 1
    field :status, :string, default: "available"

    has_many :bookings, TheDungeon.Scheduling.Booking

    timestamps(type: :utc_datetime)
  end

  def changeset(slot, attrs) do
    slot
    |> cast(attrs, [:date, :start_hour, :slot_type, :bootcamp_name, :max_participants, :status])
    |> validate_required([:date, :start_hour, :slot_type])
    |> validate_inclusion(:slot_type, ["pt", "bootcamp"])
    |> validate_inclusion(:start_hour, 0..23)
    |> validate_inclusion(:status, ["available", "cancelled"])
    |> validate_number(:max_participants, greater_than: 0)
    |> unique_constraint([:date, :start_hour, :slot_type])
  end

  def bootcamp_changeset(slot, attrs) do
    slot
    |> changeset(attrs)
    |> validate_required([:bootcamp_name])
    |> apply_default_max_participants()
  end

  defp apply_default_max_participants(changeset) do
    if get_field(changeset, :max_participants) == 1 do
      put_change(changeset, :max_participants, 8)
    else
      changeset
    end
  end
end
