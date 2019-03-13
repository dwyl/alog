defmodule Alog.Repo.Migrations.CreateComments do
  use Ecto.Migration

  def change do
    create table(:comments, primary_key: false) do
      add(:cid, :string, primary_key: true)
      add(:entry_id, :string)
      add(:deleted, :boolean, default: false)
      add(:comment, :string)

      timestamps()
    end
  end
end
