defmodule TheDungeonWeb.AdminSessionController do
  use TheDungeonWeb, :controller

  def new(conn, _params) do
    render(conn, :new, error: nil)
  end

  def create(conn, %{"password" => password}) do
    admin_hash = Application.get_env(:the_dungeon, :admin_password_hash)

    if admin_hash && Bcrypt.verify_pass(password, admin_hash) do
      conn
      |> put_session(:admin_authenticated, true)
      |> put_flash(:info, "Welcome back, admin!")
      |> redirect(to: "/admin")
    else
      Bcrypt.no_user_verify()

      conn
      |> put_flash(:error, "Invalid admin password.")
      |> render(:new, error: "Invalid password")
    end
  end

  def delete(conn, _params) do
    conn
    |> delete_session(:admin_authenticated)
    |> put_flash(:info, "Logged out of admin.")
    |> redirect(to: "/admin/login")
  end
end
