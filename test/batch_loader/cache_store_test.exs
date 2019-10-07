defmodule BatchLoader.CacheStoreTest do
  use ExUnit.Case

  alias BatchLoader.Cache
  alias BatchLoader.CacheStore

  describe "fetch_cache/2" do
    test "fetches the existing cache value from the store based on the BatchLoader struct" do
      batch_loader = %BatchLoader{item: 1, batch: fn -> nil end}
      cache = Cache.new(batch_loader)
      store = %{BatchLoader => %{BatchLoader.cache_key(batch_loader) => cache}}

      result = CacheStore.fetch_cache(store, batch_loader)

      assert result == cache
    end

    test "returns a new cache if it doesn't exist in the store" do
      batch_loader = %BatchLoader{item: 1, batch: fn -> nil end}
      store = %{}

      result = CacheStore.fetch_cache(store, batch_loader)

      assert result == Cache.new(batch_loader)
    end
  end

  describe "clean/1" do
    test "removes items for batching from the store" do
      batch_loader1 = %BatchLoader{item: 1, batch: fn -> nil end}
      cache_key1 = BatchLoader.cache_key(batch_loader1)
      batch_loader2 = %BatchLoader{item: 2, batch: fn -> nil end}
      cache_key2 = BatchLoader.cache_key(batch_loader2)

      store = %{
        BatchLoader => %{
          cache_key1 => %Cache{items: [1], batch: batch_loader1.batch},
          cache_key2 => %Cache{items: [2], batch: batch_loader2.batch}
        }
      }

      result = CacheStore.clean(store)

      assert result[BatchLoader][cache_key1].items == []
      assert result[BatchLoader][cache_key2].items == []
    end
  end

  describe "replace_caches/2" do
    test "replaces caches in the store" do
      cache1 = %Cache{batch: fn -> nil end}
      cache_key1 = BatchLoader.cache_key(cache1)
      cache2 = %Cache{batch: fn -> nil end}
      cache_key2 = BatchLoader.cache_key(cache2)

      result = CacheStore.replace_caches(%{}, [cache1, cache2])

      assert result[BatchLoader] == %{cache_key1 => cache1, cache_key2 => cache2}
    end
  end

  describe "upsert_cache/2" do
    test "adds a new cache to the store" do
      cache = %Cache{items: [1], batch: fn -> nil end}
      cache_key = BatchLoader.cache_key(cache)

      result = CacheStore.upsert_cache(%{}, cache)

      assert result[BatchLoader] == %{cache_key => cache}
    end

    test "updates an exisitng cache in the store" do
      prev_cache = %Cache{items: [1], batch: fn -> nil end}
      cache = %Cache{items: [2], batch: fn -> nil end}
      cache_key = BatchLoader.cache_key(cache)
      store = %{BatchLoader => %{cache_key => prev_cache}}

      result = CacheStore.upsert_cache(store, cache)

      assert result[BatchLoader] == %{cache_key => cache}
    end
  end

  describe "batched?/1" do
    test "returns true if all caches were batched" do
      cache = %Cache{items: [], batch: fn -> nil end}
      cache_key = BatchLoader.cache_key(cache)
      store = %{BatchLoader => %{cache_key => cache}}

      assert CacheStore.batched?(store)
    end
  end
end
