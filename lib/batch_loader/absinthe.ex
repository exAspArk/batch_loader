defmodule BatchLoader.Absinthe do
  @moduledoc """
  A module which integrates BatchLoader with Absinthe.
  """

  @default_value {:ok, nil}
  @default_opts_for [default_value: @default_value]
  @default_opts_resolve_assoc [default_value: @default_value, repo: nil, preload_opts: []]

  @doc """
  Creates a BatchLoader struct and calls the BatchLoader.Absinthe.Middleware, which will batch all collected items.

  ## Example

      field :user, :user_type do
        resolve(fn post, _, _ ->
          BatchLoader.Absinthe.for(post.user_id, fn user_ids ->
            Repo.all(from u in User, where: u.id in ^user_ids)
            |> Enum.map(fn user -> {user.id, {:ok, user}} end)
          end)
        end)
      end
  """
  def for(item, batch, options \\ @default_opts_for) do
    opts = Keyword.merge(@default_opts_for, options)
    batch_loader = %BatchLoader{item: item, batch: batch, opts: opts}
    {:middleware, BatchLoader.Absinthe.Middleware, batch_loader}
  end

  @doc """
  Creates a resolve function, which creates a BatchLoader struct and calls the BatchLoader.Absinthe.Middleware, which return an Ecto association.

  ## Example

      field :user, :user_type, resolve: BatchLoader.Absinthe.resolve_assoc(:user)
  """
  def resolve_assoc(assoc, options \\ @default_opts_resolve_assoc) do
    opts = Keyword.merge(@default_opts_resolve_assoc, options)

    batch = fn items ->
      preloaded_item_by_item = preloaded_item_by_item(items, assoc, opts)

      items
      |> Enum.map(fn item ->
        preloaded_item = preloaded_item_by_item[item]
        {item, {:ok, Map.get(preloaded_item, assoc)}}
      end)
    end

    fn item, _args, _resolution ->
      batch_loader = %BatchLoader{item: item, batch: batch, opts: opts}
      {:middleware, BatchLoader.Absinthe.Middleware, batch_loader}
    end
  end

  @doc """
  Creates a BatchLoader struct and calls the BatchLoader.Absinthe.Middleware, which will preload an Ecto association.

  ## Example

      field :title, :string do
        resolve(fn post, _, _ ->
          BatchLoader.Absinthe.preload_assoc(post, :user, fn post_with_user ->
            {:ok, "\#{post_with_user.title} - \#{post_with_user.user.name}"}
          end)
        end)
      end
  """
  def preload_assoc(item, assoc, callback, options \\ @default_opts_resolve_assoc) do
    opts =
      @default_opts_resolve_assoc
      |> Keyword.merge(options)
      |> Keyword.merge(callback: callback)

    batch = fn items ->
      preloaded_item_by_item = preloaded_item_by_item(items, assoc, opts)

      items
      |> Enum.map(fn item ->
        preloaded_item = preloaded_item_by_item[item]
        {item, preloaded_item}
      end)
    end

    batch_loader = %BatchLoader{item: item, batch: batch, opts: opts}
    {:middleware, BatchLoader.Absinthe.Middleware, batch_loader}
  end

  @doc """
  Creates a BatchLoader struct and calls the BatchLoader.Absinthe.Middleware, which will load an Ecto association.

  ## Example

      field :author, :string do
        resolve(fn post, _, _ ->
          BatchLoader.Absinthe.load_assoc(post, :user, fn user ->
            {:ok, user.name}
          end)
        end)
      end
  """
  def load_assoc(item, assoc, callback, options \\ @default_opts_resolve_assoc) do
    opts =
      @default_opts_resolve_assoc
      |> Keyword.merge(options)
      |> Keyword.merge(callback: callback)

    batch = fn items ->
      preloaded_item_by_item = preloaded_item_by_item(items, assoc, opts)

      items
      |> Enum.map(fn item ->
        preloaded_item = preloaded_item_by_item[item]
        {item, Map.get(preloaded_item, assoc)}
      end)
    end

    batch_loader = %BatchLoader{item: item, batch: batch, opts: opts}
    {:middleware, BatchLoader.Absinthe.Middleware, batch_loader}
  end

  defp preloaded_item_by_item(items, assoc, opts) do
    repo = opts[:repo] || default_repo()

    items
    |> Enum.group_by(&Map.get(&1, :__struct__))
    |> Map.values()
    |> Enum.flat_map(fn homogeneous_items ->
      preloaded_items = repo.preload(homogeneous_items, assoc, opts[:preload_opts])

      homogeneous_items
      |> Enum.with_index()
      |> Enum.map(fn {item, index} ->
        preloaded_item = Enum.at(preloaded_items, index)
        {item, preloaded_item}
      end)
    end)
    |> Map.new()
  end

  defp default_repo, do: Application.get_env(:batch_loader, :default_repo)
end
