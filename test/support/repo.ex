defmodule Alog.Repo do
  use Ecto.Repo,
    otp_app: :alog,
    adapter: Alog
end
