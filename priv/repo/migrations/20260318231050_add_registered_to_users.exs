defmodule TheDungeon.Repo.Migrations.AddRegisteredToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :registered, :boolean, null: false, default: false
    end
  end
end
