defmodule GitHub.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  require Logger

  @impl true
  def start(type, args) do
    Logger.debug("start(#{inspect(type)}, #{inspect(args)})")

    children = [
      # Start the Ecto repository
      GitHub.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: GitHub.PubSub},
      # Start Finch
      {Finch, name: GitHub.Finch}
      # Start a worker by calling: GitHub.Worker.start_link(arg)
      # {GitHub.Worker, arg}
    ]

    Logger.debug("github_app_id: #{Application.fetch_env!(:github, GitHub)[:github_app_id]}")

    Supervisor.start_link(children, strategy: :one_for_one, name: GitHub.Supervisor)
  end
end
