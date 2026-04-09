defmodule TheDungeon.Profiles do
  @moduledoc """
  The Profiles context.
  """

  import Ecto.Query, warn: false
  alias TheDungeon.Repo

  alias TheDungeon.Profiles.Profile

  def get_profile_by_user_id(user_id) do
    Repo.get_by(Profile, user_id: user_id)
  end

  def create_profile(user, attrs) do
    %Profile{}
    |> Profile.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()
  end

  def update_profile(%Profile{} = profile, attrs) do
    profile
    |> Profile.changeset(attrs)
    |> Repo.update()
  end

  def change_profile(%Profile{} = profile, attrs \\ %{}) do
    Profile.changeset(profile, attrs)
  end

  def change_profile_step(%Profile{} = profile, attrs \\ %{}, step) do
    Profile.step_changeset(profile, attrs, step)
  end
end
