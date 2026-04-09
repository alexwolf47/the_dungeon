defmodule TheDungeon.Emails do
  @moduledoc """
  Reusable email infrastructure for The Dungeon PT.

  Provides base email construction with default from address.
  Extend this module with follow-up email functions as needed
  (session reminders, training updates, etc.).
  """

  import Swoosh.Email

  @from_address {"The Dungeon PT", "thedungeonptgym@gmail.com"}

  def base_email do
    new()
    |> from(@from_address)
  end
end
