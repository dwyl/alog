# alog
alog (Append-only Log) is an easy way to start using the Lambda/Kappa architecture in your Elixir/Phoenix Apps while still using PostgreSQL (with Ecto).

This module provides some helper functions to make it easy to insert and retrieve the data you need.

## Usage

  At the top of the schema you wish to use append only functions for, `use` this module:

  ``` elixir
  use Alog
  ```

  The append only functions will then be available to call as part of your schema.

  ## Example

  ``` elixir
  defmodule MyApp.User do
    use Ecto.Schema
    use Alog

    import Ecto.Changeset

    schema "users" do
      ...
    end

    def changeset(user, attrs) do
      ...
    end
  end
  ```

  ## Repo
  
  Alog expects your `Repo` to belong to the same base module as the schema.
  So if your schema is `MyApp.User`, or `MyApp.Accounts.User`, your Repo should be `MyApp.Repo`.

  ## Uniqueness

  Due to the append only manner in which Alog stores data, it is not compatible with tables that have Unique Indexes applied to any of their columns. If you wish to use alog, you will have to remove these indexes.

  For example, the following in a migration file would remove a unique index on the `email` column from the `users` table.

  ```
  drop(unique_index(:users, :email))
  ```

  See https://hexdocs.pm/ecto_sql/Ecto.Migration.html#content for more details.

  If you want to ensure each entry in your database has a unique field, you can use the [`Ecto.Changeset.unique_constraint/3`](https://hexdocs.pm/ecto/Ecto.Changeset.html#unique_constraint/3) function as normal, and Alog will ensure there are no repeated fields, other than those of the same entry, returning an invalid changeset if there are.