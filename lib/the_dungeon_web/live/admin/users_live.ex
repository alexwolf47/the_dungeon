defmodule TheDungeonWeb.Admin.UsersLive do
  use TheDungeonWeb, :live_view

  alias TheDungeon.Accounts
  alias TheDungeon.Scheduling

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Admin Users")
      |> assign(:tab, :new_signups)
      |> assign(:selected_user, nil)
      |> load_users()

    {:ok, socket}
  end

  @impl true
  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply,
     socket
     |> assign(:tab, String.to_existing_atom(tab))
     |> assign(:selected_user, nil)
     |> load_users()}
  end

  @impl true
  def handle_event("mark_registered", %{"id" => user_id}, socket) do
    user = Accounts.get_user!(user_id)

    case Accounts.mark_user_registered(user) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "User marked as registered.")
         |> load_users()}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to update user.")}
    end
  end

  @impl true
  def handle_event("mark_unregistered", %{"id" => user_id}, socket) do
    user = Accounts.get_user!(user_id)

    case Accounts.mark_user_unregistered(user) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "User marked as unregistered.")
         |> load_users()}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to update user.")}
    end
  end

  @impl true
  def handle_event("select_user", %{"id" => user_id}, socket) do
    user = Accounts.get_user!(user_id) |> TheDungeon.Repo.preload(:profile)
    upcoming = Scheduling.list_user_bookings(user, :upcoming)
    past = Scheduling.list_user_bookings(user, :past)

    {:noreply,
     assign(socket,
       selected_user: user,
       user_upcoming_bookings: upcoming,
       user_past_bookings: past
     )}
  end

  @impl true
  def handle_event("close_user_detail", _params, socket) do
    {:noreply, assign(socket, selected_user: nil)}
  end

  defp load_users(socket) do
    case socket.assigns.tab do
      :new_signups ->
        assign(socket, :users, Accounts.list_new_signups())

      :all_users ->
        assign(socket, :users, Accounts.list_users())
    end
  end

  defp format_date(datetime) do
    Calendar.strftime(datetime, "%b %d, %Y")
  end

  defp user_name(user) do
    case user.profile do
      %{full_name: name} when is_binary(name) and name != "" -> name
      _ -> "No name"
    end
  end

  defp format_hour(hour) when hour < 12, do: "#{hour}:00 AM"
  defp format_hour(12), do: "12:00 PM"
  defp format_hour(hour), do: "#{hour - 12}:00 PM"

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen pt-20 pb-10 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto">
      <%!-- Admin Tab Navigation --%>
      <div class="tabs tabs-boxed mb-6 bg-base-200 inline-flex">
        <.link navigate={~p"/admin"} class="tab">Schedule</.link>
        <.link navigate={~p"/admin/users"} class="tab tab-active">Users</.link>
      </div>

      <%!-- Sub-tabs --%>
      <div class="tabs tabs-bordered mb-6">
        <button
          class={["tab", @tab == :new_signups && "tab-active"]}
          phx-click="switch_tab"
          phx-value-tab="new_signups"
        >
          New Signups
          <span :if={@tab != :new_signups} class="badge badge-sm badge-primary ml-2">
            {length(@users)}
          </span>
        </button>
        <button
          class={["tab", @tab == :all_users && "tab-active"]}
          phx-click="switch_tab"
          phx-value-tab="all_users"
        >
          All Users
        </button>
      </div>

      <div class="flex flex-col lg:flex-row gap-6">
        <%!-- User List --%>
        <div class="flex-1">
          <%= if @users == [] do %>
            <div class="card bg-base-200">
              <div class="card-body text-center text-base-content/60">
                <%= if @tab == :new_signups do %>
                  No new signups pending registration.
                <% else %>
                  No users yet.
                <% end %>
              </div>
            </div>
          <% else %>
            <div class="space-y-2">
              <div
                :for={user <- @users}
                class="card bg-base-200 cursor-pointer hover:bg-base-300 transition-colors"
                phx-click="select_user"
                phx-value-id={user.id}
              >
                <div class="card-body p-4 flex-row items-center justify-between">
                  <div>
                    <p class="font-bold">{user_name(user)}</p>
                    <p class="text-sm text-base-content/60">{user.email}</p>
                    <p class="text-xs text-base-content/40">
                      Signed up: {format_date(user.inserted_at)}
                    </p>
                  </div>
                  <div class="flex items-center gap-2">
                    <%= if user.registered do %>
                      <span class="badge badge-success badge-sm">Registered</span>
                      <%= if @tab == :all_users do %>
                        <button
                          phx-click="mark_unregistered"
                          phx-value-id={user.id}
                          class="btn btn-ghost btn-xs"
                          data-confirm="Mark as unregistered?"
                        >
                          Undo
                        </button>
                      <% end %>
                    <% else %>
                      <button
                        phx-click="mark_registered"
                        phx-value-id={user.id}
                        class="btn btn-primary btn-xs"
                      >
                        Mark Registered
                      </button>
                    <% end %>
                  </div>
                </div>
              </div>
            </div>
          <% end %>
        </div>

        <%!-- User Detail Panel --%>
        <div :if={@selected_user} class="flex-1">
          <div class="card bg-base-200 shadow-xl">
            <div class="card-body">
              <div class="flex items-center justify-between">
                <h3 class="card-title">{user_name(@selected_user)}</h3>
                <button class="btn btn-ghost btn-sm" phx-click="close_user_detail">X</button>
              </div>

              <div class="space-y-2 text-sm">
                <p><span class="font-semibold">Email:</span> {@selected_user.email}</p>
                <p>
                  <span class="font-semibold">Status:</span>
                  <%= if @selected_user.registered do %>
                    <span class="badge badge-success badge-sm">Registered</span>
                  <% else %>
                    <span class="badge badge-warning badge-sm">Pending</span>
                  <% end %>
                </p>

                <%= if @selected_user.profile do %>
                  <% profile = @selected_user.profile %>
                  <p :if={profile.phone_number}>
                    <span class="font-semibold">Phone:</span> {profile.phone_number}
                  </p>
                  <p :if={profile.current_fitness_level}>
                    <span class="font-semibold">Fitness Level:</span> {profile.current_fitness_level}
                  </p>
                  <p :if={profile.training_preference}>
                    <span class="font-semibold">Training Preference:</span> {profile.training_preference}
                  </p>
                  <p :if={profile.primary_fitness_goals}>
                    <span class="font-semibold">Goals:</span> {profile.primary_fitness_goals}
                  </p>
                <% end %>
              </div>

              <%!-- Upcoming Bookings --%>
              <div class="mt-4">
                <h4 class="font-bold text-sm mb-2">Upcoming Bookings</h4>
                <%= if @user_upcoming_bookings == [] do %>
                  <p class="text-sm text-base-content/60">No upcoming bookings.</p>
                <% else %>
                  <div class="space-y-1">
                    <div
                      :for={booking <- @user_upcoming_bookings}
                      class="text-sm bg-base-300 rounded px-3 py-2"
                    >
                      {Calendar.strftime(booking.slot.date, "%b %d")} at {format_hour(
                        booking.slot.start_hour
                      )}
                      <span class="badge badge-xs ml-1">{String.upcase(booking.slot.slot_type)}</span>
                    </div>
                  </div>
                <% end %>
              </div>

              <%!-- Past Bookings --%>
              <div class="mt-4">
                <h4 class="font-bold text-sm mb-2">Past Bookings</h4>
                <%= if @user_past_bookings == [] do %>
                  <p class="text-sm text-base-content/60">No past bookings.</p>
                <% else %>
                  <div class="space-y-1">
                    <div
                      :for={booking <- @user_past_bookings}
                      class="text-sm bg-base-300 rounded px-3 py-2"
                    >
                      {Calendar.strftime(booking.slot.date, "%b %d")} at {format_hour(
                        booking.slot.start_hour
                      )}
                      <span class="badge badge-xs ml-1">{String.upcase(booking.slot.slot_type)}</span>
                      <span
                        :if={booking.status == "cancelled"}
                        class="badge badge-error badge-xs ml-1"
                      >
                        Cancelled
                      </span>
                    </div>
                  </div>
                <% end %>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
