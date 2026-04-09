defmodule TheDungeonWeb.UserRegistrationLive do
  use TheDungeonWeb, :live_view

  alias TheDungeon.Accounts
  alias TheDungeon.Accounts.User
  alias TheDungeon.Profiles
  alias TheDungeon.Profiles.Profile
  alias TheDungeon.Repo

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={assigns[:current_scope]}>
      <div class="min-h-screen pt-24 pb-16">
        <div class="max-w-2xl mx-auto px-4 sm:px-6">
          <div class="text-center mb-8">
            <h1 class="text-3xl font-black tracking-tight uppercase">
              Join The Dungeon
            </h1>
            <p class="text-base-content/60 mt-2">
              {step_subtitle(@current_step)}
            </p>
          </div>

          <.step_indicator current_step={@current_step} total_steps={5} />

          <div class="card bg-base-200 shadow-xl">
            <div class="card-body">
              {render_step(assigns)}
            </div>
          </div>

          <p :if={@current_step == 1} class="text-center text-sm text-base-content/60 mt-6">
            Already have an account?
            <.link navigate={~p"/users/log-in"} class="text-primary font-semibold hover:underline">
              Log in
            </.link>
          </p>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp step_subtitle(1), do: "Create your account"
  defp step_subtitle(2), do: "Tell us about your training preferences"
  defp step_subtitle(3), do: "When are you available?"
  defp step_subtitle(4), do: "Health & background information"
  defp step_subtitle(5), do: "Your goals & expectations"

  defp render_step(%{current_step: 1} = assigns) do
    ~H"""
    <.form for={@user_form} id="registration-form" phx-change="validate" phx-submit="next_step">
      <div class="space-y-4">
        <h2 class="text-lg font-bold mb-4">Account Details</h2>

        <.input field={@user_form[:email]} type="email" label="Email" required />

        <h2 class="text-lg font-bold mt-6 mb-4">Personal Information</h2>

        <.input field={@profile_form[:full_name]} type="text" label="Full Name" required />
        <.input field={@profile_form[:phone_number]} type="tel" label="Phone Number (optional)" />
        <.input
          field={@profile_form[:instagram_handle]}
          type="text"
          label="Instagram Handle (optional)"
        />

        <div class="fieldset mb-2">
          <span class="label mb-2">
            Preferred Contact Method
            <span class="text-base-content/40 text-xs font-normal">(optional)</span>
          </span>
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
                checked={to_string(@profile_form[:preferred_contact_method].value) == elem(method, 0)}
                class="radio radio-primary radio-sm"
              />
              <span class="text-sm">{elem(method, 1)}</span>
            </label>
          </div>
          <p
            :for={
              msg <-
                Enum.map(
                  @profile_form[:preferred_contact_method].errors || [],
                  &translate_error/1
                )
            }
            class="mt-1.5 flex gap-2 items-center text-sm text-error"
          >
            <.icon name="hero-exclamation-circle" class="size-5" />
            {msg}
          </p>
        </div>
      </div>

      <div class="mt-8 flex justify-end">
        <.button type="submit" variant="primary">
          Next Step <.icon name="hero-arrow-right-mini" class="size-4 ml-1" />
        </.button>
      </div>
    </.form>
    """
  end

  defp render_step(%{current_step: 2} = assigns) do
    ~H"""
    <.form for={@profile_form} id="registration-form" phx-change="validate" phx-submit="next_step">
      <div class="space-y-4">
        <p class="text-sm text-base-content/50 italic">All fields on this step are optional.</p>

        <div class="fieldset mb-2">
          <span class="label mb-2">
            Training Preference
            <span class="text-base-content/40 text-xs font-normal">(optional)</span>
          </span>
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
          <p
            :for={
              msg <-
                Enum.map(@profile_form[:training_preference].errors || [], &translate_error/1)
            }
            class="mt-1.5 flex gap-2 items-center text-sm text-error"
          >
            <.icon name="hero-exclamation-circle" class="size-5" />
            {msg}
          </p>
        </div>

        <.input
          field={@profile_form[:primary_fitness_goals]}
          type="textarea"
          label="Primary Fitness Goals (optional)"
          placeholder="What are you looking to achieve?"
        />
        <.input
          field={@profile_form[:areas_to_focus]}
          type="textarea"
          label="Areas to Focus (optional)"
          placeholder="Any specific areas you want to work on?"
        />

        <div class="fieldset mb-2">
          <span class="label mb-2">
            Personalised Meal Plan
            <span class="text-base-content/40 text-xs font-normal">(optional)</span>
          </span>
          <div class="flex flex-wrap gap-4">
            <label
              :for={opt <- [{"yes", "Yes"}, {"no", "No"}, {"more_information", "More Information"}]}
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
          <span class="label mb-2">
            Current Fitness Level
            <span class="text-base-content/40 text-xs font-normal">(optional)</span>
          </span>
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

      <div class="mt-8 flex justify-between">
        <.button type="button" phx-click="prev_step">
          <.icon name="hero-arrow-left-mini" class="size-4 mr-1" /> Back
        </.button>
        <div class="flex gap-2">
          <.button type="button" phx-click="skip_step">Skip</.button>
          <.button type="submit" variant="primary">
            Next Step <.icon name="hero-arrow-right-mini" class="size-4 ml-1" />
          </.button>
        </div>
      </div>
    </.form>
    """
  end

  defp render_step(%{current_step: 3} = assigns) do
    ~H"""
    <.form for={@profile_form} id="registration-form" phx-change="validate" phx-submit="next_step">
      <div class="space-y-4">
        <p class="text-sm text-base-content/50 italic">All fields on this step are optional.</p>

        <div class="fieldset mb-2">
          <span class="label mb-2">
            Training Frequency
            <span class="text-base-content/40 text-xs font-normal">(optional)</span>
          </span>
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
          <span class="label mb-2">
            Available Days <span class="text-base-content/40 text-xs font-normal">(optional)</span>
          </span>
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
          <span class="label mb-2">
            Available Times <span class="text-base-content/40 text-xs font-normal">(optional)</span>
          </span>
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

      <div class="mt-8 flex justify-between">
        <.button type="button" phx-click="prev_step">
          <.icon name="hero-arrow-left-mini" class="size-4 mr-1" /> Back
        </.button>
        <div class="flex gap-2">
          <.button type="button" phx-click="skip_step">Skip</.button>
          <.button type="submit" variant="primary">
            Next Step <.icon name="hero-arrow-right-mini" class="size-4 ml-1" />
          </.button>
        </div>
      </div>
    </.form>
    """
  end

  defp render_step(%{current_step: 4} = assigns) do
    ~H"""
    <.form for={@profile_form} id="registration-form" phx-change="validate" phx-submit="next_step">
      <div class="space-y-4">
        <p class="text-sm text-base-content/50 italic">All fields on this step are optional.</p>

        <.input
          field={@profile_form[:medical_conditions]}
          type="textarea"
          label="Medical Conditions (optional)"
          placeholder="Any medical conditions we should know about?"
        />
        <.input
          field={@profile_form[:current_medications]}
          type="textarea"
          label="Current Medications (optional)"
          placeholder="Any medications you're currently taking?"
        />
        <.input
          field={@profile_form[:prior_trainer_experience]}
          type="textarea"
          label="Prior Trainer Experience (optional)"
          placeholder="Have you worked with a personal trainer before?"
        />
      </div>

      <div class="mt-8 flex justify-between">
        <.button type="button" phx-click="prev_step">
          <.icon name="hero-arrow-left-mini" class="size-4 mr-1" /> Back
        </.button>
        <div class="flex gap-2">
          <.button type="button" phx-click="skip_step">Skip</.button>
          <.button type="submit" variant="primary">
            Next Step <.icon name="hero-arrow-right-mini" class="size-4 ml-1" />
          </.button>
        </div>
      </div>
    </.form>
    """
  end

  defp render_step(%{current_step: 5} = assigns) do
    ~H"""
    <.form for={@profile_form} id="registration-form" phx-change="validate" phx-submit="save">
      <div class="space-y-4">
        <p class="text-sm text-base-content/50 italic">All fields on this step are optional.</p>

        <.input
          field={@profile_form[:additional_fitness_info]}
          type="textarea"
          label="Additional Fitness Information (optional)"
          placeholder="Anything else about your fitness background?"
        />
        <.input
          field={@profile_form[:training_goals_expectations]}
          type="textarea"
          label="Training Goals & Expectations (optional)"
          placeholder="What do you expect from your training experience?"
        />
        <.input
          field={@profile_form[:specific_requests]}
          type="textarea"
          label="Specific Requests (optional)"
          placeholder="Any specific requests or preferences?"
        />
      </div>

      <div class="mt-8 flex justify-between">
        <.button type="button" phx-click="prev_step">
          <.icon name="hero-arrow-left-mini" class="size-4 mr-1" /> Back
        </.button>
        <div class="flex gap-2">
          <.button type="button" phx-click="save_skip">Skip & Finish</.button>
          <.button type="submit" variant="primary">
            Complete Sign Up <.icon name="hero-check-mini" class="size-4 ml-1" />
          </.button>
        </div>
      </div>
    </.form>
    """
  end

  def mount(_params, _session, socket) do
    user_changeset = Accounts.change_user_registration(%User{})
    profile_changeset = Profiles.change_profile_step(%Profile{}, %{}, 1)

    socket =
      socket
      |> assign(page_title: "Sign Up")
      |> assign(current_step: 1)
      |> assign(accumulated_params: %{})
      |> assign(check_errors: false)
      |> assign_form(user_changeset, profile_changeset)

    {:ok, socket, temporary_assigns: []}
  end

  def handle_event("validate", params, %{assigns: %{current_step: 1}} = socket) do
    user_params = Map.get(params, "user", %{})
    profile_params = Map.get(params, "profile", %{})

    user_changeset =
      Accounts.change_user_registration(%User{}, user_params, validate_unique: false)

    profile_changeset = Profiles.change_profile_step(%Profile{}, profile_params, 1)

    socket =
      socket
      |> assign_form(
        Map.put(user_changeset, :action, :validate),
        Map.put(profile_changeset, :action, :validate)
      )

    {:noreply, socket}
  end

  def handle_event("validate", %{"profile" => profile_params}, socket) do
    %{current_step: step, accumulated_params: accumulated} = socket.assigns

    merged = Map.merge(accumulated, profile_params)
    profile_changeset = Profiles.change_profile_step(%Profile{}, merged, step)

    socket = assign_form(socket, nil, Map.put(profile_changeset, :action, :validate))

    {:noreply, socket}
  end

  def handle_event("next_step", params, %{assigns: %{current_step: 1}} = socket) do
    user_params = Map.get(params, "user", %{})
    profile_params = Map.get(params, "profile", %{})

    user_changeset =
      Accounts.change_user_registration(%User{}, user_params, validate_unique: false)

    profile_changeset = Profiles.change_profile_step(%Profile{}, profile_params, 1)

    if user_changeset.valid? and profile_changeset.valid? do
      accumulated = Map.merge(socket.assigns.accumulated_params, profile_params)

      next_profile_changeset = Profiles.change_profile_step(%Profile{}, accumulated, 2)

      socket =
        socket
        |> assign(current_step: 2)
        |> assign(accumulated_params: Map.merge(accumulated, %{"_user" => user_params}))
        |> assign_form(nil, next_profile_changeset)

      {:noreply, socket}
    else
      socket =
        socket
        |> assign(check_errors: true)
        |> assign_form(
          Map.put(user_changeset, :action, :validate),
          Map.put(profile_changeset, :action, :validate)
        )

      {:noreply, socket}
    end
  end

  def handle_event("next_step", %{"profile" => profile_params}, socket) do
    %{current_step: step, accumulated_params: accumulated} = socket.assigns

    merged = Map.merge(accumulated, profile_params)
    profile_changeset = Profiles.change_profile_step(%Profile{}, merged, step)

    if profile_changeset.valid? do
      advance_step(socket, merged)
    else
      socket =
        socket
        |> assign(check_errors: true)
        |> assign_form(nil, Map.put(profile_changeset, :action, :validate))

      {:noreply, socket}
    end
  end

  def handle_event("skip_step", _params, socket) do
    advance_step(socket, socket.assigns.accumulated_params)
  end

  def handle_event("prev_step", _params, socket) do
    %{current_step: step, accumulated_params: accumulated} = socket.assigns
    prev_step = max(step - 1, 1)

    if prev_step == 1 do
      user_params = Map.get(accumulated, "_user", %{})

      user_changeset =
        Accounts.change_user_registration(%User{}, user_params, validate_unique: false)

      profile_changeset = Profiles.change_profile_step(%Profile{}, accumulated, 1)

      socket =
        socket
        |> assign(current_step: 1)
        |> assign_form(user_changeset, profile_changeset)

      {:noreply, socket}
    else
      profile_changeset = Profiles.change_profile_step(%Profile{}, accumulated, prev_step)

      socket =
        socket
        |> assign(current_step: prev_step)
        |> assign_form(nil, profile_changeset)

      {:noreply, socket}
    end
  end

  def handle_event("save", %{"profile" => profile_params}, socket) do
    all_profile_params = Map.merge(socket.assigns.accumulated_params, profile_params)
    do_save(socket, all_profile_params)
  end

  def handle_event("save_skip", _params, socket) do
    do_save(socket, socket.assigns.accumulated_params)
  end

  defp do_save(socket, all_profile_params) do
    user_params = Map.get(socket.assigns.accumulated_params, "_user", %{})

    case create_user_and_profile(user_params, all_profile_params) do
      {:ok, %{user: user}} ->
        Accounts.UserNotifier.deliver_welcome_email(user)

        {:ok, _email} =
          Accounts.deliver_login_instructions(user, &url(~p"/users/log-in/#{&1}"))

        {:noreply,
         socket
         |> put_flash(
           :info,
           "Welcome to The Dungeon! Check your email to confirm your account and log in."
         )
         |> redirect(to: ~p"/users/log-in")}

      {:error, :user, changeset, _} ->
        socket =
          socket
          |> assign(current_step: 1)
          |> assign(check_errors: true)
          |> assign_form(
            Map.put(changeset, :action, :validate),
            Profiles.change_profile_step(%Profile{}, all_profile_params, 1)
          )
          |> put_flash(:error, "There was an issue with your account details. Please review.")

        {:noreply, socket}

      {:error, :profile, changeset, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "There was an issue saving your profile. Please try again.")
         |> assign_form(nil, Map.put(changeset, :action, :validate))}
    end
  end

  defp advance_step(socket, merged) do
    next_step = socket.assigns.current_step + 1
    next_profile_changeset = Profiles.change_profile_step(%Profile{}, merged, next_step)

    socket =
      socket
      |> assign(current_step: next_step)
      |> assign(accumulated_params: merged)
      |> assign_form(nil, next_profile_changeset)

    {:noreply, socket}
  end

  defp create_user_and_profile(user_params, profile_params) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:user, User.email_changeset(%User{}, user_params))
    |> Ecto.Multi.insert(:profile, fn %{user: user} ->
      %Profile{}
      |> Profile.changeset(profile_params)
      |> Ecto.Changeset.put_change(:user_id, user.id)
    end)
    |> Repo.transaction()
  end

  defp assign_form(socket, nil, profile_changeset) do
    assign(socket, profile_form: to_form(profile_changeset, as: "profile"))
  end

  defp assign_form(socket, user_changeset, profile_changeset) do
    socket
    |> assign(user_form: to_form(user_changeset, as: "user"))
    |> assign(profile_form: to_form(profile_changeset, as: "profile"))
  end
end
