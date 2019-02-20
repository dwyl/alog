defmodule AlogTest.MigrationTest do
  use ExUnit.Case, async: true

  alias Alog.Repo

  # Avoid migration out of order warnings
  @moduletag :capture_log
  @base_migration 3_000_000

  setup do
    {:ok, migration_number: System.unique_integer([:positive]) + @base_migration}
  end

  defmodule AddColumnIfNotExistsMigration do
    use Ecto.Migration

    def up do
      create(table(:add_col_if_not_exists_migration, primary_key: false))

      alter table(:add_col_if_not_exists_migration) do
        add_if_not_exists(:value, :integer)
        add_if_not_exists(:to_be_added, :integer)
      end

      execute(
        "INSERT INTO add_col_if_not_exists_migration (value, to_be_added, cid, entry_id, inserted_at, updated_at) VALUES (1, 2, 'a', 'a', '2019-02-10 10:04:30', '2019-02-10 10:04:30')"
      )
    end

    def down do
      drop(table(:add_col_if_not_exists_migration))
    end
  end

  defmodule DropColumnIfExistsMigration do
    use Ecto.Migration

    def up do
      create table(:drop_col_if_exists_migration, primary_key: false) do
        add(:value, :integer)
        add(:to_be_removed, :integer)
      end

      execute(
        "INSERT INTO drop_col_if_exists_migration (value, to_be_removed, cid, entry_id, inserted_at, updated_at) VALUES (1, 2, 'a', 'a', '2019-02-10 10:04:30', '2019-02-10 10:04:30')"
      )

      alter table(:drop_col_if_exists_migration) do
        remove_if_exists(:to_be_removed, :integer)
      end
    end

    def down do
      drop(table(:drop_col_if_exists_migration))
    end
  end

  defmodule DuplicateTableMigration do
    use Ecto.Migration

    def change do
      create_if_not_exists(table(:duplicate_table, primary_key: false))
      create_if_not_exists(table(:duplicate_table, primary_key: false))
    end
  end

  defmodule NoErrorOnConditionalColumnMigration do
    use Ecto.Migration

    def up do
      create(table(:no_error_on_conditional_column_migration, primary_key: false))

      alter table(:no_error_on_conditional_column_migration) do
        add_if_not_exists(:value, :integer)
        add_if_not_exists(:value, :integer)

        remove_if_exists(:value, :integer)
        remove_if_exists(:value, :integer)
      end
    end

    def down do
      drop(table(:no_error_on_conditional_column_migration))
    end
  end

  defmodule DefaultMigration do
    use Ecto.Migration

    def up do
      create table(:default_migration, primary_key: false) do
        add(:name, :string)
      end

      execute(
        "INSERT INTO default_migration (name, cid, entry_id, inserted_at, updated_at) VALUES ('a', 'b', 'a', '2019-02-10 10:04:30', '2019-02-10 10:04:30')"
      )
    end

    def down do
      drop(table(:default_migration))
    end
  end

  defmodule ExistingDefaultMigration do
    use Ecto.Migration

    def change do
      create table(:existing_default_migration, primary_key: false) do
        timestamps()
      end
    end
  end

  import Ecto.Query, only: [from: 2]
  import Ecto.Migrator, only: [up: 4, down: 4]

  test "logs Postgres notice messages" do
    log =
      ExUnit.CaptureLog.capture_log(fn ->
        num = @base_migration + System.unique_integer([:positive])
        up(Repo, num, DuplicateTableMigration, log: false)
      end)

    assert log =~ ~s(relation "duplicate_table" already exists, skipping)
  end

  @tag :no_error_on_conditional_column_migration
  test "add if not exists and drop if exists does not raise on failure", %{migration_number: num} do
    assert :ok == up(Repo, num, NoErrorOnConditionalColumnMigration, log: false)
    assert :ok == down(Repo, num, NoErrorOnConditionalColumnMigration, log: false)
  end

  @tag :add_column_if_not_exists
  test "add column if not exists", %{migration_number: num} do
    assert :ok == up(Repo, num, AddColumnIfNotExistsMigration, log: false)

    assert [2] == Repo.all(from(p in "add_col_if_not_exists_migration", select: p.to_be_added))

    :ok = down(Repo, num, AddColumnIfNotExistsMigration, log: false)
  end

  @tag :remove_column_if_exists
  test "remove column when exists", %{migration_number: num} do
    assert :ok == up(Repo, num, DropColumnIfExistsMigration, log: false)

    assert catch_error(
             Repo.all(from(p in "drop_col_if_exists_migration", select: p.to_be_removed))
           )

    :ok = down(Repo, num, DropColumnIfExistsMigration, log: false)
  end

  test "creates default columns", %{migration_number: num} do
    assert :ok == up(Repo, num, DefaultMigration, log: false)

    assert [%{name: _, cid: _, entry_id: _, inserted_at: _, updated_at: _, deleted: false}] =
             Repo.all(
               from(a in "default_migration",
                 select: %{
                   name: a.name,
                   cid: a.cid,
                   entry_id: a.entry_id,
                   inserted_at: a.inserted_at,
                   updated_at: a.updated_at,
                   deleted: a.deleted
                 }
               )
             )

    :ok = down(Repo, num, DefaultMigration, log: false)
  end

  test "existing default columns don't throw errors", %{migration_number: num} do
    assert :ok == up(Repo, num, ExistingDefaultMigration, log: false)

    :ok = down(Repo, num, ExistingDefaultMigration, log: false)
  end
end
