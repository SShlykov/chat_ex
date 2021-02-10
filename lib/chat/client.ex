defmodule ChatEx.Client do
  @moduledoc """
  Простейший API чтобы
  """
  alias ChatEx.{RoomSupervisor, UserSessionSupervisor, TokenRepository}

  @spec create_room(binary()) :: {:error, binary()} | {:ok, binary()}
  def create_room(room) do
    case RoomSupervisor.create(room) do
      {:ok, _}                  -> {:ok, "Комната #{room} была создана"}
      {:error, :already_exists} -> {:error, "#{room} уже существует"}
    end
  end

  @spec join_room(binary(), binary()) :: :ok | {:error, any()}
  def join_room(room, user_id) do
    case RoomSupervisor.join(room, as: user_id) do
      :ok ->
        UserSessionSupervisor.notify(%{room: room, message: "К комнате #{room} подключился #{user_id}!"}, to: user_id)
        :ok
      {:error, :already_joined}   -> {:error, "Вы уже присоединились к #{room} комнате!"}
      {:error, :unexisting_room}  -> {:error, "Комната #{room} не существует"}
    end
  end

  @spec send_message_to_chat(binary(), binary(), binary()) :: :ok | {:error, binary()}
  def send_message_to_chat(message, room, user_id) do
    case RoomSupervisor.send(message, to: room, as: user_id) do
      :ok                         -> :ok
      {:error, :unexisting_room}  -> {:error, "#{room} does not exists"}
    end
  end

  @spec subscribe_to_user_session(any, any) :: any
  def subscribe_to_user_session(subscriber_pid, user_id), do: UserSessionSupervisor.subscribe(subscriber_pid, to: user_id)


  def validate_access_token(access_token) do
    Registry
    case TokenRepository.find_user_session_by(access_token) do
      nil     -> {:error, :access_token_invalid}
      session -> {:ok, session}
    end
  end
end
