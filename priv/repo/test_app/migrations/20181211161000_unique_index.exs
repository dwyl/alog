defmodule Alog.Repo.Migrations.UniqueIndex do
  use Ecto.Migration

  def change do
    create table(:unique) do
      add(:name, :string)
      add(:entry_id, :string)
      add(:deleted, :boolean, default: false)

      timestamps()
    end

    create(unique_index(:unique, :name))
  end
end
