defmodule AlogTest do
  use Alog.TestApp.DataCase
  doctest Alog

  describe "required fields" do
    test "schema without delete field raises error" do
      assert_raise RuntimeError, fn ->
        defmodule NoDeleteSchema do
          use Ecto.Schema
          use Alog

          schema "bad_schema" do
            field(:entry_id, :string)
            timestamps()
          end
        end
      end
    end

    test "schema without entry_id field raises error" do
      assert_raise RuntimeError, fn ->
        defmodule NoEntrySchema do
          use Ecto.Schema
          use Alog

          schema "bad_schema" do
            field(:deleted, :boolean, default: false)
            timestamps()
          end
        end
      end
    end

    test "schema with deleted field of wrong type raises error" do
      assert_raise RuntimeError, fn ->
        defmodule BadDeletedSchema do
          use Ecto.Schema
          use Alog

          schema "bad_schema" do
            field(:entry_id, :string)
            field(:deleted, :string)
            timestamps()
          end
        end
      end
    end

    test "both required fields do not raise error" do
      assert (fn ->
                defmodule GoodSchema do
                  use Ecto.Schema
                  use Alog

                  schema "bad_schema" do
                    field(:entry_id, :string)
                    field(:deleted, :boolean, default: false)
                    timestamps()
                  end
                end
              end).()
    end
  end

  describe "Not compatible with unique index" do
    test "Throws error if unique index exists" do
      assert_raise RuntimeError, fn ->
        %Alog.TestApp.Unique{}
        |> Alog.TestApp.Unique.changeset(%{name: "unique item"})
        |> Alog.TestApp.Unique.insert()
      end
    end
  end
end
