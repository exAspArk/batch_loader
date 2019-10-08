defmodule BatchLoader do
  @moduledoc """
  A struct which is being used for batching.
  """

  @enforce_keys [:item, :batch]
  defstruct [:item, :batch, opts: [default_value: nil, callback: nil]]

  def cache_key(batch_loader) do
    info = Function.info(batch_loader.batch)
    "#{info[:module]}-#{info[:name]}-#{inspect(info[:env])}"
  end
end
