defmodule TheDungeonWeb.Admin.DashboardLive do
  use TheDungeonWeb, :live_view

  alias TheDungeon.Scheduling

  @impl true
  def mount(_params, _session, socket) do
    today = Date.utc_today()

    socket =
      socket
      |> assign(:page_title, "Admin Dashboard")
      |> assign(:year, today.year)
      |> assign(:month, today.month)
      |> assign(:selected_date, nil)
      |> assign(:selected_slots, [])
      |> assign(:show_bootcamp_form, false)
      |> assign(:show_pt_form, false)
      |> load_slots()

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
      |> assign(:selected_slots, [])
      |> load_slots()

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
      |> assign(:selected_slots, [])
      |> load_slots()

    {:noreply, socket}
  end

  @impl true
  def handle_event("generate_defaults", _params, socket) do
    %{year: year, month: month} = socket.assigns
    {count, _} = Scheduling.generate_default_slots(year, month)

    socket =
      socket
      |> put_flash(:info, "Generated #{count} default slots.")
      |> load_slots()

    {:noreply, socket}
  end

  @impl true
  def handle_event("select_date", %{"date" => date_str}, socket) do
    date = Date.from_iso8601!(date_str)
    all_slots = Scheduling.get_all_slots_for_date(date)

    {:noreply, assign(socket, selected_date: date, selected_slots: all_slots)}
  end

  @impl true
  def handle_event("show_bootcamp_form", _params, socket) do
    {:noreply, assign(socket, show_bootcamp_form: true)}
  end

  @impl true
  def handle_event("show_pt_form", _params, socket) do
    {:noreply, assign(socket, show_pt_form: true)}
  end

  @impl true
  def handle_event("cancel_form", _params, socket) do
    {:noreply, assign(socket, show_bootcamp_form: false, show_pt_form: false)}
  end

  @impl true
  def handle_event("add_bootcamp", %{"slot" => slot_params}, socket) do
    %{selected_date: date} = socket.assigns

    attrs =
      slot_params
      |> Map.put("date", Date.to_iso8601(date))
      |> Map.put("slot_type", "bootcamp")

    case Scheduling.create_bootcamp_slot(attrs) do
      {:ok, _slot} ->
        socket =
          socket
          |> put_flash(:info, "Bootcamp added!")
          |> assign(:show_bootcamp_form, false)
          |> load_slots()
          |> reload_selected_date()

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to add bootcamp.")}
    end
  end

  @impl true
  def handle_event("add_pt_slot", %{"slot" => slot_params}, socket) do
    %{selected_date: date} = socket.assigns

    attrs =
      slot_params
      |> Map.put("date", Date.to_iso8601(date))
      |> Map.put("slot_type", "pt")
      |> Map.put("max_participants", "1")

    case Scheduling.create_slot(attrs) do
      {:ok, _slot} ->
        socket =
          socket
          |> put_flash(:info, "PT slot added!")
          |> assign(:show_pt_form, false)
          |> load_slots()
          |> reload_selected_date()

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to add PT slot. Time may already be taken.")}
    end
  end

  @impl true
  def handle_event("cancel_slot", %{"id" => slot_id}, socket) do
    slot = Scheduling.get_slot!(slot_id)

    case Scheduling.cancel_slot(slot) do
      {:ok, _slot} ->
        socket =
          socket
          |> put_flash(:info, "Slot cancelled.")
          |> load_slots()
          |> reload_selected_date()

        {:noreply, socket}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Failed to cancel slot.")}
    end
  end

  @impl true
  def handle_event("delete_slot", %{"id" => slot_id}, socket) do
    slot = Scheduling.get_slot!(slot_id)

    case Scheduling.delete_slot(slot) do
      {:ok, _slot} ->
        socket =
          socket
          |> put_flash(:info, "Slot deleted.")
          |> load_slots()
          |> reload_selected_date()

        {:noreply, socket}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Failed to delete slot.")}
    end
  end

  @impl true
  def handle_event("cancel_booking", %{"id" => booking_id}, socket) do
    booking = Scheduling.get_booking!(booking_id)

    case Scheduling.cancel_booking(booking) do
      {:ok, _booking} ->
        socket =
          socket
          |> put_flash(:info, "Booking cancelled.")
          |> load_slots()
          |> reload_selected_date()

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to cancel booking.")}
    end
  end

  defp load_slots(socket) do
    %{year: year, month: month} = socket.assigns
    slots_by_date = Scheduling.list_slots_for_month(year, month)
    assign(socket, :slots_by_date, slots_by_date)
  end

  defp reload_selected_date(socket) do
    case socket.assigns.selected_date do
      nil ->
        socket

      date ->
        all_slots = Scheduling.get_all_slots_for_date(date)
        assign(socket, :selected_slots, all_slots)
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

    # Pad start (Monday = 1)
    start_padding = List.duplicate(nil, day_of_week - 1)
    days = Enum.map(Date.range(first_day, last_day), & &1)
    all_cells = start_padding ++ days

    # Pad end to complete last week
    end_padding_count = rem(7 - rem(length(all_cells), 7), 7)
    all_cells = all_cells ++ List.duplicate(nil, end_padding_count)

    Enum.chunk_every(all_cells, 7)
  end

  defp slot_status_for_date(date, slots_by_date) do
    case Map.get(slots_by_date, date, []) do
      [] ->
        :empty

      slots ->
        all_full =
          Enum.all?(slots, fn slot ->
            confirmed = Enum.count(slot.bookings)
            slot.status == "cancelled" or confirmed >= slot.max_participants
          end)

        any_booked = Enum.any?(slots, fn slot -> Enum.count(slot.bookings) > 0 end)

        cond do
          all_full -> :full
          any_booked -> :partial
          true -> :available
        end
    end
  end

  defp format_hour(hour) when hour < 12, do: "#{hour}:00 AM"
  defp format_hour(12), do: "12:00 PM"
  defp format_hour(hour), do: "#{hour - 12}:00 PM"

  defp confirmed_booking_count(slot) do
    Enum.count(slot.bookings, fn
      %{status: "confirmed"} -> true
      _ -> false
    end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen pt-20 pb-10 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto">
      <%!-- Admin Tab Navigation --%>
      <div class="tabs tabs-boxed mb-6 bg-base-200 inline-flex">
        <.link navigate={~p"/admin"} class="tab tab-active">Schedule</.link>
        <.link navigate={~p"/admin/users"} class="tab">Users</.link>
      </div>

      <div class="flex flex-col lg:flex-row gap-6">
        <%!-- Calendar Section --%>
        <div class="flex-1">
          <div class="card bg-base-200 shadow-xl">
            <div class="card-body">
              <div class="flex items-center justify-between mb-4">
                <button class="btn btn-ghost btn-sm" phx-click="prev_month">&larr;</button>
                <h2 class="text-xl font-bold">{month_name(@month)} {@year}</h2>
                <button class="btn btn-ghost btn-sm" phx-click="next_month">&rarr;</button>
              </div>

              <div class="mb-4">
                <button class="btn btn-primary btn-sm" phx-click="generate_defaults">
                  Generate Default Slots
                </button>
              </div>

              <%!-- Calendar Grid --%>
              <div class="grid grid-cols-7 gap-1 text-center">
                <div
                  :for={day <- ~w(Mon Tue Wed Thu Fri Sat Sun)}
                  class="text-xs font-bold text-base-content/60 p-1"
                >
                  {day}
                </div>

                <%= for week <- calendar_weeks(@year, @month), date <- week do %>
                  <%= if date do %>
                    <% status = slot_status_for_date(date, @slots_by_date) %>
                    <button
                      phx-click="select_date"
                      phx-value-date={Date.to_iso8601(date)}
                      class={[
                        "btn btn-sm h-10 min-h-0",
                        status == :available && "btn-success btn-outline",
                        status == :partial && "btn-warning btn-outline",
                        status == :full && "btn-error btn-outline",
                        status == :empty && "btn-ghost",
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

              <div class="flex gap-4 mt-4 text-xs">
                <span class="flex items-center gap-1">
                  <span class="w-3 h-3 rounded bg-success"></span> Available
                </span>
                <span class="flex items-center gap-1">
                  <span class="w-3 h-3 rounded bg-warning"></span> Partially Booked
                </span>
                <span class="flex items-center gap-1">
                  <span class="w-3 h-3 rounded bg-error"></span> Full
                </span>
              </div>
            </div>
          </div>
        </div>

        <%!-- Day Detail Panel --%>
        <div class="flex-1">
          <%= if @selected_date do %>
            <div class="card bg-base-200 shadow-xl">
              <div class="card-body">
                <h3 class="card-title">
                  {Calendar.strftime(@selected_date, "%A, %B %d, %Y")}
                </h3>

                <div class="flex gap-2 mb-4">
                  <button class="btn btn-sm btn-secondary" phx-click="show_bootcamp_form">
                    Add Bootcamp
                  </button>
                  <button class="btn btn-sm btn-accent" phx-click="show_pt_form">
                    Add PT Slot
                  </button>
                </div>

                <%!-- Add Bootcamp Form --%>
                <%= if @show_bootcamp_form do %>
                  <div class="card bg-base-300 mb-4">
                    <div class="card-body p-4">
                      <h4 class="font-bold text-sm">New Bootcamp</h4>
                      <.form for={%{}} phx-submit="add_bootcamp" class="flex flex-col gap-2">
                        <input
                          type="text"
                          name="slot[bootcamp_name]"
                          placeholder="Bootcamp Name"
                          class="input input-bordered input-sm w-full"
                          required
                        />
                        <div class="flex gap-2">
                          <select
                            name="slot[start_hour]"
                            class="select select-bordered select-sm flex-1"
                          >
                            <option :for={h <- 6..20} value={h}>{format_hour(h)}</option>
                          </select>
                          <input
                            type="number"
                            name="slot[max_participants]"
                            value="8"
                            min="1"
                            class="input input-bordered input-sm w-20"
                          />
                        </div>
                        <div class="flex gap-2">
                          <button type="submit" class="btn btn-primary btn-sm">Add</button>
                          <button type="button" class="btn btn-ghost btn-sm" phx-click="cancel_form">
                            Cancel
                          </button>
                        </div>
                      </.form>
                    </div>
                  </div>
                <% end %>

                <%!-- Add PT Slot Form --%>
                <%= if @show_pt_form do %>
                  <div class="card bg-base-300 mb-4">
                    <div class="card-body p-4">
                      <h4 class="font-bold text-sm">New PT Slot</h4>
                      <.form for={%{}} phx-submit="add_pt_slot" class="flex flex-col gap-2">
                        <select name="slot[start_hour]" class="select select-bordered select-sm">
                          <option :for={h <- 6..20} value={h}>{format_hour(h)}</option>
                        </select>
                        <div class="flex gap-2">
                          <button type="submit" class="btn btn-primary btn-sm">Add</button>
                          <button type="button" class="btn btn-ghost btn-sm" phx-click="cancel_form">
                            Cancel
                          </button>
                        </div>
                      </.form>
                    </div>
                  </div>
                <% end %>

                <%!-- Slot List --%>
                <div class="space-y-3">
                  <%= if @selected_slots == [] do %>
                    <p class="text-base-content/60 text-sm">No slots for this date.</p>
                  <% end %>

                  <div
                    :for={slot <- @selected_slots}
                    class={[
                      "card bg-base-300",
                      slot.status == "cancelled" && "opacity-50"
                    ]}
                  >
                    <div class="card-body p-4">
                      <div class="flex items-center justify-between">
                        <div>
                          <span class="font-bold">{format_hour(slot.start_hour)}</span>
                          <span class={[
                            "badge badge-sm ml-2",
                            slot.slot_type == "pt" && "badge-accent",
                            slot.slot_type == "bootcamp" && "badge-secondary"
                          ]}>
                            {String.upcase(slot.slot_type)}
                          </span>
                          <span :if={slot.bootcamp_name} class="text-sm ml-1">
                            {slot.bootcamp_name}
                          </span>
                          <span
                            :if={slot.status == "cancelled"}
                            class="badge badge-error badge-sm ml-2"
                          >
                            Cancelled
                          </span>
                        </div>
                        <div class="text-sm text-base-content/60">
                          {confirmed_booking_count(slot)}/{slot.max_participants} booked
                        </div>
                      </div>

                      <%!-- Bookings --%>
                      <div :if={slot.bookings != []} class="mt-2 space-y-1">
                        <div
                          :for={booking <- slot.bookings}
                          class="flex items-center justify-between text-sm bg-base-100 rounded px-3 py-1"
                        >
                          <span>{booking.user.email}</span>
                          <button
                            phx-click="cancel_booking"
                            phx-value-id={booking.id}
                            data-confirm="Cancel this booking?"
                            class="btn btn-ghost btn-xs text-error"
                          >
                            Cancel
                          </button>
                        </div>
                      </div>

                      <%!-- Slot Actions --%>
                      <div :if={slot.status == "available"} class="flex gap-2 mt-2">
                        <button
                          phx-click="cancel_slot"
                          phx-value-id={slot.id}
                          data-confirm="Cancel this slot? All bookings will be cancelled."
                          class="btn btn-warning btn-xs"
                        >
                          Cancel Slot
                        </button>
                        <button
                          phx-click="delete_slot"
                          phx-value-id={slot.id}
                          data-confirm="Delete this slot permanently?"
                          class="btn btn-error btn-xs"
                        >
                          Delete
                        </button>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          <% else %>
            <div class="card bg-base-200 shadow-xl">
              <div class="card-body items-center text-center text-base-content/60">
                <p>Select a date to view and manage slots.</p>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
