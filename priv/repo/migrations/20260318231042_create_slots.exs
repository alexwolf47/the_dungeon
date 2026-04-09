defmodule TheDungeon.Repo.Migrations.CreateSlots do
  use Ecto.Migration

  def change do
    create table(:slots, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :date, :date, null: false
      add :start_hour, :integer, null: false
      add :slot_type, :string, null: false
      add :bootcamp_name, :string
      add :max_participants, :integer, null: false, default: 1
      add :status, :string, null: false, default: "available"

      timestamps(type: :utc_datetime)
    end

    create unique_index(:slots, [:date, :start_hour, :slot_type])
    create index(:slots, [:date])
  end
end
