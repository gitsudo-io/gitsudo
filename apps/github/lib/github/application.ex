defmodule GitHub.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  require Logger

  @impl true
  def start(type, args) do
    Logger.debug("start(#{inspect(type)}, #{inspect(args)})")

    app_id = Application.fetch_env!(:github, GitHub)[:github_app_id]
    Logger.debug("github_app_id: #{app_id}")

    key_pem =
      case key = System.fetch_env("GITHUB_APP_PRIVATE_KEY") do
        {:ok, key} when key != "" -> key
        _ -> File.read!(System.fetch_env!("GITHUB_APP_PRIVATE_KEY_FILE"))
      end

    children = [
      # Start the Ecto repository
      GitHub.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: GitHub.PubSub},
      # Start Finch
      {Finch, name: GitHub.Finch},
      # Start a worker by calling: GitHub.Worker.start_link(arg)
      {GitHub.TokenCache, app_id: app_id, key_pem: key_pem}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: GitHub.Supervisor)
  end
end
