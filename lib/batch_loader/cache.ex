defmodule BatchLoader.Cache do
  defstruct [:batch, :items, :value_by_item]

  @moduledoc """
  A struct which is used like cache per batch function.
  """

  def new(batch_loader) do
    %__MODULE__{items: [], value_by_item: %{}, batch: batch_loader.batch}
  end

  def batched?(cache) do
    !Enum.any?(cache.items)
  end

  def add_item(cache, batch_loader) do
    %{cache | items: [batch_loader.item] ++ cache.items}
  end

  def batch(cache) do
    value_by_item = cache.batch.(cache.items) |> Map.new()
    %{cache | value_by_item: value_by_item}
  end

  def clean(cache) do
    %{cache | items: []}
  end

  def value(cache, batch_loader) do
    cache.value_by_item[batch_loader.item] || batch_loader.opts[:default_value]
  end
end
