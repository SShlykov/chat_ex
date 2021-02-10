defmodule ChatEx.Tasks.Setup do
  use Task, restart: :transient

  alias ChatEx.{RoomSupervisor, UserSessionSupervisor, TokenRepository}

  @spec start_link(any) :: {:ok, pid}
  def start_link(_args), do: Task.start_link(__MODULE__, :run, [])

  @spec run :: :ok
  def run do
    :io.format("running ~n", [])

    RoomSupervisor.create("init")

    UserSessionSupervisor.create("person-one")
    UserSessionSupervisor.create("person-two")

    TokenRepository.add("person-one", "first_user")
    TokenRepository.add("person-two", "second_user")
  end
end
