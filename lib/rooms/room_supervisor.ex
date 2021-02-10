defmodule ChatEx.RoomSupervisor do
  use DynamicSupervisor
  @supervisor_name :chatroom_supervisor
  alias ChatEx.{Room, RoomRegistry}

  #
  # Клиентские функции
  #

  def create(room) do
    case find(room) do
      {:ok, _pid} -> {:error, :already_exists}
      {:error, :unexisting_room} ->
        {:ok, _pid} = start(room)
    end
  end

  def join(room, [as: session_id]) do
    case find(room) do
      {:ok, pid}                  -> try_join_chatroom(pid, session_id)
      {:error, :unexisting_room}  -> {:error, :unexisting_room}
    end
  end

  def send(message, [to: room, as: session_id]) do
    case find(room) do
      {:ok, pid} -> Room.send(pid, message, as: session_id)
      error -> error
    end
  end

  def list_rooms do
    RoomRegistry
    |> Registry.select([{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2", :"$3"}}]}])
    |> Enum.map(& elem(&1, 0))
  end

  #
  # Серверные функции
  #

  def start_link(_opts) do
    DynamicSupervisor.start_link(__MODULE__, [], name: @supervisor_name)
  end

  @impl true
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one, extra_arguments: [])
  end

  defp start(room_name) do
    name = {:via, Registry, {RoomRegistry, room_name}}

    DynamicSupervisor.start_child(@supervisor_name, {Room, name})
  end


  #
  # Приватные функции
  #


  defp try_join_chatroom(chatroom_pid, session_id) do
    case Room.join(chatroom_pid, session_id) do
      :ok -> :ok
      {:error, :already_joined} -> {:error, :already_joined}
    end
  end

  defp find(room) do
    case Registry.lookup(RoomRegistry, room) do
      [] -> {:error, :unexisting_room}
      [{pid, nil}] -> {:ok, pid}
    end
  end
end
