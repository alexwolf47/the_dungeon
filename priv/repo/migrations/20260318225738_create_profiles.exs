defmodule TheDungeon.Repo.Migrations.CreateProfiles do
  use Ecto.Migration

  def change do
    create table(:profiles) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :full_name, :string, null: false
      add :phone_number, :string
      add :instagram_handle, :string
      add :preferred_contact_method, :string, null: false
      add :training_preference, :string, null: false
      add :primary_fitness_goals, :text
      add :areas_to_focus, :text
      add :personalised_meal_plan, :string
      add :current_fitness_level, :string
      add :training_frequency, :string
      add :available_days, {:array, :string}, default: []
      add :available_times, {:array, :string}, default: []
      add :medical_conditions, :text
      add :current_medications, :text
      add :prior_trainer_experience, :text
      add :additional_fitness_info, :text
      add :training_goals_expectations, :text
      add :specific_requests, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:profiles, [:user_id])
  end
end
