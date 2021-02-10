defmodule ChatEx.Room do
  use GenServer

  alias ChatEx.UserSessionSupervisor

  defstruct sessions: [], name: nil

  #
  # Клиентские функции
  #

  def join(pid, session_id), do: GenServer.call(pid, {:join, session_id})

  def send(pid, message, [as: session_id]) do
    :ok = GenServer.call(pid, {:send, message, :as, session_id})
  end

  #
  # Серверные функции
  #

  def start_link(name), do: create(name)
  def create(name = {:via, Registry, {_registry_name, room_name}}) do
    GenServer.start_link(__MODULE__, %__MODULE__{name: room_name}, name: name)
  end
  def create(room_name), do: GenServer.start_link(__MODULE__, %__MODULE__{name: room_name}, name: String.to_atom(room_name))

  def init(state), do: {:ok, state}

  def handle_call({:join, session_id}, _from, state) do
    {message, new_state} = case joined?(state.sessions, session_id) do
      true -> {{:error, :already_joined}, state}
      false -> {:ok, add_session(state, session_id)}
    end

    {:reply, message, new_state}
  end

  def handle_call({:send, message, :as, session_id}, _from, state = %__MODULE__{name: name}) do
    Enum.each(state.sessions, &UserSessionSupervisor.notify(%{from: session_id, room: name, message: message}, to: &1))
    {:reply, :ok, state}
  end

  #
  # Приватные функции
  #

  defp joined?(sessions, session_id), do: Enum.member?(sessions, session_id)

  defp add_session(state = %__MODULE__{sessions: sessions}, session_id) do
    %__MODULE__{state | sessions: [session_id|sessions]}
  end
end
