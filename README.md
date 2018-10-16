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

  Alog expects your `Repo` to belong to the same base module as the schema.
  So if your schema is `MyApp.User`, or `MyApp.Accounts.User`, your Repo should be `MyApp.Repo`.