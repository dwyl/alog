defmodule TestApp.Application do
  @moduledoc false
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children =
      case Code.ensure_compiled(TestApp) do
        {:error, _} ->
          []

        {:module, TestApp} ->
          [supervisor(TestApp.Repo, [])]
      end

    opts = [strategy: :one_for_one, name: TestApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
