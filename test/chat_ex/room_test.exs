defmodule ChatEx.RoomSupervisorTest do
  use ExUnit.Case, async: false

  import Mock

  alias ChatEx.{UserSessionSupervisor, RoomSupervisor}

  @room "test_room_name"
  @session_1 "a-user-session-1"
  @session_2 "a-user-session-2"
  @message "a message"

  setup do
    start_supervised! RoomSupervisor
    start_supervised! {Registry, keys: :unique, name: ChatEx.RoomRegistry}
    :ok
  end

  test "Оповестить всех пользователей комнаты о сообщении" do
    {:ok, chatroom} = RoomSupervisor.create(@room)
    RoomSupervisor.join(chatroom, [as: @session_1])

    with_mock UserSessionSupervisor, [notify: fn(_message, [to: _user_session_id]) -> :ok end] do
      expected_message = %{
        from: @session_2,
        room: @room,
        message: @message
      }

      RoomSupervisor.send(chatroom, to: @message, as: @session_2)

      UserSessionSupervisor.notify(expected_message, to: @session_1)

      assert_called UserSessionSupervisor.notify(expected_message, to: @session_1)
    end
  end
end
