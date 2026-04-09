defmodule TheDungeon.ProfilesFixtures do
  alias TheDungeon.AccountsFixtures

  def valid_profile_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      full_name: "Test User"
    })
  end

  def profile_fixture(attrs \\ %{}) do
    user = Map.get_lazy(attrs, :user, fn -> AccountsFixtures.user_fixture() end)
    profile_attrs = attrs |> Map.delete(:user) |> valid_profile_attributes()

    {:ok, profile} = TheDungeon.Profiles.create_profile(user, profile_attrs)
    profile
  end
end
