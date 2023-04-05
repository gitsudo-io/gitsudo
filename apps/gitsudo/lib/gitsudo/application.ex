defmodule Gitsudo.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Gitsudo.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Gitsudo.PubSub},
      # Start Finch
      {Finch, name: Gitsudo.Finch},
      # Start a worker by calling: Gitsudo.Worker.start_link(arg)
      Gitsudo.Events.AsyncWorker
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Gitsudo.Supervisor)
  end
end
