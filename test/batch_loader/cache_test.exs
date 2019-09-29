defmodule BatchLoader.CacheTest do
  use ExUnit.Case

  alias BatchLoader.Cache

  describe "new/1" do
    test "generates a cache struct based on the BatchLoader" do
      batch = fn -> nil end
      batch_loader = %BatchLoader{batch: batch}

      cache = Cache.new(batch_loader)

      assert cache.items == []
      assert cache.value_by_item == %{}
      assert cache.batch == batch
    end
  end

  describe "batched?/1" do
    test "returns true if there are no items for batching" do
      cache = %Cache{items: []}

      assert Cache.batched?(cache)
    end

    test "returns false if there are items for batching" do
      cache = %Cache{items: [1]}

      assert !Cache.batched?(cache)
    end
  end

  describe "add_item/2" do
    test "adds an item from a BatchLoader struct" do
      cache = %Cache{items: [1]}
      batch_loader = %BatchLoader{item: 2}

      result = Cache.add_item(cache, batch_loader)

      assert result.items == [2, 1]
    end
  end

  describe "batch/1" do
    test "calls a batch function and stores value_by_item" do
      cache = %Cache{
        items: [1],
        batch: fn items -> Enum.map(items, &{&1, &1 + 1}) end
      }

      result = Cache.batch(cache)

      assert result.value_by_item == %{1 => 2}
    end
  end

  describe "clean/1" do
    test "returns a new cache with empty items" do
      cache = %Cache{items: [1]}

      result = Cache.clean(cache)

      assert result.items == []
    end
  end

  describe "value/2" do
    test "reads a batched value based on the BatchLoader struct" do
      batch_loader = %BatchLoader{item: 1}
      cache = %Cache{value_by_item: %{1 => 2}}

      result = Cache.value(cache, batch_loader)

      assert result == 2
    end

    test "fallbacks to BatchLoader's default_value if batched value couldn't be found" do
      batch_loader = %BatchLoader{item: 1, opts: [default_value: 2]}
      cache = %Cache{value_by_item: %{}}

      result = Cache.value(cache, batch_loader)

      assert result == 2
    end
  end
end
