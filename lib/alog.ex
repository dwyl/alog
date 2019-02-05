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

  You can set the repo you want Alog to use in a config file:

      config :alog, Alog,
        repo: MyApp.Repo

  If you do not explicitly set a Repo, Alog will try to find it using your application name.
  So if your app is `MyApp` and your schema is `MyApp.User`, or `MyApp.Accounts.User`, your Repo should be `MyApp.Repo`.

  Any schema that uses Alog must include the fields `:deleted` of type `:boolean` and default false,
  and `:entry_id` of type `:string`.

        field(:deleted, :boolean, default: false)
        field(:entry_id, :string)
  """

  @callback insert(Ecto.Schema.t() | Ecto.Changeset.t()) ::
              {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  @callback get(String.t()) :: Ecto.Schema.t() | nil | no_return()
  @callback get_by(Keyword.t() | map(), Keyword.t()) :: Ecto.Schema.t() | nil | no_return()
  @callback update(Ecto.Changeset.t()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  @callback get_history(Ecto.Schema.t()) :: [Ecto.Schema.t()] | no_return()
  @callback delete(Ecto.Schema.t() | Ecto.Changeset.t()) ::
              {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
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
      import Ecto.Query
      import Ecto.Query.API, only: [field: 2]

      @repo apply(unquote(__MODULE__), :get_repo, [__MODULE__])

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
      Inserts a struct made with a schema or a changeset into the database.
      Adds an entry id to link it to future updates of the item.

      If `cast_assoc` has been used on the changeset before passing it to this function,
      any nested associations will also be given an `entry_id` before they are
      inserted into the database.

          %User{name: "username", age: "25"}
          |> User.insert()

          %User{}
          |> User.changeset(%{name: "username", age: "25"})
          |> User.insert()
      """
      def insert(struct_or_changeset) do
        case check_for_unique_index() do
          :ok ->
            struct_or_changeset
            |> insert_entry_id()
            |> apply_constraints()
            |> @repo.insert()

          {:error, msg} ->
            raise msg
        end
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

          User.get_by(username: "admin")
          User.get_by(first_name: "Charlie", age: 27)

      ## Options

          - :case_insensitive (boolean) - whether your query should be case insensitive. Defaults to `false`.

      If using the `:case_insensitive` option, you should consider adding a lowercase index to your table,
      as it will significantly increase the query speed. For example:

          `create index("users", ["(lower(first_name))"], first_name: :users_lower_first_name_index)`

      See https://hexdocs.pm/ecto_sql/Ecto.Migration.html#index/3 for more details.

      If passing options, make sure your clauses are wrapped in square brackets, or passed as a map:

          User.get([first_name: "charlie"], case_insensitive: true)
          User.get(%{first_name: "charlie"}, case_insensitive: true)
      """
      def get_by(clauses, opts \\ []) do
        sub =
          __MODULE__
          |> (fn q ->
                Enum.reduce(clauses, q, fn {key, value}, q ->
                  case Keyword.get(opts, :case_insensitive) do
                    true ->
                      q
                      |> where(
                        [m],
                        fragment("lower(?)", field(m, ^key)) == ^String.downcase(value)
                      )

                    _ ->
                      q |> where([m], field(m, ^key) == ^value)
                  end
                end)
              end).()
          |> order_by([m], desc: m.inserted_at)
          |> distinct([m], m.entry_id)
          |> select([m], m)

        query = from(m in subquery(sub), where: not m.deleted, select: m)

        query
        |> @repo.all
        |> Enum.filter(fn item -> item && __MODULE__.get(item.entry_id) == item end)
        |> List.last()
      end

      @doc """
      Updates an item in the database.
      Copies the current row, updates the relevant fields and appends
      it to the database table.
      Requires a changeset to be given.

          User.get("5ds4fg31-a7f1-2hd8-x56a-d4s3g7ded1vv2")
          |> User.changeset(%{age: 44})
          |> User.update()
      """
      def update(%Ecto.Changeset{} = changeset) do
        case check_for_unique_index() do
          :ok ->
            data =
              changeset
              |> Map.get(:data)
              |> @repo.preload(__MODULE__.__schema__(:associations))
              |> Map.put(:id, nil)
              |> Map.put(:updated_at, nil)

            changeset
            |> apply_constraints()
            |> Map.put(:data, data)
            |> @repo.insert()

          {:error, msg} ->
            raise msg
        end
      end

      def update(_) do
        raise ArgumentError, "The argument provided to update/1 must be an Ecto.Changeset"
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

          User.get("5ds4fg31-a7f1-2hd8-x56a-d4s3g7ded1vv2")
          |> User.changeset(%{})
          |> User.delete()
      """
      def delete(%Ecto.Changeset{} = changeset) do
        changeset
        |> Ecto.Changeset.put_change(:deleted, true)
        |> update()
      end

      def delete(%__MODULE__{} = entry) do
        entry
        |> Ecto.Changeset.cast(%{deleted: true}, [:deleted])
        |> update()
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

      defp apply_constraints(%Ecto.Changeset{} = changeset) do
        changeset
        |> Map.get(:constraints)
        |> Enum.reduce(changeset, fn con, acc ->
          with :unique <- con.type,
               change when not is_nil(change) <- Map.get(changeset.changes, con.field),
               existing when not is_nil(existing) <- __MODULE__.get_by([{con.field, change}]) do
            Ecto.Changeset.add_error(acc, con.field, Map.get(con, :error) |> elem(0))
          else
            _ -> acc
          end
        end)
      end

      defp apply_constraints(struct), do: struct

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

      defp insert_entry_id(%Ecto.Changeset{} = entry) do
        with {:ok, nil} <- Map.fetch(entry.data, :entry_id),
             nil <- get_change(entry, :entry_id) do
          entry
          |> put_change(:entry_id, Ecto.UUID.generate())
          |> insert_nested_entry_ids()
        else
          _ ->
            entry
        end
      end

      defp insert_entry_id(%__MODULE__{} = entry) do
        case Map.fetch(entry, :entry_id) do
          {:ok, nil} -> %{entry | entry_id: Ecto.UUID.generate()}
          _ -> entry
        end
      end

      defp insert_nested_entry_ids(changeset) do
        assocs = changeset.data.__struct__.__schema__(:associations)

        Enum.reduce(changeset.changes, changeset, fn {k, v}, acc ->
          if k in assocs do
            assoc =
              case v do
                l when is_list(l) -> Enum.map(l, &insert_entry_id/1)
                item -> insert_entry_id(item)
              end

            Ecto.Changeset.put_change(acc, k, assoc)
          else
            acc
          end
        end)
      end

      defp check_for_unique_index() do
        table = __MODULE__.__schema__(:source)
        "Elixir." <> module_name = unquote(__MODULE__) |> to_string()

        case @repo.query(
               "SELECT * FROM pg_indexes WHERE tablename = $1 and indexname NOT LIKE '%_pkey' AND indexdef LIKE 'CREATE UNIQUE INDEX%';",
               [table]
             ) do
          {:ok, %Postgrex.Result{columns: columns, rows: rows}} when rows != [] ->
            unique_index =
              rows
              |> List.first()
              |> Enum.zip(columns)
              |> Enum.find(fn {_r, c} -> c == "indexname" end)
              |> elem(0)

            {:error,
             """
               Unique index '#{unique_index}' found on table '#{table}'.
               #{module_name} is not compatible with tables that have a unique index.
               Please remove this index if you want to use #{module_name}.
             """}

          _ ->
            :ok
        end
      end

      defoverridable Alog
    end
  end

  def get_repo(module) do
    with config when not is_nil(config) <- Application.get_env(:alog, Alog),
         repo when not is_nil(repo) <- Keyword.get(config, :repo) do
    else
      _ ->
        module
        |> Module.split()
        |> List.first()
        |> Module.concat("Repo")
    end
  end
end
