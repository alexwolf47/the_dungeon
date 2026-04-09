defmodule TheDungeon.ProfilesTest do
  use TheDungeon.DataCase

  alias TheDungeon.Profiles
  alias TheDungeon.Profiles.Profile
  alias TheDungeon.AccountsFixtures

  describe "create_profile/2" do
    test "creates a profile with valid attributes" do
      user = AccountsFixtures.user_fixture()

      attrs = %{
        full_name: "Jane Doe",
        preferred_contact_method: "email",
        training_preference: "online"
      }

      assert {:ok, %Profile{} = profile} = Profiles.create_profile(user, attrs)
      assert profile.full_name == "Jane Doe"
      assert profile.preferred_contact_method == "email"
      assert profile.training_preference == "online"
      assert profile.user_id == user.id
    end

    test "creates a profile with only required fields" do
      user = AccountsFixtures.user_fixture()

      attrs = %{full_name: "Jane Doe"}

      assert {:ok, %Profile{} = profile} = Profiles.create_profile(user, attrs)
      assert profile.full_name == "Jane Doe"
      assert is_nil(profile.preferred_contact_method)
      assert is_nil(profile.training_preference)
    end

    test "fails without full_name" do
      user = AccountsFixtures.user_fixture()
      assert {:error, changeset} = Profiles.create_profile(user, %{})
      assert %{full_name: ["can't be blank"]} = errors_on(changeset)
    end

    test "enforces unique user_id" do
      user = AccountsFixtures.user_fixture()

      attrs = %{full_name: "Jane Doe"}

      assert {:ok, _profile} = Profiles.create_profile(user, attrs)
      assert {:error, changeset} = Profiles.create_profile(user, attrs)
      assert %{user_id: ["has already been taken"]} = errors_on(changeset)
    end

    test "validates inclusion of enum fields when provided" do
      user = AccountsFixtures.user_fixture()

      attrs = %{
        full_name: "Jane Doe",
        preferred_contact_method: "carrier_pigeon",
        training_preference: "telepathy"
      }

      assert {:error, changeset} = Profiles.create_profile(user, attrs)
      assert %{preferred_contact_method: ["is invalid"]} = errors_on(changeset)
      assert %{training_preference: ["is invalid"]} = errors_on(changeset)
    end
  end

  describe "update_profile/2" do
    test "updates an existing profile" do
      user = AccountsFixtures.user_fixture()
      {:ok, profile} = Profiles.create_profile(user, %{full_name: "Jane"})

      assert {:ok, updated} =
               Profiles.update_profile(profile, %{
                 full_name: "Jane Updated",
                 training_preference: "online"
               })

      assert updated.full_name == "Jane Updated"
      assert updated.training_preference == "online"
    end
  end

  describe "get_profile_by_user_id/1" do
    test "returns profile for user" do
      user = AccountsFixtures.user_fixture()
      {:ok, profile} = Profiles.create_profile(user, %{full_name: "Jane Doe"})
      found = Profiles.get_profile_by_user_id(user.id)
      assert found.id == profile.id
    end

    test "returns nil when no profile exists" do
      assert Profiles.get_profile_by_user_id(-1) == nil
    end
  end

  describe "step changesets" do
    test "step 1 validates only full_name as required" do
      changeset = Profile.step_changeset(%Profile{}, %{}, 1)
      assert %{full_name: ["can't be blank"]} = errors_on(changeset)
      refute Map.has_key?(errors_on(changeset), :preferred_contact_method)
    end

    test "step 2 has no required fields" do
      changeset = Profile.step_changeset(%Profile{}, %{}, 2)
      assert changeset.valid?
    end

    test "steps 3-5 have no required fields" do
      for step <- 3..5 do
        changeset = Profile.step_changeset(%Profile{}, %{}, step)
        assert changeset.valid?, "Step #{step} should be valid with no data"
      end
    end

    test "step 1 validates contact method inclusion when provided" do
      changeset = Profile.step_changeset(%Profile{}, %{preferred_contact_method: "fax"}, 1)
      assert %{preferred_contact_method: ["is invalid"]} = errors_on(changeset)
    end

    test "step 2 validates training preference inclusion when provided" do
      changeset = Profile.step_changeset(%Profile{}, %{training_preference: "nope"}, 2)
      assert %{training_preference: ["is invalid"]} = errors_on(changeset)
    end

    test "step 3 validates day and time subsets" do
      changeset =
        Profile.step_changeset(
          %Profile{},
          %{available_days: ["funday"], available_times: ["midnight"]},
          3
        )

      assert %{available_days: ["has an invalid entry"]} = errors_on(changeset)
      assert %{available_times: ["has an invalid entry"]} = errors_on(changeset)
    end
  end
end
