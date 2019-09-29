defmodule BatchLoader.Absinthe do
  @moduledoc """
  A module which integrates BatchLoader with Absinthe.
  """

  @default_value {:ok, nil}

  @doc """
  Creates a BatchLoader struct and calls the BatchLoader.Absinthe.Middleware.

  ## Example
      iex> BatchLoader.Absinthe.for(post.user_id, batch_function)
  """
  def for(item, batch, opts \\ [default_value: @default_value]) do
    batch_loader = %BatchLoader{item: item, batch: batch, opts: opts}
    {:middleware, BatchLoader.Absinthe.Middleware, batch_loader}
  end
end
