defmodule Alog do
  @moduledoc """
  Behaviour that defines functions for accessing and inserting data in an
  Append-Only database
  """

  @callback insert(struct) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  @callback get(integer) :: Ecto.Schema.t() | nil | no_return()
  @callback get_by(Keyword.t() | map) :: Ecto.Schema.t() | nil | no_return()
  @callback update(Ecto.Schema.t(), struct) ::
              {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  @callback get_history(Ecto.Schema.t()) :: [Ecto.Schema.t()] | no_return()

  defmacro __using__(_opts) do
    quote location: :keep do
      @behaviour Alog
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_env) do
    quote generated: true do
      import Ecto.Query, only: [from: 2, subquery: 1]

      @repo __MODULE__ |> Module.split() |> List.first() |> Module.concat("Repo")

      def insert(attrs) do
        %__MODULE__{}
        |> __MODULE__.changeset(attrs)
        |> @repo.insert()
      end

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

      def get_by(clauses) do
        @repo.get_by(__MODULE__, clauses)
      end

      def update(%__MODULE__{} = item, attrs) do
        item
        |> @repo.preload(__MODULE__.__schema__(:associations))
        |> Map.put(:id, nil)
        |> Map.put(:inserted_at, nil)
        |> Map.put(:updated_at, nil)
        |> __MODULE__.changeset(attrs)
        |> @repo.insert()
      end

      def get_history(%__MODULE__{} = item) do
        query =
          from(m in __MODULE__,
            where: m.entry_id == ^item.entry_id,
            select: m
          )

        @repo.all(query)
      end

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

      def insert_entry_id(entry) do
        case Map.fetch(entry, :entry_id) do
          {:ok, nil} -> %{entry | entry_id: Ecto.UUID.generate()}
          _ -> entry
        end
      end

      def delete(item) do
        item
        |> @repo.preload(__MODULE__.__schema__(:associations))
        |> Map.put(:id, nil)
        |> Map.put(:inserted_at, nil)
        |> Map.put(:updated_at, nil)
        |> __MODULE__.changeset(%{deleted: true})
        |> @repo.insert()
      end

      defoverridable Alog
    end
  end
end
