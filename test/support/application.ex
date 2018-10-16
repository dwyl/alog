defmodule Alog.TestApp.Application do
  @moduledoc false
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children =
      case Code.ensure_compiled(Alog.TestApp) do
        {:error, _} ->
          []

        {:module, Alog.TestApp} ->
          [supervisor(Alog.Repo, [])]
      end

    opts = [strategy: :one_for_one, name: Alog.TestApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
