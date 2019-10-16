defmodule BatchLoader.Absinthe.Plugin do
  @moduledoc """
  Absinthe Plugin which re-runs the delayed resolution and executes batching.
  """

  @behaviour Absinthe.Plugin

  alias BatchLoader.Cache
  alias BatchLoader.CacheStore

  def before_resolution(res) do
    new_acc = CacheStore.clean(res.acc)
    %{res | acc: new_acc}
  end

  def after_resolution(res) do
    batched_caches =
      res.acc
      |> CacheStore.unbatched_caches()
      |> Enum.map(fn cache -> Cache.batch(cache) end)

    new_acc = CacheStore.replace_caches(res.acc, batched_caches)
    %{res | acc: new_acc}
  end

  def pipeline(pipeline, res) do
    if CacheStore.batched?(res.acc) do
      pipeline
    else
      [Absinthe.Phase.Document.Execution.Resolution | pipeline]
    end
  end
end
