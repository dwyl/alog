defmodule Alog.TestApp.Application do
  @moduledoc false
  use Application

  def start(_type, _args) do
    opts = [strategy: :one_for_one, name: Alog.TestApp.Supervisor]

    Supervisor.start_link([Alog.Repo], opts)
  end
end
