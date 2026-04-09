defmodule TheDungeon.Repo.Migrations.MakeProfileFieldsOptional do
  use Ecto.Migration

  def change do
    alter table(:profiles) do
      modify :preferred_contact_method, :string, null: true, from: {:string, null: false}
      modify :training_preference, :string, null: true, from: {:string, null: false}
    end
  end
end
