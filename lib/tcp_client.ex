defmodule TcpClient do
  use GenServer
  require Logger

  # TCP Client. Runs as a separate independent process. It talks to TCPServer and forwards
  # any messages from Server back to the 'callback'. In our case that's the WS Server. 
  
  # State
  defmodule SocketState do
    defstruct sock: nil, callback: nil
  end

  # Callback is the PID of the WS
  def connect(host, port, callback) do
    # Calls init()
    GenServer.start_link(__MODULE__, [{host,port,callback}],name: __MODULE__)
  end

  # Write data to the endpoint
  def write(data) do
    GenServer.cast(__MODULE__,{:send, data})
  end

  # Close the socket
  def close() do
    GenServer.cast(__MODULE__,:close)
  end


  #GenServer callbacks below
  def init(args) do
    # Trap exits
    :erlang.process_flag(:trap_exit, true)
    # Host, Port, Callback
    [{h,p,c}] = args
    # Connect to Server
    {:ok, socket} = :gen_tcp.connect(String.to_char_list(h),p,[:binary,{:packet, :raw},{:active,true}])
    
    {:ok,%SocketState{sock: socket, callback: c}} 
  end

  # Async call to send data to server
  def handle_cast({:send,data},state) do
    :gen_tcp.send(state.sock, data)
    {:noreply,state}
  end

  # Async call to close the socket
  def handle_cast(:close,state) do
    :gen_tcp.close(state.sock)
    {:stop, :normal, state}
  end

  # Handle message from TCP Server and send it to the WS Server
  def handle_info({:tcp,_socket,data}, state) do
    # Forward info to Proxy websocket
    send(state.callback, {:proxy,data})
    {:noreply,state}
  end

  def handle_info({:tcp_closed, _socket},state) do 
    {:stop, :normal,state}
  end

  def handle_info({:tcp_error, _socket, reason},state) do
    Logger.error("TCP: " <> reason)
    {:stop, :tcp_error, state}
  end

  def handle_info({:'EXIT',_pid, reason},state) do
    {:noreply, state}
  end
  
end
