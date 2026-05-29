defmodule O11yAdvisor.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      O11yAdvisorWeb.Telemetry,
      O11yAdvisor.Repo,
      {DNSCluster, query: Application.get_env(:o11y_advisor, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: O11yAdvisor.PubSub},
      # Start a worker by calling: O11yAdvisor.Worker.start_link(arg)
      # {O11yAdvisor.Worker, arg},
      # Start to serve requests, typically the last entry
      O11yAdvisorWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: O11yAdvisor.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    O11yAdvisorWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
