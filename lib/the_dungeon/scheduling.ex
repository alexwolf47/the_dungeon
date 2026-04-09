defmodule TheDungeon.Scheduling do
  @moduledoc """
  The Scheduling context for managing slots and bookings.
  """

  import Ecto.Query, warn: false
  alias TheDungeon.Repo
  alias TheDungeon.Scheduling.{Slot, Booking}

  ## Slot Management

  def generate_default_slots(year, month) do
    first_day = Date.new!(year, month, 1)
    last_day = Date.end_of_month(first_day)
    hours = [9, 10, 11, 13, 14, 15, 16]
    now = DateTime.utc_now(:second)

    slots =
      Date.range(first_day, last_day)
      |> Enum.filter(&(Date.day_of_week(&1) in 1..5))
      |> Enum.flat_map(fn date ->
        Enum.map(hours, fn hour ->
          %{
            id: Ecto.UUID.generate(),
            date: date,
            start_hour: hour,
            slot_type: "pt",
            bootcamp_name: nil,
            max_participants: 1,
            status: "available",
            inserted_at: now,
            updated_at: now
          }
        end)
      end)

    Repo.insert_all(Slot, slots, on_conflict: :nothing)
  end

  def create_slot(attrs) do
    %Slot{}
    |> Slot.changeset(attrs)
    |> Repo.insert()
  end

  def create_bootcamp_slot(attrs) do
    %Slot{}
    |> Slot.bootcamp_changeset(attrs)
    |> Repo.insert()
  end

  def cancel_slot(%Slot{} = slot) do
    Repo.transaction(fn ->
      {:ok, slot} =
        slot
        |> Slot.changeset(%{status: "cancelled"})
        |> Repo.update()

      from(b in Booking, where: b.slot_id == ^slot.id and b.status == "confirmed")
      |> Repo.update_all(set: [status: "cancelled", updated_at: DateTime.utc_now(:second)])

      slot
    end)
  end

  def delete_slot(%Slot{} = slot) do
    Repo.delete(slot)
  end

  def list_slots_for_month(year, month) do
    first_day = Date.new!(year, month, 1)
    last_day = Date.end_of_month(first_day)

    from(s in Slot,
      where: s.date >= ^first_day and s.date <= ^last_day,
      order_by: [asc: s.date, asc: s.start_hour],
      preload: [bookings: ^from(b in Booking, where: b.status == "confirmed", preload: [:user])]
    )
    |> Repo.all()
    |> Enum.group_by(& &1.date)
  end

  def list_slots_for_date(date) do
    from(s in Slot,
      where: s.date == ^date and s.status == "available",
      order_by: [asc: s.start_hour],
      preload: [bookings: ^from(b in Booking, where: b.status == "confirmed")]
    )
    |> Repo.all()
  end

  def get_all_slots_for_date(date) do
    from(s in Slot,
      where: s.date == ^date,
      order_by: [asc: s.start_hour],
      preload: [bookings: ^from(b in Booking, where: b.status == "confirmed", preload: [:user])]
    )
    |> Repo.all()
  end

  def get_slot!(id), do: Repo.get!(Slot, id)

  def get_slot_with_bookings!(id) do
    Repo.get!(Slot, id)
    |> Repo.preload(
      bookings: from(b in Booking, where: b.status == "confirmed", preload: [:user])
    )
  end

  ## Booking Management

  def book_slot(user, slot_id) do
    Repo.transaction(fn ->
      slot =
        from(s in Slot,
          where: s.id == ^slot_id,
          lock: "FOR UPDATE"
        )
        |> Repo.one()

      cond do
        is_nil(slot) ->
          Repo.rollback(:slot_not_found)

        slot.status == "cancelled" ->
          Repo.rollback(:slot_cancelled)

        true ->
          confirmed_count =
            from(b in Booking,
              where: b.slot_id == ^slot.id and b.status == "confirmed",
              select: count(b.id)
            )
            |> Repo.one()

          if confirmed_count >= slot.max_participants do
            Repo.rollback(:slot_full)
          else
            %Booking{}
            |> Booking.changeset(%{user_id: user.id, slot_id: slot.id})
            |> Repo.insert()
            |> case do
              {:ok, booking} -> booking
              {:error, changeset} -> Repo.rollback(changeset)
            end
          end
      end
    end)
  end

  def cancel_booking(%Booking{} = booking) do
    booking
    |> Booking.changeset(%{status: "cancelled"})
    |> Repo.update()
  end

  def get_booking!(id) do
    Repo.get!(Booking, id)
    |> Repo.preload(:slot)
  end

  def list_user_bookings(user, type) do
    today = Date.utc_today()

    base_query =
      from(b in Booking,
        join: s in assoc(b, :slot),
        where: b.user_id == ^user.id,
        preload: [slot: s]
      )

    case type do
      :upcoming ->
        from([b, s] in base_query,
          where: s.date >= ^today and b.status == "confirmed",
          order_by: [asc: s.date, asc: s.start_hour]
        )

      :past ->
        from([b, s] in base_query,
          where: s.date < ^today or b.status == "cancelled",
          order_by: [desc: s.date, desc: s.start_hour]
        )
    end
    |> Repo.all()
  end
end
