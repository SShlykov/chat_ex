defmodule ChatEx.TokenRepository do
  use GenServer

  #
  # Клиентские функции
  #

  def add(access_token, user_session), do: :ok = GenServer.call(:access_token_repository, {:add, access_token, user_session})

  def find_user_session_by(access_token), do: GenServer.call(:access_token_repository, {:find_user_session_by, access_token})
  def list_tokens(), do: GenServer.call(:access_token_repository, :all_tokens)

  #
  # Серверные функции
  #

  def start_link(_opts), do: GenServer.start_link(__MODULE__, [], name: :access_token_repository)
  def init(_args), do: {:ok, %{}}
  def handle_call({:add, access_token, user_session}, _from, state), do: {:reply, :ok, Map.put(state, access_token, user_session)}
  def handle_call({:find_user_session_by, access_token}, _from, state), do: {:reply, Map.get(state, access_token), state}
  def handle_call(:all_tokens, _from, state), do: {:reply, state, state}
end
