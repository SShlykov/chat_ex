defmodule ChatEx.UserSession do
  use GenServer

  defstruct clients: []

  def subscribe(pid, client_pid), do: GenServer.call(pid, {:subscribe, client_pid})
  def notify(pid, message), do: GenServer.cast(pid, {:send, message})

  #
  # Серверные функции
  #
  def start_link(name) do
    GenServer.start_link(__MODULE__, %__MODULE__{}, name: name)
  end
  def init(state), do:  {:ok, state}

  def handle_call({:subscribe, client_pid}, _from, state), do: {:reply, :ok, %__MODULE__{state | clients: [client_pid|state.clients]} }

  def handle_cast({:send, message}, state) do
    Enum.each(state.clients, &Kernel.send(&1, message))
    {:noreply, state}
  end
end
