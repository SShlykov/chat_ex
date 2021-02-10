
defmodule ChatEx.ClientTest do
  use ExUnit.Case, async: true

  import Mock

  alias ChatEx.{RoomSupervisor, Client, UserSessionSupervisor}

  test "Успешно создает комнату" do
    with_mock(RoomSupervisor, create: fn(_) -> {:ok, :created} end) do
      result = Client.create_room("a room")

      assert result == {:ok, "Комната a room была создана"}
      assert called RoomSupervisor.create("a room")
    end
  end

  test "Ошибка, когда комната существует" do
    with_mock(RoomSupervisor, create: fn(_) -> {:error, :already_exists} end) do
      result = Client.create_room("a room")

      assert result ==  {:error, "a room уже существует"}
      assert called RoomSupervisor.create("a room")
    end
  end

  test "Возвращает ошибку, если комната не существует" do
    with_mocks([
      {RoomSupervisor, [], join: fn(_, _) -> {:error, :unexisting_room} end},
      {UserSessionSupervisor, [], notify: fn(_, _) -> nil end}
    ]) do
      result = Client.join_room("a room", "a user id")

      assert result == {:error, "Комната a room не существует"}
      refute called UserSessionSupervisor.notify(%{room: "a room", message: "welcome to the a room chat room, a user id!"}, to: "a user id")
    end
  end

  test "return an error message when already joined the chat room" do
    with_mocks([
      {RoomSupervisor, [], join: fn(_, _) -> {:error, :already_joined} end},
      {UserSessionSupervisor, [], notify: fn(_, _) -> nil end}
    ]) do
      result = Client.join_room("a room", "a user id")

      assert result == {:error, "Вы уже присоединились к a room комнате!"}
      refute called UserSessionSupervisor.notify(%{room: "a room", message: "welcome to the a room chat room, a user id!"}, to: "a user id")
    end
  end

  # test "Оповещает пользователя при присоединении" do
  #   with_mocks([
  #     {RoomSupervisor, [], join: fn(_, _) -> :ok end},
  #     {UserSessionSupervisor, [], notify: fn(_, _) -> nil end}
  #   ]) do
  #     result = Client.join_room("a room", "a user id")

  #     assert result == :ok
  #     assert called UserSessionSupervisor.notify(%{room: "a room", message: "welcome to the a room chat room, a user id!"}, to: "a user id")
  #   end
  # end
end
