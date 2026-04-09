defmodule TheDungeon.Profiles.Profile do
  use Ecto.Schema
  import Ecto.Changeset

  @step_fields %{
    1 => [:full_name, :phone_number, :instagram_handle, :preferred_contact_method],
    2 => [
      :training_preference,
      :primary_fitness_goals,
      :areas_to_focus,
      :personalised_meal_plan,
      :current_fitness_level
    ],
    3 => [:training_frequency, :available_days, :available_times],
    4 => [:medical_conditions, :current_medications, :prior_trainer_experience],
    5 => [:additional_fitness_info, :training_goals_expectations, :specific_requests]
  }

  @step_required %{
    1 => [:full_name],
    2 => [],
    3 => [],
    4 => [],
    5 => []
  }

  @valid_contact_methods ~w(phone email instagram text)
  @valid_training_preferences ~w(in_person online both)
  @valid_meal_plan_options ~w(yes no more_information)
  @valid_fitness_levels ~w(beginner intermediate advanced)
  @valid_training_frequencies ~w(none once_per_week two_to_three_per_week four_plus_per_week)
  @valid_days ~w(monday tuesday wednesday thursday friday saturday sunday)
  @valid_times ~w(early_morning morning afternoon evening)

  schema "profiles" do
    field :full_name, :string
    field :phone_number, :string
    field :instagram_handle, :string
    field :preferred_contact_method, :string
    field :training_preference, :string
    field :primary_fitness_goals, :string
    field :areas_to_focus, :string
    field :personalised_meal_plan, :string
    field :current_fitness_level, :string
    field :training_frequency, :string
    field :available_days, {:array, :string}, default: []
    field :available_times, {:array, :string}, default: []
    field :medical_conditions, :string
    field :current_medications, :string
    field :prior_trainer_experience, :string
    field :additional_fitness_info, :string
    field :training_goals_expectations, :string
    field :specific_requests, :string

    belongs_to :user, TheDungeon.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def step_fields, do: @step_fields

  def step_changeset(profile, attrs, step) do
    fields = Map.fetch!(@step_fields, step)
    required = Map.fetch!(@step_required, step)

    profile
    |> cast(attrs, fields)
    |> validate_required(required)
    |> validate_step_fields(step)
  end

  def changeset(profile, attrs) do
    all_fields = @step_fields |> Map.values() |> List.flatten()
    all_required = @step_required |> Map.values() |> List.flatten()

    profile
    |> cast(attrs, all_fields)
    |> validate_required(all_required)
    |> maybe_validate_inclusion(:preferred_contact_method, @valid_contact_methods)
    |> maybe_validate_inclusion(:training_preference, @valid_training_preferences)
    |> maybe_validate_inclusion(:personalised_meal_plan, @valid_meal_plan_options)
    |> maybe_validate_inclusion(:current_fitness_level, @valid_fitness_levels)
    |> maybe_validate_inclusion(:training_frequency, @valid_training_frequencies)
    |> validate_subset(:available_days, @valid_days)
    |> validate_subset(:available_times, @valid_times)
    |> unique_constraint(:user_id)
  end

  defp validate_step_fields(changeset, 1) do
    changeset
    |> maybe_validate_inclusion(:preferred_contact_method, @valid_contact_methods)
  end

  defp validate_step_fields(changeset, 2) do
    changeset
    |> maybe_validate_inclusion(:training_preference, @valid_training_preferences)
    |> maybe_validate_inclusion(:personalised_meal_plan, @valid_meal_plan_options)
    |> maybe_validate_inclusion(:current_fitness_level, @valid_fitness_levels)
  end

  defp validate_step_fields(changeset, 3) do
    changeset
    |> maybe_validate_inclusion(:training_frequency, @valid_training_frequencies)
    |> validate_subset(:available_days, @valid_days)
    |> validate_subset(:available_times, @valid_times)
  end

  defp validate_step_fields(changeset, _step), do: changeset

  defp maybe_validate_inclusion(changeset, field, values) do
    if get_change(changeset, field) do
      validate_inclusion(changeset, field, values)
    else
      changeset
    end
  end
end
