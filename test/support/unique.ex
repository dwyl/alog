defmodule Alog.TestApp.Unique do
  use Ecto.Schema
  use Alog
  import Ecto.Changeset

  schema "unique" do
    field(:name, :string)
    field(:entry_id, :string)
    field(:deleted, :boolean, default: false)

    timestamps()
  end

  @doc false
  def changeset(unique, attrs) do
    unique
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
