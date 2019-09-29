defmodule BatchLoader do
  defstruct [:item, :batch, :opts]

  @moduledoc """
  A struct which is being used for batching.
  """

  def cache_key(batch_loader) do
    function_info = Function.info(batch_loader.batch)
    "#{function_info[:module]}-#{function_info[:name]}"
  end
end
