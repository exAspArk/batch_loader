defmodule BatchLoader.Absinthe.Middleware do
  @behaviour Absinthe.Middleware

  @moduledoc """
  Absinthe Middleware which delays the resolution and then gets the result from CacheStore.
  """

  alias BatchLoader.Cache
  alias BatchLoader.CacheStore

  def call(%{state: :unresolved} = res, batch_loader) do
    new_cache =
      res.acc
      |> CacheStore.fetch_cache(batch_loader)
      |> Cache.add_item(batch_loader)

    new_acc =
      res.acc
      |> CacheStore.upsert_cache(new_cache)

    new_middleware = [{__MODULE__, batch_loader} | res.middleware]
    %{res | state: :suspended, acc: new_acc, middleware: new_middleware}
  end

  def call(%{state: :suspended} = res, batch_loader, resolution \\ Absinthe.Resolution) do
    result =
      res.acc
      |> CacheStore.fetch_cache(batch_loader)
      |> Cache.value(batch_loader)

    res |> resolution.put_result(result)
  end
end
