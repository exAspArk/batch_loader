defmodule BatchLoader.CacheStore do
  alias BatchLoader.Cache

  @moduledoc """
  A module which operates on the cache store (map).
  """

  def fetch_cache(store, batch_loader) do
    cache_key = BatchLoader.cache_key(batch_loader)
    batch_loader_store(store)[cache_key] || Cache.new(batch_loader)
  end

  def clean(store) do
    batches =
      store
      |> batch_loader_store()
      |> Enum.map(fn {cache_key, cache} -> {cache_key, Cache.clean(cache)} end)
      |> Map.new()

    Map.put(store, BatchLoader, batches)
  end

  def replace_caches(store, caches) do
    batches =
      caches
      |> Enum.map(fn cache -> {BatchLoader.cache_key(cache), cache} end)
      |> Map.new()

    Map.put(store, BatchLoader, batches)
  end

  def upbatched_caches(store) do
    store
    |> batch_loader_store()
    |> Enum.filter(fn {_cache_key, cache} -> !Cache.batched?(cache) end)
    |> Enum.map(fn {_cache_key, cache} -> cache end)
  end

  def upsert_cache(store, cache) do
    cache_key = BatchLoader.cache_key(cache)
    batches = batch_loader_store(store) |> Map.put(cache_key, cache)
    Map.put(store, BatchLoader, batches)
  end

  def batched?(store) do
    store
    |> batch_loader_store()
    |> Enum.all?(fn {_cache_key, cache} -> Cache.batched?(cache) end)
  end

  defp batch_loader_store(store) do
    store[BatchLoader] || %{}
  end
end
