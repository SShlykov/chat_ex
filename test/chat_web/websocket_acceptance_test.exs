defmodule ChatEx.Web.WebSocketAcceptanceTest do
  use ExUnit.Case, async: true
  import WebSocketClient

  setup_all do
    Enum.each([:cowlib, :cowboy, :ranch], &(Application.start(&1)))
  end

  setup do
    start_supervised! ChatEx.Application
    :ok
  end

  describe "Клиент отправляет не валидный токен: " do
    test "400 Bad Request" do
      result = connect_to websocket_chat_url(with: "AN_INVALID_ACCESS_TOKEN"), forward_to: self()

      assert result == {:error, %WebSockex.RequestError{code: 400, message: "Bad Request"}}
    end
  end

  describe "Запрос без токена - " do
    test "400 Bad Request" do
      result = connect_to websocket_chat_url(), forward_to: self()

      assert result == {:error, %WebSockex.RequestError{code: 400, message: "Bad Request"}}
    end
  end

  describe "Присоединение к комнате" do
    setup :connect_as_a_user

    test "Получение приветственного сообщения", %{client: client} do
      send_as_text(client, "{\"command\":\"join\"}")

      assert_receive "{\"room\":\"init\",\"message\":\"К комнате init подключился a-user!\"}"
    end

    test "Все пользователи должны получить сообщения", %{client: client} do
      connect_to websocket_chat_url(with: "A_USER_ACCESS_TOKEN"), forward_to: self()

      send_as_text(client, "{\"command\":\"join\"}")

      assert_receive "{\"room\":\"init\",\"message\":\"К комнате init подключился a-user!\"}"
      assert_receive "{\"room\":\"init\",\"message\":\"К комнате init подключился a-user!\"}"
    end
  end

  describe "Общение в чате" do
    setup :connect_as_a_user

    test "получение сообщение назад", %{client: client} do
      send_as_text(client, "{\"command\":\"join\"}")

      send_as_text(client, "{\"room\":\"init\",\"message\":\"Hello folks!\"}")

      assert_receive "{\"room\":\"init\",\"message\":\"К комнате init подключился a-user!\"}"
    end

    test "поглучение ошибки, когда комнаты", %{client: client} do
      send_as_text(client, "{\"room\":\"unexisting_room\",\"message\":\"a message\"}")

      assert_receive "{\"error\":\"unexisting_room does not exists\"}"
    end
  end

  describe "При создании новой комнаты" do
    setup :connect_as_a_user

    test "получаю сообщение об ошибке, если комната уже есть", %{client: client} do
      send_as_text(client, "{\"command\":\"create\",\"room\":\"a_chat_room\"}")
      send_as_text(client, "{\"command\":\"create\",\"room\":\"a_chat_room\"}")

      assert_receive "{\"error\":\"a_chat_room уже существует\"}"
    end

    test "получаю сообщение об успехе", %{client: client} do
      send_as_text(client, "{\"command\":\"create\",\"room\":\"another_room\"}")

      assert_receive "{\"success\":\"Комната another_room была создана\"}"
    end
  end

  describe "Присоединяюсь к новой комнате" do
    setup :connect_as_a_user

    test "получаю сообщение о создании", %{client: client} do
      send_as_text(client, "{\"command\":\"create\",\"room\":\"a_chat_room\"}")
      send_as_text(client, "{\"command\":\"join\",\"room\":\"a_chat_room\"}")

      assert_receive "{\"success\":\"Комната a_chat_room была создана\"}"
    end
  end

  describe "Ошибки" do
    setup :connect_as_a_user

    test "join twice the same chat room", %{client: client} do
      send_as_text(client, "{\"command\":\"join\"}")

      assert_receive "{\"room\":\"init\",\"message\":\"К комнате init подключился a-user!\"}"
      refute_receive "{\"room\":\"init\",\"message\":\"К комнате init подключился a-user!\"}"

      send_as_text(client, "{\"command\":\"join\"}")
      assert_receive "{\"error\":\"Вы уже присоединились к init комнате!\"}"
    end

    test "send invalid messages", %{client: client} do
      send_as_text(client, "this is an invalid message")

      refute_receive _
    end

    test "send invalid commands", %{client: client} do
      send_as_text(client, "{\"something\":\"invalid\"}")

      refute_receive _
    end
  end

  defp connect_as_a_user(_context) do
    user = "a-user"
    access_token = "A_USER_ACCESS_TOKEN"

    ChatEx.UserSessionSupervisor.create(user)
    ChatEx.TokenRepository.add(access_token, user)

    {:ok, client} = connect_to websocket_chat_url(with: access_token), forward_to: self()
    {:ok, client: client}
  end

  defp websocket_chat_url() do
    "ws://localhost:4000/ws/chat"
  end

  defp websocket_chat_url([with: access_token]) do
    "#{websocket_chat_url()}?access_token=#{access_token}"
  end
end
