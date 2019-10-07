defmodule BatchLoader do
  @moduledoc """
  A struct which is being used for batching.
  """

  @enforce_keys [:item, :batch]
  defstruct [:item, :batch, opts: []]

  def cache_key(batch_loader) do
    function_info = Function.info(batch_loader.batch)
    "#{function_info[:module]}-#{function_info[:name]}"
  end
end
