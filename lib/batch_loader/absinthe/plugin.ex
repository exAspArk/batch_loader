defmodule BatchLoader.Absinthe.Plugin do
  @behaviour Absinthe.Plugin

  @moduledoc """
  Absinthe Plugin which re-runs the delayed resolution, executes batching and cleans the CacheStore.
  """

  alias BatchLoader.Cache
  alias BatchLoader.CacheStore

  def before_resolution(res) do
    new_acc = CacheStore.clean(res.acc)
    %{res | acc: new_acc}
  end

  def after_resolution(res) do
    batched_caches =
      res.acc
      |> CacheStore.upbatched_caches()
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
