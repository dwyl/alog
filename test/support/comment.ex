defmodule Alog.TestApp.Comment do
  use Ecto.Schema
  import Ecto.Changeset

  # I'd imagine we'll change string as the type but
  @primary_key {:cid, :string, autogenerate: false}
  schema "users" do
    field(:entry_id, :string)
    field(:comment, :string)
    field(:deleted, :boolean, default: false)
  end

  def changeset(comment_struct, attrs \\ %{}) do
    comment_struct
    |> cast(attrs, [:cid, :entry_id, :comment, :deleted])
  end
end