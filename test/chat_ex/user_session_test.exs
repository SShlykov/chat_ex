defmodule ChatEx.UserSessionSupervisorTest do
  use ExUnit.Case, async: true

  alias ChatEx.UserSessionSupervisor

  @valid_session_id "super-test-user"
  @valid_message "this is a valid message"

  setup do
    start_supervised! UserSessionSupervisor
    start_supervised! {Registry, keys: :unique, name: ChatEx.UserSessionRegistry}
    :ok
  end

  describe "Создание пользовательской сессии: " do
    test "получен ок при создании сессии" do
      result = UserSessionSupervisor.create(@valid_session_id)

      assert result == :ok
    end

    test "получена ошибка при повторном создания пользовательской сессии" do
      UserSessionSupervisor.create(@valid_session_id)

      result = UserSessionSupervisor.create(@valid_session_id)

      assert result == {:error, :already_exists}
    end
  end

  describe "Работа подписки на пользовательскую сессию: " do
    test "получен ок, когда сессия существует" do
      UserSessionSupervisor.create(@valid_session_id)

      result = UserSessionSupervisor.subscribe(self(), to: @valid_session_id)

      assert result == :ok
    end

    test "получена ошибка, когда сессия не существует" do
      result = UserSessionSupervisor.subscribe(self(), to: @valid_session_id)

      assert result == {:error, :session_not_exists}
    end
  end

  describe "При отправке сообщений в пользовательской сессии: " do
    test "сообщение доставлено" do
      UserSessionSupervisor.create(@valid_session_id)

      result = UserSessionSupervisor.notify(@valid_message, to: @valid_session_id)

      assert result == :ok
    end

    test "ошибка из-за того, что сессия не существует" do
      result = UserSessionSupervisor.notify(@valid_message, to: @valid_session_id)

      assert result == {:error, :session_not_exists}
    end
  end

  describe "Получение сообщения по подписке: " do
    test "сообщение получено и перенаправлено всем подписчикам" do
      UserSessionSupervisor.create(@valid_session_id)
      UserSessionSupervisor.subscribe(self(), to: @valid_session_id)

      UserSessionSupervisor.notify(@valid_message, to: @valid_session_id)

      assert_receive @valid_message
    end
  end

  describe "Получение сообщения без подписки: " do
    test "не происходит" do
      UserSessionSupervisor.create(@valid_session_id)

      UserSessionSupervisor.notify(@valid_message, to: @valid_session_id)

      refute_receive @valid_message
    end
  end
end
