defmodule BatchLoader.Absinthe.PluginTest do
  use ExUnit.Case

  alias BatchLoader.Cache
  alias BatchLoader.CacheStore
  alias BatchLoader.Absinthe.Plugin

  describe "pipeline/2" do
    test "appends an extra step to the pipeline if not batched yet" do
      cache = %Cache{items: [1, 2], batch: fn -> nil end}
      res = %{acc: CacheStore.upsert_cache(%{}, cache)}

      result = Plugin.pipeline([:step2], res)

      assert result == [Absinthe.Phase.Document.Execution.Resolution, :step2]
    end
  end

  describe "after_resolution/1" do
    test "runs the batch function and stores the results in the cache" do
      batch = fn ids -> Enum.map(ids, &{&1, &1 + 1}) end
      batch_loader = %BatchLoader{item: 1, batch: batch}
      cache = %Cache{items: [1], batch: batch}
      res = %{acc: CacheStore.upsert_cache(%{}, cache)}

      result = Plugin.after_resolution(res)

      assert result.acc
             |> CacheStore.fetch_cache(batch_loader)
             |> Cache.value(batch_loader) == 2
    end
  end

  describe "before_resolution/1" do
    test "cleans the batched caches" do
      batch = fn ids -> Enum.map(ids, &{&1, &1 + 1}) end
      cache = %Cache{items: [1], batch: batch}
      res = %{acc: CacheStore.upsert_cache(%{}, cache)}

      result = Plugin.before_resolution(res)

      assert result.acc
             |> CacheStore.fetch_cache(cache)
             |> Map.get(:items) == []
    end
  end
end
