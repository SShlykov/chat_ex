defmodule ChatEx.Application do
  use Supervisor

  @http_options [
    dispatch: ChatEx.Router.dispatch(),
    port: 4000
  ]

  def start_link(opts), do: Supervisor.start_link(__MODULE__, :ok, opts)

  @impl true
  def init(:ok) do
    children = [
      {Registry, keys: :unique, name: ChatEx.RoomRegistry},
      {Registry, keys: :unique, name: ChatEx.UserSessionRegistry},
      ChatEx.RoomSupervisor,
      ChatEx.UserSessionSupervisor,
      ChatEx.TokenRepository,
      ChatEx.Tasks.Setup,
      Plug.Cowboy.child_spec(scheme: :http, plug: ChatEx.Router, options: @http_options),
      ChatEx.Bot,
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
