defmodule TheDungeonWeb.Plugs.AdminAuth do
  @moduledoc """
  Plug that requires admin authentication via session.
  """
  import Plug.Conn
  import Phoenix.Controller

  def init(opts), do: opts

  def call(conn, _opts) do
    if get_session(conn, :admin_authenticated) do
      conn
    else
      conn
      |> put_flash(:error, "You must log in as admin to access this page.")
      |> redirect(to: "/admin/login")
      |> halt()
    end
  end
end
