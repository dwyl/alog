defmodule Alog.Repo.Migrations.CreateComments do
  use Ecto.Migration

  def change do
    create table(:comments, primary_key: false) do
      # cid & entry_id need to be removed later as they should be handled in execute_ddl I believe
      add(:cid, :string, primary_key: true)
      add(:entry_id, :string)
      add(:comment, :string)
      add(:deleted, :boolean, default: false)
    end
  end
end
