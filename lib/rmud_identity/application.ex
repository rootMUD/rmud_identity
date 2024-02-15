defmodule RmudIdentity.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      RmudIdentityWeb.Telemetry,
      # Start the Ecto repository
      RmudIdentity.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: RmudIdentity.PubSub},
      # Start Finch
      {Finch, name: RmudIdentity.Finch},
      # Start the Endpoint (http/https)
      RmudIdentityWeb.Endpoint
      # Start a worker by calling: RmudIdentity.Worker.start_link(arg)
      # {RmudIdentity.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: RmudIdentity.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    RmudIdentityWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
