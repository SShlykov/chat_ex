defmodule ChatEx.UserSessionSupervisor do
  use DynamicSupervisor

  alias ChatEx.{UserSession, UserSessionRegistry}

  #
  # Клиентские функции
  #

  def create(session_id) do
    case find(session_id) do
      nil   ->
        start(session_id)
        :ok
      pid when is_pid(pid)  -> {:error, :already_exists}
    end
  end

  def subscribe(client_pid, [to: session_id]) do
    case find(session_id) do
      nil -> {:error, :session_not_exists}
      pid -> UserSession.subscribe(pid, client_pid)
    end
  end

  def notify(message, [to: session_id]) do
    case find(session_id) do
      nil -> {:error, :session_not_exists}
      pid -> UserSession.notify(pid, message)
    end
  end

  #
  # Серверные функции
  #

  def start_link(opts \\ []) do
    DynamicSupervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  defp start(session_id) do
    try do
      name = {:via, Registry, {UserSessionRegistry, session_id}}
      DynamicSupervisor.start_child(__MODULE__, {UserSession, name})
    rescue
      _e -> {:error, :already_exists}
    end
  end

  defp find(session_id) do
    with {key, _val} <- Enum.find(ChatEx.TokenRepository.list_tokens, & elem(&1, 1) == session_id),
                  [{pid, _}]  <- Registry.lookup(UserSessionRegistry, key) do
      pid
    else
      _e -> nil
    end
  end
end
