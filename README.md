# alog

alog is an [Hex package](https://hexdocs.pm/alog) (Elixir) which
provides some helper functions to make it easy to insert and retrieve the data you need in your Elixir/Phoenix applications.

Instead of using CRUD concept to manage data, alog makes sure to keep the data immutable in the database.
This means the data is not updated nor deleted but instead a new version representing the new state of the data is inserted in the database.

## Why

- See all history of the data
- Debugging is easier
- Analytics is built-in

## Usage

### Install alog

  Add alog to your package dependencies in the `mix.exs` file:

  ```elixir
  defp deps do
    [{:alog, "~> 0.1"}]
  end
  ```

  Update your dependencies with `mix deps.get`

### Define your schemas

  For alog to work the schemas need to have defined:
  - `inserted_at` field. You can use the [timestamps/1](https://hexdocs.pm/ecto/Ecto.Schema.html#timestamps/1) functions.

  Since Ecto v3.0 the type of `inserted_at` is by default `naive_datetime`. We recommand to change it to `naive_datetime_usec` to save the timestamps with a precision of microseconds:

    - Update your `Repo` configuration

    ```elixir
    config :my_app, MyApp.Repo,
    migration_timestamps: [type: :naive_datetime_usec]
    ```

    - Define the timestamps option in your schemas

    ```elixir
    @timestamps_opts [type: :naive_datetime_usec]
    ```

    see the `Calendar type` secction of http://blog.plataformatec.com.br/2018/10/a-sneak-peek-at-ecto-3-0-breaking-changes/

  - `entry_id` field with the type `string`.

  alog will save a new version of an item each time its state is changed. To keep track of all the states we need to a unique id which represent an item(and its older versions). alog use [Ecto.UUID](https://hexdocs.pm/ecto/Ecto.UUID.html) to generate the `entry_id`

  - `deleted` field with the type `boolean` default to `false`.

  alog will not remove items from the database. Instead it represent a deletion with the `deleted` field.

  Once your schemas are defined, at the top of the one you wish to use append only functions for, `use` this module:

  ``` elixir
  defmodule MyApp.User do
    use Ecto.Schema
    use Alog

    import Ecto.Changeset

    @timestamps_opts [type: :naive_datetime_usec]
    schema "users" do
      ...
      timestamps()
    end

    def changeset(user, attrs) do
      ...
    end
  end
  ```

  The append only functions will then be available to call as part of your schema:

    - `Users.get`
    - `Users.get_by`
    - `Users.insert`
    - `Users.update`
    - `Users.get_history`
    - `Users.delete`
    - `Users.preload`


  Alog expects your `Repo` to belong to the same base module as the schema.
  So if your schema is `MyApp.User`, or `MyApp.Accounts.User`, your Repo should be `MyApp.Repo`.

## Useful links

  - A step by step guide on how to create append only applications [phoenix-ecto-append-only-log-example](https://github.com/dwyl/phoenix-ecto-append-only-log-example)

  - [Lambda architecture](https://en.wikipedia.org/wiki/Lambda_architecture)
