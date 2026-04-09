defmodule TheDungeonWeb.UserRegistrationLiveTest do
  use TheDungeonWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import TheDungeon.AccountsFixtures

  describe "Registration wizard (unauthenticated)" do
    test "renders step 1 by default", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/register")

      assert html =~ "Join The Dungeon"
      assert html =~ "Create your account"
      assert html =~ "Email"
      assert html =~ "Full Name"
    end

    test "validates step 1 on submit with empty fields", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      html =
        lv
        |> form("#registration-form", %{
          user: %{email: ""},
          profile: %{full_name: ""}
        })
        |> render_submit()

      assert html =~ "can&#39;t be blank"
    end

    test "advances to step 2 with valid step 1 data", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      html =
        lv
        |> form("#registration-form", %{
          user: %{email: "test@example.com"},
          profile: %{full_name: "Test User"}
        })
        |> render_submit()

      assert html =~ "Training Preference"
      assert html =~ "optional"
    end

    test "can skip optional steps", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      # Step 1
      lv
      |> form("#registration-form", %{
        user: %{email: "skip@example.com"},
        profile: %{full_name: "Skip User"}
      })
      |> render_submit()

      # Skip step 2
      html = lv |> element("button", "Skip") |> render_click()
      assert html =~ "Training Frequency"

      # Skip step 3
      html = lv |> element("button", "Skip") |> render_click()
      assert html =~ "Medical Conditions"

      # Skip step 4
      html = lv |> element("button", "Skip") |> render_click()
      assert html =~ "Additional Fitness Information"
    end

    test "can go back from step 2 to step 1", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      lv
      |> form("#registration-form", %{
        user: %{email: "test@example.com"},
        profile: %{full_name: "Test User"}
      })
      |> render_submit()

      html = lv |> element("button", "Back") |> render_click()

      assert html =~ "Email"
      assert html =~ "Full Name"
    end

    test "completes full wizard and creates user + profile", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      # Step 1 - only required fields
      lv
      |> form("#registration-form", %{
        user: %{email: "wizard@example.com"},
        profile: %{full_name: "Wizard User"}
      })
      |> render_submit()

      # Skip steps 2-4
      lv |> element("button", "Skip") |> render_click()
      lv |> element("button", "Skip") |> render_click()
      lv |> element("button", "Skip") |> render_click()

      # Step 5 - skip & finish
      lv |> element("button", "Skip & Finish") |> render_click()

      assert_redirect(lv, ~p"/users/log-in")

      user = TheDungeon.Accounts.get_user_by_email("wizard@example.com")
      assert user
      profile = TheDungeon.Profiles.get_profile_by_user_id(user.id)
      assert profile
      assert profile.full_name == "Wizard User"
      assert is_nil(profile.training_preference)
    end
  end

  describe "Registration wizard (authenticated)" do
    test "redirects from /users/register to /users/edit-profile", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      {:ok, lv, _html} = live(conn, ~p"/users/register")
      assert_patch(lv, ~p"/users/edit-profile")
    end

    test "shows edit form at /users/edit-profile", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      {:ok, _lv, html} = live(conn, ~p"/users/edit-profile")

      assert html =~ "Edit Your Profile"
      assert html =~ user.email
    end
  end
end
