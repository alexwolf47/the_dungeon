defmodule TheDungeonWeb.ProfileLive do
  use TheDungeonWeb, :live_view

  alias TheDungeon.Scheduling
  alias TheDungeon.Profiles
  alias TheDungeon.Profiles.Profile

  @impl true
  def mount(_params, _session, socket) do
    %{current_scope: %{user: user}} = socket.assigns
    profile = Profiles.get_profile_by_user_id(user.id) || %Profile{}

    socket =
      socket
      |> assign(:page_title, "My Profile")
      |> assign(:profile, profile)
      |> assign(:editing, false)
      |> assign(:tab, :upcoming)
      |> assign(:upcoming_bookings, Scheduling.list_user_bookings(user, :upcoming))
      |> assign(:past_bookings, Scheduling.list_user_bookings(user, :past))
      |> assign_profile_form(profile)

    {:ok, socket}
  end

  @impl true
  def handle_event("edit_profile", _params, socket) do
    {:noreply, assign(socket, :editing, true)}
  end

  @impl true
  def handle_event("cancel_edit", _params, socket) do
    socket =
      socket
      |> assign(:editing, false)
      |> assign_profile_form(socket.assigns.profile)

    {:noreply, socket}
  end

  @impl true
  def handle_event("validate_profile", %{"profile" => profile_params}, socket) do
    changeset =
      socket.assigns.profile
      |> Profiles.change_profile(profile_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :profile_form, to_form(changeset, as: "profile"))}
  end

  @impl true
  def handle_event("save_profile", %{"profile" => profile_params}, socket) do
    %{current_scope: %{user: user}, profile: profile} = socket.assigns

    result =
      case profile do
        %Profile{id: id} when not is_nil(id) ->
          Profiles.update_profile(profile, profile_params)

        _ ->
          Profiles.create_profile(user, profile_params)
      end

    case result do
      {:ok, updated_profile} ->
        socket =
          socket
          |> assign(:profile, updated_profile)
          |> assign(:editing, false)
          |> assign_profile_form(updated_profile)
          |> put_flash(:info, "Profile updated successfully!")

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, :profile_form, to_form(changeset, as: "profile"))}
    end
  end

  @impl true
  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :tab, String.to_existing_atom(tab))}
  end

  @impl true
  def handle_event("cancel_booking", %{"id" => booking_id}, socket) do
    %{current_scope: %{user: user}} = socket.assigns
    booking = Scheduling.get_booking!(booking_id)

    case Scheduling.cancel_booking(booking) do
      {:ok, _booking} ->
        {:noreply,
         socket
         |> put_flash(:info, "Booking cancelled.")
         |> assign(:upcoming_bookings, Scheduling.list_user_bookings(user, :upcoming))
         |> assign(:past_bookings, Scheduling.list_user_bookings(user, :past))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to cancel booking.")}
    end
  end

  defp assign_profile_form(socket, %Profile{} = profile) do
    changeset = Profiles.change_profile(profile)
    assign(socket, :profile_form, to_form(changeset, as: "profile"))
  end

  defp format_hour(hour) when hour < 12, do: "#{hour}:00 AM"
  defp format_hour(12), do: "12:00 PM"
  defp format_hour(hour), do: "#{hour - 12}:00 PM"

  defp format_hour_range(hour), do: "#{format_hour(hour)} - #{format_hour(hour + 1)}"

  defp humanize(nil), do: ""

  defp humanize(value) when is_binary(value) do
    value
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp format_list(nil), do: ""
  defp format_list(list) when is_list(list), do: Enum.map_join(list, ", ", &humanize/1)

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen pt-20 pb-10 px-4 sm:px-6 lg:px-8 max-w-4xl mx-auto">
      <h1 class="text-3xl font-black mb-6">My Profile</h1>

      <%!-- Profile Info Card --%>
      <div class="card bg-base-200 shadow-xl mb-8">
        <div class="card-body">
          <%= if @editing do %>
            {render_edit_form(assigns)}
          <% else %>
            {render_profile_display(assigns)}
          <% end %>
        </div>
      </div>

      <%!-- Bookings Section --%>
      <div class="card bg-base-200 shadow-xl">
        <div class="card-body">
          <div class="tabs tabs-bordered mb-4">
            <button
              class={["tab", @tab == :upcoming && "tab-active"]}
              phx-click="switch_tab"
              phx-value-tab="upcoming"
            >
              Upcoming ({length(@upcoming_bookings)})
            </button>
            <button
              class={["tab", @tab == :history && "tab-active"]}
              phx-click="switch_tab"
              phx-value-tab="history"
            >
              History ({length(@past_bookings)})
            </button>
          </div>

          <%= if @tab == :upcoming do %>
            <%= if @upcoming_bookings == [] do %>
              <p class="text-base-content/60 text-center py-4">No upcoming bookings.</p>
            <% else %>
              <div class="space-y-3">
                <div :for={booking <- @upcoming_bookings} class="card bg-base-300">
                  <div class="card-body p-4 flex-row items-center justify-between">
                    <div>
                      <p class="font-bold">
                        {Calendar.strftime(booking.slot.date, "%A, %B %d, %Y")}
                      </p>
                      <p class="text-sm">{format_hour_range(booking.slot.start_hour)}</p>
                      <span class={[
                        "badge badge-sm mt-1",
                        booking.slot.slot_type == "pt" && "badge-accent",
                        booking.slot.slot_type == "bootcamp" && "badge-secondary"
                      ]}>
                        {if booking.slot.slot_type == "pt",
                          do: "Personal Training",
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
          <% else %>
            <%= if @past_bookings == [] do %>
              <p class="text-base-content/60 text-center py-4">No past sessions.</p>
            <% else %>
              <div class="space-y-3">
                <div :for={booking <- @past_bookings} class="card bg-base-300">
                  <div class="card-body p-4 flex-row items-center justify-between">
                    <div>
                      <p class="font-bold">
                        {Calendar.strftime(booking.slot.date, "%A, %B %d, %Y")}
                      </p>
                      <p class="text-sm">{format_hour_range(booking.slot.start_hour)}</p>
                      <span class={[
                        "badge badge-sm mt-1",
                        booking.slot.slot_type == "pt" && "badge-accent",
                        booking.slot.slot_type == "bootcamp" && "badge-secondary"
                      ]}>
                        {if booking.slot.slot_type == "pt",
                          do: "Personal Training",
                          else: booking.slot.bootcamp_name || "Bootcamp"}
                      </span>
                    </div>
                    <span class={[
                      "badge",
                      booking.status == "confirmed" && "badge-success",
                      booking.status == "cancelled" && "badge-error"
                    ]}>
                      {String.capitalize(booking.status)}
                    </span>
                  </div>
                </div>
              </div>
            <% end %>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp render_profile_display(assigns) do
    ~H"""
    <div class="flex items-center justify-between mb-4">
      <h2 class="card-title">Profile Information</h2>
      <button phx-click="edit_profile" class="btn btn-primary btn-sm">
        <.icon name="hero-pencil-square-mini" class="size-4 mr-1" /> Edit
      </button>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
      <div>
        <p class="text-base-content/60">Email</p>
        <p class="font-semibold">{@current_scope.user.email}</p>
      </div>

      <%= if @profile && @profile.id do %>
        <div>
          <p class="text-base-content/60">Name</p>
          <p class="font-semibold">{@profile.full_name}</p>
        </div>
        <div :if={@profile.phone_number}>
          <p class="text-base-content/60">Phone</p>
          <p class="font-semibold">{@profile.phone_number}</p>
        </div>
        <div :if={@profile.instagram_handle}>
          <p class="text-base-content/60">Instagram</p>
          <p class="font-semibold">{@profile.instagram_handle}</p>
        </div>
        <div :if={@profile.preferred_contact_method}>
          <p class="text-base-content/60">Preferred Contact</p>
          <p class="font-semibold">{humanize(@profile.preferred_contact_method)}</p>
        </div>
        <div :if={@profile.training_preference}>
          <p class="text-base-content/60">Training Preference</p>
          <p class="font-semibold">{humanize(@profile.training_preference)}</p>
        </div>
        <div :if={@profile.current_fitness_level}>
          <p class="text-base-content/60">Fitness Level</p>
          <p class="font-semibold">{humanize(@profile.current_fitness_level)}</p>
        </div>
        <div :if={@profile.training_frequency}>
          <p class="text-base-content/60">Training Frequency</p>
          <p class="font-semibold">{humanize(@profile.training_frequency)}</p>
        </div>
        <div :if={@profile.available_days && @profile.available_days != []}>
          <p class="text-base-content/60">Available Days</p>
          <p class="font-semibold">{format_list(@profile.available_days)}</p>
        </div>
        <div :if={@profile.available_times && @profile.available_times != []}>
          <p class="text-base-content/60">Available Times</p>
          <p class="font-semibold">{format_list(@profile.available_times)}</p>
        </div>
        <div :if={@profile.personalised_meal_plan}>
          <p class="text-base-content/60">Meal Plan</p>
          <p class="font-semibold">{humanize(@profile.personalised_meal_plan)}</p>
        </div>
        <div :if={@profile.primary_fitness_goals} class="col-span-2">
          <p class="text-base-content/60">Fitness Goals</p>
          <p class="font-semibold">{@profile.primary_fitness_goals}</p>
        </div>
        <div :if={@profile.areas_to_focus} class="col-span-2">
          <p class="text-base-content/60">Areas to Focus</p>
          <p class="font-semibold">{@profile.areas_to_focus}</p>
        </div>
        <div :if={@profile.medical_conditions} class="col-span-2">
          <p class="text-base-content/60">Medical Conditions</p>
          <p class="font-semibold">{@profile.medical_conditions}</p>
        </div>
        <div :if={@profile.current_medications} class="col-span-2">
          <p class="text-base-content/60">Current Medications</p>
          <p class="font-semibold">{@profile.current_medications}</p>
        </div>
        <div :if={@profile.prior_trainer_experience} class="col-span-2">
          <p class="text-base-content/60">Prior Trainer Experience</p>
          <p class="font-semibold">{@profile.prior_trainer_experience}</p>
        </div>
        <div :if={@profile.additional_fitness_info} class="col-span-2">
          <p class="text-base-content/60">Additional Fitness Info</p>
          <p class="font-semibold">{@profile.additional_fitness_info}</p>
        </div>
        <div :if={@profile.training_goals_expectations} class="col-span-2">
          <p class="text-base-content/60">Training Goals & Expectations</p>
          <p class="font-semibold">{@profile.training_goals_expectations}</p>
        </div>
        <div :if={@profile.specific_requests} class="col-span-2">
          <p class="text-base-content/60">Specific Requests</p>
          <p class="font-semibold">{@profile.specific_requests}</p>
        </div>
      <% else %>
        <div class="col-span-2">
          <p class="text-base-content/60">
            No profile information yet. Click Edit to fill in your details.
          </p>
        </div>
      <% end %>
    </div>
    """
  end

  defp render_edit_form(assigns) do
    ~H"""
    <div class="flex items-center justify-between mb-4">
      <h2 class="card-title">Edit Profile</h2>
      <button phx-click="cancel_edit" class="btn btn-ghost btn-sm">Cancel</button>
    </div>

    <.form for={@profile_form} phx-change="validate_profile" phx-submit="save_profile">
      <div class="space-y-6">
        <%!-- Personal Information --%>
        <div>
          <h3 class="text-sm font-bold uppercase tracking-wider text-base-content/60 mb-3">
            Personal Information
          </h3>
          <div class="space-y-3">
            <.input field={@profile_form[:full_name]} type="text" label="Full Name" required />
            <.input field={@profile_form[:phone_number]} type="tel" label="Phone Number" />
            <.input field={@profile_form[:instagram_handle]} type="text" label="Instagram Handle" />

            <div class="fieldset mb-2">
              <span class="label mb-2">Preferred Contact Method</span>
              <div class="flex flex-wrap gap-4">
                <label
                  :for={
                    method <- [
                      {"phone", "Phone"},
                      {"email", "Email"},
                      {"instagram", "Instagram"},
                      {"text", "Text"}
                    ]
                  }
                  class="flex items-center gap-2 cursor-pointer"
                >
                  <input
                    type="radio"
                    name={@profile_form[:preferred_contact_method].name}
                    value={elem(method, 0)}
                    checked={
                      to_string(@profile_form[:preferred_contact_method].value) == elem(method, 0)
                    }
                    class="radio radio-primary radio-sm"
                  />
                  <span class="text-sm">{elem(method, 1)}</span>
                </label>
              </div>
            </div>
          </div>
        </div>

        <%!-- Training Preferences --%>
        <div>
          <h3 class="text-sm font-bold uppercase tracking-wider text-base-content/60 mb-3">
            Training Preferences
          </h3>
          <div class="space-y-3">
            <div class="fieldset mb-2">
              <span class="label mb-2">Training Preference</span>
              <div class="flex flex-wrap gap-4">
                <label
                  :for={pref <- [{"in_person", "In Person"}, {"online", "Online"}, {"both", "Both"}]}
                  class="flex items-center gap-2 cursor-pointer"
                >
                  <input
                    type="radio"
                    name={@profile_form[:training_preference].name}
                    value={elem(pref, 0)}
                    checked={to_string(@profile_form[:training_preference].value) == elem(pref, 0)}
                    class="radio radio-primary radio-sm"
                  />
                  <span class="text-sm">{elem(pref, 1)}</span>
                </label>
              </div>
            </div>

            <.input
              field={@profile_form[:primary_fitness_goals]}
              type="textarea"
              label="Primary Fitness Goals"
              placeholder="What are you looking to achieve?"
            />
            <.input
              field={@profile_form[:areas_to_focus]}
              type="textarea"
              label="Areas to Focus"
              placeholder="Any specific areas you want to work on?"
            />

            <div class="fieldset mb-2">
              <span class="label mb-2">Personalised Meal Plan</span>
              <div class="flex flex-wrap gap-4">
                <label
                  :for={
                    opt <- [{"yes", "Yes"}, {"no", "No"}, {"more_information", "More Information"}]
                  }
                  class="flex items-center gap-2 cursor-pointer"
                >
                  <input
                    type="radio"
                    name={@profile_form[:personalised_meal_plan].name}
                    value={elem(opt, 0)}
                    checked={to_string(@profile_form[:personalised_meal_plan].value) == elem(opt, 0)}
                    class="radio radio-primary radio-sm"
                  />
                  <span class="text-sm">{elem(opt, 1)}</span>
                </label>
              </div>
            </div>

            <div class="fieldset mb-2">
              <span class="label mb-2">Current Fitness Level</span>
              <div class="flex flex-wrap gap-4">
                <label
                  :for={
                    level <- [
                      {"beginner", "Beginner"},
                      {"intermediate", "Intermediate"},
                      {"advanced", "Advanced"}
                    ]
                  }
                  class="flex items-center gap-2 cursor-pointer"
                >
                  <input
                    type="radio"
                    name={@profile_form[:current_fitness_level].name}
                    value={elem(level, 0)}
                    checked={to_string(@profile_form[:current_fitness_level].value) == elem(level, 0)}
                    class="radio radio-primary radio-sm"
                  />
                  <span class="text-sm">{elem(level, 1)}</span>
                </label>
              </div>
            </div>
          </div>
        </div>

        <%!-- Schedule & Availability --%>
        <div>
          <h3 class="text-sm font-bold uppercase tracking-wider text-base-content/60 mb-3">
            Schedule & Availability
          </h3>
          <div class="space-y-3">
            <div class="fieldset mb-2">
              <span class="label mb-2">Training Frequency</span>
              <div class="flex flex-wrap gap-4">
                <label
                  :for={
                    freq <- [
                      {"none", "None yet"},
                      {"once_per_week", "Once per week"},
                      {"two_to_three_per_week", "2-3 per week"},
                      {"four_plus_per_week", "4+ per week"}
                    ]
                  }
                  class="flex items-center gap-2 cursor-pointer"
                >
                  <input
                    type="radio"
                    name={@profile_form[:training_frequency].name}
                    value={elem(freq, 0)}
                    checked={to_string(@profile_form[:training_frequency].value) == elem(freq, 0)}
                    class="radio radio-primary radio-sm"
                  />
                  <span class="text-sm">{elem(freq, 1)}</span>
                </label>
              </div>
            </div>

            <div class="fieldset mb-2">
              <span class="label mb-2">Available Days</span>
              <div class="flex flex-wrap gap-3">
                <label
                  :for={
                    day <- [
                      {"monday", "Mon"},
                      {"tuesday", "Tue"},
                      {"wednesday", "Wed"},
                      {"thursday", "Thu"},
                      {"friday", "Fri"},
                      {"saturday", "Sat"},
                      {"sunday", "Sun"}
                    ]
                  }
                  class="flex items-center gap-2 cursor-pointer"
                >
                  <input
                    type="checkbox"
                    name={@profile_form[:available_days].name <> "[]"}
                    value={elem(day, 0)}
                    checked={
                      elem(day, 0) in ((@profile_form[:available_days].value || []) |> List.wrap())
                    }
                    class="checkbox checkbox-primary checkbox-sm"
                  />
                  <span class="text-sm">{elem(day, 1)}</span>
                </label>
              </div>
              <input type="hidden" name={@profile_form[:available_days].name <> "[]"} value="" />
            </div>

            <div class="fieldset mb-2">
              <span class="label mb-2">Available Times</span>
              <div class="flex flex-wrap gap-3">
                <label
                  :for={
                    time <- [
                      {"early_morning", "Early Morning (6-8am)"},
                      {"morning", "Morning (8-12pm)"},
                      {"afternoon", "Afternoon (12-5pm)"},
                      {"evening", "Evening (5-9pm)"}
                    ]
                  }
                  class="flex items-center gap-2 cursor-pointer"
                >
                  <input
                    type="checkbox"
                    name={@profile_form[:available_times].name <> "[]"}
                    value={elem(time, 0)}
                    checked={
                      elem(time, 0) in ((@profile_form[:available_times].value || []) |> List.wrap())
                    }
                    class="checkbox checkbox-primary checkbox-sm"
                  />
                  <span class="text-sm">{elem(time, 1)}</span>
                </label>
              </div>
              <input type="hidden" name={@profile_form[:available_times].name <> "[]"} value="" />
            </div>
          </div>
        </div>

        <%!-- Health & Background --%>
        <div>
          <h3 class="text-sm font-bold uppercase tracking-wider text-base-content/60 mb-3">
            Health & Background
          </h3>
          <div class="space-y-3">
            <.input
              field={@profile_form[:medical_conditions]}
              type="textarea"
              label="Medical Conditions"
              placeholder="Any medical conditions we should know about?"
            />
            <.input
              field={@profile_form[:current_medications]}
              type="textarea"
              label="Current Medications"
              placeholder="Any medications you're currently taking?"
            />
            <.input
              field={@profile_form[:prior_trainer_experience]}
              type="textarea"
              label="Prior Trainer Experience"
              placeholder="Have you worked with a personal trainer before?"
            />
          </div>
        </div>

        <%!-- Goals & Expectations --%>
        <div>
          <h3 class="text-sm font-bold uppercase tracking-wider text-base-content/60 mb-3">
            Goals & Expectations
          </h3>
          <div class="space-y-3">
            <.input
              field={@profile_form[:additional_fitness_info]}
              type="textarea"
              label="Additional Fitness Information"
              placeholder="Anything else about your fitness background?"
            />
            <.input
              field={@profile_form[:training_goals_expectations]}
              type="textarea"
              label="Training Goals & Expectations"
              placeholder="What do you expect from your training experience?"
            />
            <.input
              field={@profile_form[:specific_requests]}
              type="textarea"
              label="Specific Requests"
              placeholder="Any specific requests or preferences?"
            />
          </div>
        </div>
      </div>

      <div class="mt-8 flex justify-between">
        <button type="button" phx-click="cancel_edit" class="btn btn-ghost">Cancel</button>
        <.button type="submit" variant="primary">
          Save Profile <.icon name="hero-check-mini" class="size-4 ml-1" />
        </.button>
      </div>
    </.form>
    """
  end
end
