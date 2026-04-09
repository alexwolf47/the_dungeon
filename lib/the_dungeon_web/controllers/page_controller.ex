defmodule TheDungeonWeb.PageController do
  use TheDungeonWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
