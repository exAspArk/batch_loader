defmodule BatchLoader.Absinthe.MiddlewareTest do
  use ExUnit.Case

  alias BatchLoader.Cache
  alias BatchLoader.CacheStore
  alias BatchLoader.Absinthe.Middleware

  defmodule DummyResolution do
    def put_result(res, result) do
      Map.put(res, :result, result)
    end
  end

  describe "call/2" do
    test "adds info for batching to cache and reschedules the execution with the 'suspended' state" do
      batch = fn -> nil end
      batch_loader = %BatchLoader{item: 1, batch: batch}
      res = %{state: :unresolved, middleware: [], acc: %{}}

      result = Middleware.call(res, batch_loader)

      assert result.state == :suspended
      assert result.middleware == [{BatchLoader.Absinthe.Middleware, batch_loader}]
      cache = %Cache{items: [1], value_by_item: %{}, batch: batch}
      assert CacheStore.fetch_cache(result.acc, batch_loader) == cache
    end

    test "reads the batched value from the cache" do
      batch = fn -> nil end
      batch_loader = %BatchLoader{item: 1, batch: batch}
      cache = %Cache{value_by_item: %{1 => 2}, batch: batch}
      res = %{state: :suspended, acc: CacheStore.upsert_cache(%{}, cache)}

      result = Middleware.call(res, batch_loader, DummyResolution)

      assert result.result == 2
    end
  end
end
