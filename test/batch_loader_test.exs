defmodule BatchLoaderTest do
  use ExUnit.Case

  describe "cache_key/1" do
    test "generates a cache key based on the batch function" do
      batch_loader = %BatchLoader{item: 1, batch: fn -> nil end}

      result = BatchLoader.cache_key(batch_loader)

      assert result ==
               "Elixir.BatchLoaderTest--test cache_key/1 generates a cache key based on the batch function/1-fun-0--[]"
    end
  end
end
