defmodule TheDungeon.Repo.Migrations.CreateBookings do
  use Ecto.Migration

  def change do
    create table(:bookings, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :slot_id, references(:slots, type: :binary_id, on_delete: :delete_all), null: false
      add :status, :string, null: false, default: "confirmed"

      timestamps(type: :utc_datetime)
    end

    create unique_index(:bookings, [:user_id, :slot_id])
    create index(:bookings, [:slot_id])
  end
end
