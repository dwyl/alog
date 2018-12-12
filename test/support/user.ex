defmodule Alog.TestApp.User do
  use Ecto.Schema
  use Alog
  import Ecto.Changeset

  schema "users" do
    field(:name, :string)
    field(:username, :string)
    field(:postcode, :string)
    field(:entry_id, :string)
    field(:deleted, :boolean, default: false)

    has_many(:items, Alog.TestApp.Item, foreign_key: :owner)

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :username, :postcode, :deleted])
    |> validate_required([:name, :username, :postcode])
    |> unique_constraint(:username)
  end

  def user_and_item_changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :username, :postcode, :deleted])
    |> validate_required([:name, :username, :postcode])
    |> cast_assoc(:items)
  end
end
