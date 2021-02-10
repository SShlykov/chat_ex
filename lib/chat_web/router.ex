defmodule ChatEx.Router do
  @moduledoc """
  Router
  """
  use Plug.Router

  plug Plug.Static, at: "/", from: :chat_ex

  plug :match
  plug :dispatch

  plug Plug.Parsers, parsers: [:json], pass: ["application/json"], json_decoder: Jason

  require EEx
  EEx.function_from_file(:defp, :application_html, "lib/chat_web/templates/application.html.eex", [])

  get "/" do
    send_resp(conn, 200, application_html())
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end


  def dispatch do
    [
      {:_,
        [
          {"/ws/chat/", ChatEx.SocketHandler, []},
          {:_, Plug.Cowboy.Handler, {__MODULE__, []}}
        ]
      }
    ]
  end
end
