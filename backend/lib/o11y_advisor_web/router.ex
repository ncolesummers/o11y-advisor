defmodule O11yAdvisorWeb.Router do
  use O11yAdvisorWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", O11yAdvisorWeb do
    pipe_through :api
  end
end
