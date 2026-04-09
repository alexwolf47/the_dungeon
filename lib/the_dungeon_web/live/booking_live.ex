defmodule TheDungeonWeb.BookingLive do
  use TheDungeonWeb, :live_view

  alias TheDungeon.Scheduling

  @impl true
  def mount(_params, _session, socket) do
    %{current_scope: %{user: user}} = socket.assigns
    today = Date.utc_today()

    socket =
      socket
      |> assign(:page_title, "Book a Session")
      |> assign(:year, today.year)
      |> assign(:month, today.month)
      |> assign(:selected_date, nil)
      |> assign(:available_slots, [])
      |> assign(:upcoming_bookings, Scheduling.list_user_bookings(user, :upcoming))
      |> load_month_data()

    {:ok, socket}
  end

  @impl true
  def handle_event("prev_month", _params, socket) do
    %{year: year, month: month} = socket.assigns
    {new_year, new_month} = prev_month(year, month)

    socket =
      socket
      |> assign(:year, new_year)
      |> assign(:month, new_month)
      |> assign(:selected_date, nil)
      |> assign(:available_slots, [])
      |> load_month_data()

    {:noreply, socket}
  end

  @impl true
  def handle_event("next_month", _params, socket) do
    %{year: year, month: month} = socket.assigns
    {new_year, new_month} = next_month(year, month)

    socket =
      socket
      |> assign(:year, new_year)
      |> assign(:month, new_month)
      |> assign(:selected_date, nil)
      |> assign(:available_slots, [])
      |> load_month_data()

    {:noreply, socket}
  end

  @impl true
  def handle_event("select_date", %{"date" => date_str}, socket) do
    date = Date.from_iso8601!(date_str)
    slots = Scheduling.list_slots_for_date(date)

    {:noreply, assign(socket, selected_date: date, available_slots: slots)}
  end

  @impl true
  def handle_event("book_slot", %{"id" => slot_id}, socket) do
    %{current_scope: %{user: user}} = socket.assigns

    case Scheduling.book_slot(user, slot_id) do
      {:ok, _booking} ->
        socket =
          socket
          |> put_flash(:info, "Session booked successfully!")
          |> assign(:upcoming_bookings, Scheduling.list_user_bookings(user, :upcoming))
          |> refresh_selected_date()
          |> load_month_data()

        {:noreply, socket}

      {:error, :slot_full} ->
        {:noreply, put_flash(socket, :error, "Sorry, this slot is fully booked.")}

      {:error, :slot_cancelled} ->
        {:noreply, put_flash(socket, :error, "This slot has been cancelled.")}

      {:error, :slot_not_found} ->
        {:noreply, put_flash(socket, :error, "Slot not found.")}

      {:error, _reason} ->
        {:noreply,
         put_flash(socket, :error, "Unable to book this slot. You may have already booked it.")}
    end
  end

  @impl true
  def handle_event("cancel_booking", %{"id" => booking_id}, socket) do
    %{current_scope: %{user: user}} = socket.assigns
    booking = Scheduling.get_booking!(booking_id)

    case Scheduling.cancel_booking(booking) do
      {:ok, _booking} ->
        socket =
          socket
          |> put_flash(:info, "Booking cancelled.")
          |> assign(:upcoming_bookings, Scheduling.list_user_bookings(user, :upcoming))
          |> refresh_selected_date()
          |> load_month_data()

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to cancel booking.")}
    end
  end

  defp load_month_data(socket) do
    %{year: year, month: month} = socket.assigns
    slots_by_date = Scheduling.list_slots_for_month(year, month)
    assign(socket, :slots_by_date, slots_by_date)
  end

  defp refresh_selected_date(socket) do
    case socket.assigns.selected_date do
      nil -> socket
      date -> assign(socket, :available_slots, Scheduling.list_slots_for_date(date))
    end
  end

  defp prev_month(year, 1), do: {year - 1, 12}
  defp prev_month(year, month), do: {year, month - 1}

  defp next_month(year, 12), do: {year + 1, 1}
  defp next_month(year, month), do: {year, month + 1}

  defp month_name(month) do
    ~w(January February March April May June July August September October November December)
    |> Enum.at(month - 1)
  end

  defp calendar_weeks(year, month) do
    first_day = Date.new!(year, month, 1)
    last_day = Date.end_of_month(first_day)
    day_of_week = Date.day_of_week(first_day)

    start_padding = List.duplicate(nil, day_of_week - 1)
    days = Enum.map(Date.range(first_day, last_day), & &1)
    all_cells = start_padding ++ days

    end_padding_count = rem(7 - rem(length(all_cells), 7), 7)
    all_cells = all_cells ++ List.duplicate(nil, end_padding_count)

    Enum.chunk_every(all_cells, 7)
  end

  defp date_has_available_slots?(date, slots_by_date) do
    case Map.get(slots_by_date, date, []) do
      [] ->
        false

      slots ->
        Enum.any?(slots, fn slot ->
          slot.status == "available" and
            Enum.count(slot.bookings) < slot.max_participants
        end)
    end
  end

  defp spots_remaining(slot) do
    confirmed = Enum.count(slot.bookings)
    slot.max_participants - confirmed
  end

  defp format_hour(hour) when hour < 12, do: "#{hour}:00 AM"
  defp format_hour(12), do: "12:00 PM"
  defp format_hour(hour), do: "#{hour - 12}:00 PM"

  defp format_hour_range(hour) do
    "#{format_hour(hour)} - #{format_hour(hour + 1)}"
  end

  defp already_booked?(slot, user) do
    Enum.any?(slot.bookings, fn
      %{user_id: uid} -> uid == user.id
      _ -> false
    end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen pt-20 pb-10 px-4 sm:px-6 lg:px-8 max-w-4xl mx-auto">
      <h1 class="text-3xl font-black mb-6">Book a Session</h1>

      <div class="flex flex-col lg:flex-row gap-6">
        <%!-- Calendar --%>
        <div class="lg:w-1/2">
          <div class="card bg-base-200 shadow-xl">
            <div class="card-body">
              <div class="flex items-center justify-between mb-4">
                <button class="btn btn-ghost btn-sm" phx-click="prev_month">&larr;</button>
                <h2 class="text-lg font-bold">{month_name(@month)} {@year}</h2>
                <button class="btn btn-ghost btn-sm" phx-click="next_month">&rarr;</button>
              </div>

              <div class="grid grid-cols-7 gap-1 text-center">
                <div
                  :for={day <- ~w(Mon Tue Wed Thu Fri Sat Sun)}
                  class="text-xs font-bold text-base-content/60 p-1"
                >
                  {day}
                </div>

                <%= for week <- calendar_weeks(@year, @month), date <- week do %>
                  <%= if date do %>
                    <% has_slots = date_has_available_slots?(date, @slots_by_date) %>
                    <% is_past = Date.compare(date, Date.utc_today()) == :lt %>
                    <button
                      phx-click={if !is_past, do: "select_date"}
                      phx-value-date={Date.to_iso8601(date)}
                      disabled={is_past}
                      class={[
                        "btn btn-sm h-10 min-h-0",
                        has_slots && !is_past && "btn-success btn-outline",
                        !has_slots && "btn-ghost",
                        is_past && "opacity-30",
                        @selected_date == date && "ring-2 ring-primary"
                      ]}
                    >
                      {date.day}
                    </button>
                  <% else %>
                    <div class="h-10"></div>
                  <% end %>
                <% end %>
              </div>
            </div>
          </div>
        </div>

        <%!-- Available Slots --%>
        <div class="lg:w-1/2">
          <%= if @selected_date do %>
            <h3 class="text-lg font-bold mb-3">
              {Calendar.strftime(@selected_date, "%A, %B %d")}
            </h3>

            <%= if @available_slots == [] do %>
              <p class="text-base-content/60">No available slots for this date.</p>
            <% else %>
              <div class="space-y-3">
                <div :for={slot <- @available_slots} class="card bg-base-200 shadow">
                  <div class="card-body p-4 flex-row items-center justify-between">
                    <div>
                      <p class="font-bold">{format_hour_range(slot.start_hour)}</p>
                      <div class="flex items-center gap-2 mt-1">
                        <span class={[
                          "badge badge-sm",
                          slot.slot_type == "pt" && "badge-accent",
                          slot.slot_type == "bootcamp" && "badge-secondary"
                        ]}>
                          {if slot.slot_type == "pt", do: "PT", else: slot.bootcamp_name || "Bootcamp"}
                        </span>
                        <span :if={slot.slot_type == "bootcamp"} class="text-xs text-base-content/60">
                          {spots_remaining(slot)} spots left
                        </span>
                      </div>
                    </div>
                    <div>
                      <%= if already_booked?(slot, @current_scope.user) do %>
                        <span class="badge badge-info">Booked</span>
                      <% else %>
                        <% remaining = spots_remaining(slot) %>
                        <%= if remaining > 0 do %>
                          <button
                            phx-click="book_slot"
                            phx-value-id={slot.id}
                            class="btn btn-primary btn-sm"
                          >
                            Book
                          </button>
                        <% else %>
                          <span class="badge badge-error">Full</span>
                        <% end %>
                      <% end %>
                    </div>
                  </div>
                </div>
              </div>
            <% end %>
          <% else %>
            <p class="text-base-content/60">Select a date to see available slots.</p>
          <% end %>
        </div>
      </div>

      <%!-- Upcoming Bookings --%>
      <div class="mt-10">
        <h2 class="text-2xl font-bold mb-4">Your Upcoming Bookings</h2>

        <%= if @upcoming_bookings == [] do %>
          <p class="text-base-content/60">No upcoming bookings.</p>
        <% else %>
          <div class="space-y-3">
            <div :for={booking <- @upcoming_bookings} class="card bg-base-200 shadow">
              <div class="card-body p-4 flex-row items-center justify-between">
                <div>
                  <p class="font-bold">
                    {Calendar.strftime(booking.slot.date, "%A, %B %d")}
                  </p>
                  <p class="text-sm">{format_hour_range(booking.slot.start_hour)}</p>
                  <span class={[
                    "badge badge-sm mt-1",
                    booking.slot.slot_type == "pt" && "badge-accent",
                    booking.slot.slot_type == "bootcamp" && "badge-secondary"
                  ]}>
                    {if booking.slot.slot_type == "pt",
                      do: "PT",
                      else: booking.slot.bootcamp_name || "Bootcamp"}
                  </span>
                </div>
                <button
                  phx-click="cancel_booking"
                  phx-value-id={booking.id}
                  data-confirm="Are you sure you want to cancel this booking?"
                  class="btn btn-outline btn-error btn-sm"
                >
                  Cancel
                </button>
              </div>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
