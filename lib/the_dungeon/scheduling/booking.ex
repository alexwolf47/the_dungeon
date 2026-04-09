defmodule TheDungeon.Scheduling.Booking do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "bookings" do
    field :status, :string, default: "confirmed"

    belongs_to :user, TheDungeon.Accounts.User
    belongs_to :slot, TheDungeon.Scheduling.Slot, type: :binary_id

    timestamps(type: :utc_datetime)
  end

  def changeset(booking, attrs) do
    booking
    |> cast(attrs, [:user_id, :slot_id, :status])
    |> validate_required([:user_id, :slot_id])
    |> validate_inclusion(:status, ["confirmed", "cancelled"])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:slot_id)
    |> unique_constraint([:user_id, :slot_id])
  end
end
