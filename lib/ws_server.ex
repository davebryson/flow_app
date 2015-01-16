defmodule WsServer do

  # Websocket handler
  defmodule SocketHandler do
    @behaviour :cowboy_websocket_handler
    require Logger
    alias :jsx, as: JSON
    
    
    def init({tcp, http}, req, _opts) do
      {:upgrade, :protocol, :cowboy_websocket}
    end

    def websocket_init(_TransportName, req, _opts) do
      # Use my PID identifier to send message to me.
      pid = self()
      # Connect to the TCP server
      TcpClient.connect("127.0.0.1",5555,pid)
      {:ok, req, []}
     end

     def websocket_terminate(_reason, _req, _state) do
       :ok
     end

     # Message from WS client (Javascript client in our case)
     def websocket_handle({:text, content}, req, state) do
       # Forward to TCP Server
       [a] = JSON.decode(content);
       {"message", x} = a
       TcpClient.write(x)

       # Don't echo back a reply (we could if we wanted...)
       {:ok, req, state}
     end

     # Inter communication. This is how the TCP socket talks to the WS process.  Ahhh... processes talking to processes...
     def websocket_info({:proxy,data}, req, state) do

       reply = JSON.encode(%{ reply: data})
       
       # send the new message to the Javascript (web page) client.
       { :reply, {:text, reply}, req, state}
     end

     
     # fallback message handler 
     def websocket_info(_info, req, state) do
       {:ok, req, state}
     end
  end

  # Start up the supervised WebServer and WS Server
  def start_link() do
    dispatch = :cowboy_router
    .compile([
      { :_,
        [
            {"/", :cowboy_static, {:priv_file, :flow_app, "index.html"}},
            {"/static/[...]", :cowboy_static, {:priv_dir,  :flow_app, "static_files"}},
            {"/websocket", WsServer.SocketHandler, []}
        ]
      }
    ])

    {:ok, _} = :cowboy.start_http(:http, 
                                  100, 
                                  [{:port, 8081}],
                                  [{:env, [{:dispatch, dispatch}]}])
    
  end
end
