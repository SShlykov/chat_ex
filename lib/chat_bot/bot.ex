defmodule ChatEx.Bot do
  @moduledoc """
  В данном случае это просто scheduler который с определнным промежутком пишет сообщение.
  """
  use GenServer
  @name "chat_bot"

  def init(_args) do
    schedule()
    job()
    {:ok, %{}}
  end
  def start_link(args), do: GenServer.start_link(__MODULE__, args)

  def handle_info(:job, state) do
    schedule()
    job()
    {:noreply, state}
  end

  defp job do
    room_list = ChatEx.RoomSupervisor.list_rooms()

    Enum.each(room_list, &make_message/1)
    :ok
  end
  defp schedule, do: Process.send_after(self(), :job, rand_time())
  defp rand_time, do: :rand.uniform(6) * 1000
  defp make_message(room_name) do
    ChatEx.Client.send_message_to_chat("hello from bot to room #{room_name}", room_name, @name)
  end
end
