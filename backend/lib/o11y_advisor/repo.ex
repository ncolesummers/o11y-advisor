defmodule O11yAdvisor.Repo do
  use Ecto.Repo,
    otp_app: :o11y_advisor,
    adapter: Ecto.Adapters.Postgres
end
