defmodule TheDungeon.Repo do
  use Ecto.Repo,
    otp_app: :the_dungeon,
    adapter: Ecto.Adapters.Postgres
end
