defmodule TheDungeonWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use TheDungeonWeb, :html

  embed_templates "layouts/*"

  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <main>
      {render_slot(@inner_block)}
    </main>

    <footer class="bg-base-300 border-t border-base-content/10">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
          <div>
            <span class="text-xl font-black tracking-tighter text-primary uppercase">
              The Dungeon
            </span>
            <p class="mt-3 text-sm text-base-content/60 leading-relaxed">
              Private gym and personal training in the heart of Stanhope, County Durham.
            </p>
          </div>
          <div>
            <h4 class="text-sm font-bold uppercase tracking-wider text-base-content/80 mb-4">
              Quick Links
            </h4>
            <ul class="space-y-2 text-sm">
              <li>
                <a href="#about" class="text-base-content/60 hover:text-primary transition-colors">
                  About
                </a>
              </li>
              <li>
                <a href="#services" class="text-base-content/60 hover:text-primary transition-colors">
                  Services
                </a>
              </li>
              <li>
                <a href="#results" class="text-base-content/60 hover:text-primary transition-colors">
                  Results
                </a>
              </li>
              <li>
                <a href="#pricing" class="text-base-content/60 hover:text-primary transition-colors">
                  Pricing
                </a>
              </li>
              <li>
                <a href="#booking" class="text-base-content/60 hover:text-primary transition-colors">
                  Book a Consultation
                </a>
              </li>
            </ul>
          </div>
          <div>
            <h4 class="text-sm font-bold uppercase tracking-wider text-base-content/80 mb-4">
              Contact
            </h4>
            <ul class="space-y-2 text-sm text-base-content/60">
              <li>60 Front Street, Stanhope</li>
              <li>Durham, DL13 2UE</li>
              <li>
                <a href="tel:07825337993" class="hover:text-primary transition-colors">
                  07825 337993
                </a>
              </li>
              <li>
                <a
                  href="mailto:thedungeonptgym@gmail.com"
                  class="hover:text-primary transition-colors"
                >
                  thedungeonptgym@gmail.com
                </a>
              </li>
            </ul>
          </div>
        </div>
        <div class="mt-10 pt-6 border-t border-base-content/10 text-center text-xs text-base-content/40">
          &copy; {Date.utc_today().year} The Dungeon PT. All rights reserved.
        </div>
      </div>
    </footer>

    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
