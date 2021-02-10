defmodule ChatEx do
  @moduledoc """
  Запускает приложение
  Приходится выделять в отдельный модуль, поскольку иначе проблемы с тестами супервизора приложения
  """
  use Application

  def start(_type, _args) do
    ChatEx.Application.start_link([])
  end
end
