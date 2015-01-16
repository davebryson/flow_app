defmodule Flow.App do
  use Application

  # Starting point of the application. Starts the Supervisor.

  def start(_type, _args) do
    Flow.Supervisor.start_link
  end
end
