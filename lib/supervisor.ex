defmodule Flow.Supervisor do
  use Supervisor

  # Supervisor starts the 'worker' processes below.
  def start_link do
    Supervisor.start_link(__MODULE__, :ok)
  end


  def init(:ok) do
    children = [
      worker(TcpServer, []),
      worker(WsServer, [])
    ]

    # When a worker dies, restart it
    supervise(children, strategy: :one_for_one)
  end
end
