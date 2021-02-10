defmodule ChatEx.SocketHandler do
  @behaviour :cowboy_websocket

  alias ChatEx.Client

  def init(request, state) do
    token = get_access_token(request)

    case Client.validate_access_token(token) do
      {:ok, session} -> {:cowboy_websocket, request, session, %{idle_timeout: 10 * 60 * 1000}}
      {:error, _} -> {:ok, :cowboy_req.reply(400, request), state}
    end
  end

  @spec websocket_init(any) :: {:ok, any}
  def websocket_init(session) do
    Client.subscribe_to_user_session(self(), session)

    {:ok, session}
  end

  def websocket_handle({:text, command_as_json}, session_id) do
    case Poison.decode(command_as_json) do
      {:error, _reason} -> {:ok, session_id}
      {:ok, command} -> handle(command, session_id)
    end
  end

  def websocket_handle(_message, session_id) do
    {:ok, session_id}
  end

  def websocket_info(message, session_id) do
    {:reply, {:text, Poison.encode!(message)}, session_id}
  end

  defp handle(%{"command" => "join", "room" => room}, session_id) do
    case Client.join_room(room, session_id) do
      :ok ->
        {:ok, session_id}
      {:error, message} ->
        {:reply, {:text, Poison.encode!(%{error: message})}, session_id}
    end
  end

  defp handle(command = %{"command" => "join"}, session_id) do
    handle(Map.put(command, "room", "init"), session_id)
  end

  defp handle(%{"room" => room, "message" => message}, session_id) do
    case Client.send_message_to_chat(message, room, session_id) do
      {:error, message} ->
        {:reply, {:text, Poison.encode!(%{ error: message })}, session_id}
      :ok ->
        {:ok, session_id}
    end
  end

  defp handle(%{"command" => "create", "room" => room}, session_id) do
    response = case Client.create_room(room) do
      {:ok, message} -> %{success: message}
      {:error, message} -> %{error: message}
    end

    {:reply, {:text, Poison.encode!(response)}, session_id}
  end

  defp handle(_not_handled_command, session_id), do: {:ok, session_id}

  @spec get_access_token(:cowboy_req.req()) :: binary() | nil
  def get_access_token(req) do
    case Enum.find(:cowboy_req.parse_qs(req), & elem(&1, 0) == "access_token") do
      {"access_token", access_token}  -> access_token
      _                               -> nil
    end
  end
end
