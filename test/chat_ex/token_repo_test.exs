defmodule ChatEx.TokenRepositoryTest do
  use ExUnit.Case, async: true
  alias ChatEx.TokenRepository

  setup do
    start_supervised! TokenRepository
    :ok
  end

  test "Возвращает nil, когда токен не существует" do
    assert TokenRepository.find_user_session_by("token") == nil
  end

  test "возвращает сессию по токену" do
    TokenRepository.add("token", "user-session")

    assert TokenRepository.find_user_session_by("token") == "user-session"
  end
end
