defmodule Alog do
  @moduledoc """
  Behaviour that defines functions for accessing and inserting data in an
  Append Only database.

  ## Usage

  At the top of the schema you wish to use append only functions for, `use` this module:

      use Alog

  The append only functions will then be available to call as part of your schema.

  ## Example

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

  Alog expects your `Repo` to belong to the same base module as the schema.
  So if your schema is `MyApp.User`, or `MyApp.Accounts.User`, your Repo should be `MyApp.Repo`.

  Any schema that uses Alog must include the fields `:deleted` of type `:boolean` and default false,
  and `:entry_id` of type `:string`.

        field(:deleted, :boolean, default: false)
        field(:entry_id, :string)
  """

  @callback insert(map()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  @callback get(String.t()) :: Ecto.Schema.t() | nil | no_return()
  @callback get_by(Keyword.t() | map()) :: Ecto.Schema.t() | nil | no_return()
  @callback update(Ecto.Schema.t(), map()) ::
              {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  @callback get_history(Ecto.Schema.t()) :: [Ecto.Schema.t()] | no_return()
  @callback delete(Ecto.Schema.t()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  @callback preload(Ecto.Schema.t() | list(Ecto.Schema.t()), atom() | list()) ::
              Ecto.Schema.t() | list(Ecto.Schema.t())

  defmacro __using__(_opts) do
    quote location: :keep do
      @behaviour Alog
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_env) do
    quote generated: true, location: :keep do
      import Ecto.Query, only: [from: 2, subquery: 1]

      @repo __MODULE__ |> Module.split() |> List.first() |> Module.concat("Repo")

      if not Map.has_key?(%__MODULE__{}, :deleted) || not is_boolean(%__MODULE__{}.deleted) do
        raise """

        Your Schema must have a key :deleted, with type :boolean and default false.

        Add the following line to your schema:

            field(:deleted, :boolean, default: false)
        """
      end

      if not Map.has_key?(%__MODULE__{}, :entry_id) do
        raise """

        Your Schema must have a key :entry_id, with type :string

        Add the following line to your schema:

            field(:entry_id, :string)
        """
      end

      @doc """
      Applies a schema's changeset function and inserts it into the database.
      Adds an entry id to link it to future updates of the item.

          User.insert(attributes)
      """
      def insert(attrs) do
        %__MODULE__{}
        |> insert_entry_id()
        |> __MODULE__.changeset(attrs)
        |> @repo.insert()
      end

      @doc """
      Gets the item from the database that matches the given entry id.
      Gets the most recently inserted item if it is not marked as deleted.

          User.get("5ds4fg31-a7f1-2hd8-x56a-d4s3g7ded1vv2")
      """
      def get(entry_id) do
        sub =
          from(
            m in __MODULE__,
            where: m.entry_id == ^entry_id,
            order_by: [desc: :inserted_at],
            limit: 1,
            select: m
          )

        query = from(m in subquery(sub), where: not m.deleted, select: m)

        item = @repo.one(query)
      end

      @doc """
      Gets an item from the database that matches the given clause.
      """
      def get_by(clauses) do
        @repo.get_by(__MODULE__, clauses)
      end

      @doc """
      Updates an item in the database.
      Copies the current row, updates the relevant fields and appends
      it to the database table.

          User.get("5ds4fg31-a7f1-2hd8-x56a-d4s3g7ded1vv2")
          |> User.update(%{age: 44})
      """
      def update(%__MODULE__{} = item, attrs) do
        item
        |> @repo.preload(__MODULE__.__schema__(:associations))
        |> Map.put(:id, nil)
        |> Map.put(:inserted_at, nil)
        |> Map.put(:updated_at, nil)
        |> __MODULE__.changeset(attrs)
        |> @repo.insert()
      end

      @doc """
      Gets the full history of an item in the database.

          User.get("5ds4fg31-a7f1-2hd8-x56a-d4s3g7ded1vv2")
          |> User.get_history()
      """
      def get_history(%__MODULE__{} = item) do
        query =
          from(m in __MODULE__,
            where: m.entry_id == ^item.entry_id,
            select: m
          )

        @repo.all(query)
      end

      @doc """
      Gets all of the distinct instances of a schema that have not been deleted.

          User.all()
      """
      def all do
        sub =
          from(m in __MODULE__,
            distinct: m.entry_id,
            order_by: [desc: :inserted_at],
            select: m
          )

        query = from(m in subquery(sub), where: not m.deleted, select: m)

        @repo.all(query)
      end

      @doc """
      Marks an item as deleted in the database.
      Deleted items will not show up in queries.

          User.get("5ds4fg31-a7f1-2hd8-x56a-d4s3g7ded1vv2")
          |> User.delete()
      """
      def delete(item) do
        item
        |> @repo.preload(__MODULE__.__schema__(:associations))
        |> Map.put(:id, nil)
        |> Map.put(:inserted_at, nil)
        |> Map.put(:updated_at, nil)
        |> __MODULE__.changeset(%{deleted: true})
        |> @repo.insert()
      end

      @doc """
      Preloads an item's (or list of items') multiple associations.
      Also preloads any nested associations.

          # Load all of a user's friends and comments
          User.get("5ds4fg31-a7f1-2hd8-x56a-d4s3g7ded1vv2")
          |> User.preload([:friends, :comments])

          # Load all of a user's friends, and all of their friends' comments
          User.get("5ds4fg31-a7f1-2hd8-x56a-d4s3g7ded1vv2")
          |> User.preload([friends: [:comments]])
      """
      def preload(item, assocs) when is_list(assocs) do
        @repo.preload(
          item,
          Enum.map(assocs, fn a ->
            preload_map(a, __MODULE__)
          end)
        )
      end

      @doc """
      Preloads an item's (or list of items') association.

          User.get("5ds4fg31-a7f1-2hd8-x56a-d4s3g7ded1vv2")
          |> User.preload(:friends)
      """
      def preload(item, assoc) do
        @repo.preload(item, [{assoc, preload_query(assoc)}])
      end

      defp preload_map(assoc, owner) do
        case assoc do
          {k, v} ->
            assoc_module = owner.__schema__(:association, k).queryable
            {k, {preload_query(k, owner), Enum.map(v, fn a -> preload_map(a, assoc_module) end)}}

          k ->
            {k, preload_query(k, owner)}
        end
      end

      @doc false
      def preload_query(assoc, module \\ __MODULE__) do
        sub =
          from(mod in Map.get(module.__schema__(:association, assoc), :queryable),
            distinct: mod.entry_id,
            order_by: [desc: :inserted_at],
            select: mod
          )

        from(m in subquery(sub), where: not m.deleted, select: m)
      end

      defp insert_entry_id(entry) do
        case Map.fetch(entry, :entry_id) do
          {:ok, nil} -> %{entry | entry_id: Ecto.UUID.generate()}
          _ -> entry
        end
      end

      defoverridable Alog
    end
  end
end
