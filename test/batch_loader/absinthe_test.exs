defmodule BatchLoader.AbsintheTest do
  use ExUnit.Case

  describe "for/2" do
    test "creates a BatchLoader and returns the BatchLoader.Absinthe.Middleware" do
      batch = fn _ -> nil end
      batch_loader = %BatchLoader{item: 1, batch: batch, opts: [default_value: {:ok, nil}]}

      result = BatchLoader.Absinthe.for(1, batch)

      assert result == {:middleware, BatchLoader.Absinthe.Middleware, batch_loader}
    end
  end
end
