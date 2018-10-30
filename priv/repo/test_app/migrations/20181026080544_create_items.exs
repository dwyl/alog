defmodule Alog.Repo.Migrations.CreateItems do
  use Ecto.Migration

  def change do
    create table(:items) do
      add(:name, :string)
      add(:entry_id, :string)
      add(:deleted, :boolean, default: false)
      add(:owner, references(:users))

      timestamps()
    end

    create table(:item_types) do
      add(:type, :string)
      add(:entry_id, :string)
      add(:deleted, :boolean, default: false)

      timestamps()
    end

    create table(:items_item_types, primary_key: false) do
      add(:item_id, references(:items, on_delete: :delete_all, column: :id, type: :id))

      add(:item_type_id, references(:item_types, on_delete: :delete_all, column: :id, type: :id))
    end
  end
end
