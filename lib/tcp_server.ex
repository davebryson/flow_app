defmodule TcpServer do

  # Simple Ranch based TCP Server
  defmodule VmProtocol do
    
    @behaviour :ranch_protocol
    @wait_for 30000 # Amount of time in milliseconds to wait for messages
    
    # Hook in to the supervisor chain
    def start_link(ref, socket, transport, opts) do
	    pid = spawn_link(__MODULE__, :init, [ref, socket, transport, opts])
	    {:ok, pid}
    end
        
    def init(ref, socket, transport, _opts) do
	    :ok = :ranch.accept_ack(ref)
	    loop(socket, transport)
    end
    
    # Main (simple) processing loop
    defp loop(socket, transport) do
	    case transport.recv(socket, 0, @wait_for) do
		    {:ok, data} ->
          # If you send Q, kill me...
          if data == "Q" do
            :erlang.exit(:die)
          else
            # Send data back.
            d = "from_vm: " <> data
			      transport.send(socket, d)
			      loop(socket, transport)
          end
        _ ->
			    :ok = transport.close(socket)
	    end
    end
  end

  
  # Supervise me...
  def start_link() do
    :application.ensure_started(:ranch)
    {:ok, _} = :ranch.start_listener(:flow_app_listener, 100,
                                     :ranch_tcp, [{:port, 5555}],
                                     VmProtocol, [])
  end
end
