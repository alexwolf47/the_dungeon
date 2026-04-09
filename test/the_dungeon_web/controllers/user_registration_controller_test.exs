defmodule TheDungeonWeb.UserRegistrationControllerTest do
  use TheDungeonWeb.ConnCase, async: true

  describe "GET /users/register" do
    test "renders registration wizard", %{conn: conn} do
      conn = get(conn, ~p"/users/register")
      response = html_response(conn, 200)
      assert response =~ "Join The Dungeon"
    end
  end
end
