defmodule BatchLoader.AbsintheTest do
  use ExUnit.Case

  defmodule DummyRepo do
    @preloaded_assoc %{object: :bar}

    def preload([object], assoc, _opts \\ []) do
      [%{object | assoc => @preloaded_assoc}]
    end
  end

  describe "for/2" do
    test "creates a BatchLoader and returns the BatchLoader.Absinthe.Middleware" do
      batch = fn _ -> nil end
      batch_loader = %BatchLoader{item: 1, batch: batch, opts: [default_value: {:ok, nil}]}

      result = BatchLoader.Absinthe.for(1, batch)

      assert result == {:middleware, BatchLoader.Absinthe.Middleware, batch_loader}
    end

    test "creates a BatchLoader with a callback" do
      batch = fn -> nil end
      callback = fn -> nil end

      batch_loader = %BatchLoader{
        item: 1,
        batch: batch,
        opts: [default_value: {:ok, nil}, callback: callback]
      }

      result = BatchLoader.Absinthe.for(1, batch, callback: callback)

      assert result == {:middleware, BatchLoader.Absinthe.Middleware, batch_loader}
    end
  end

  describe "resolve_assoc/2" do
    test "returns a resolve function which returns a middleware with BatchLoader" do
      object = %{object: :foo, assoc: nil}
      preloaded_assoc = %{object: :bar}

      resolve = BatchLoader.Absinthe.resolve_assoc(:assoc, repo: DummyRepo)

      middleware = resolve.(object, nil, nil)
      {:middleware, BatchLoader.Absinthe.Middleware, batch_loader} = middleware
      assert batch_loader.item == object
      assert batch_loader.opts == [default_value: {:ok, nil}, preload_opts: [], repo: DummyRepo]
      assert batch_loader.batch
      assert batch_loader.batch.([object]) == [{object, {:ok, preloaded_assoc}}]
    end

    test "returns a resolve function with a middleware with a batch function which preload assocs" do
      object1 = %{__struct__: :foo1, object: :foo1, assoc: nil}
      object2 = %{__struct__: :foo2, object: :foo2, assoc: nil}
      preloaded_assoc = %{object: :bar}

      resolve = BatchLoader.Absinthe.resolve_assoc(:assoc, repo: DummyRepo)

      middleware = resolve.(object1, nil, nil)
      {:middleware, BatchLoader.Absinthe.Middleware, batch_loader} = middleware

      assert batch_loader.batch.([object1, object2]) == [
               {object1, {:ok, preloaded_assoc}},
               {object2, {:ok, preloaded_assoc}}
             ]
    end
  end

  describe "preloaded_assoc/2" do
    test "returns a middleware with BatchLoader" do
      object = %{object: :foo, assoc: nil}
      preloaded_object = %{object: :foo, assoc: %{object: :bar}}
      callback = fn preloaded_obj -> preloaded_obj end

      result = BatchLoader.Absinthe.preload_assoc(object, :assoc, callback, repo: DummyRepo)

      {:middleware, BatchLoader.Absinthe.Middleware, batch_loader} = result
      assert batch_loader.item == object
      assert batch_loader.batch
      assert batch_loader.batch.([object]) == [{object, preloaded_object}]

      assert batch_loader.opts == [
               default_value: {:ok, nil},
               preload_opts: [],
               repo: DummyRepo,
               callback: callback
             ]
    end
  end
end
