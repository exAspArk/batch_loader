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

    batch = fn objects ->
      preloaded_objects = preload(objects, assoc, opts)

      objects
      |> Enum.with_index()
      |> Enum.map(fn {obj, index} ->
        preloaded_obj = Enum.at(preloaded_objects, index)
        {obj, {:ok, Map.get(preloaded_obj, assoc)}}
      end)
    end

    fn object, _args, _resolution ->
      batch_loader = %BatchLoader{item: object, batch: batch, opts: opts}
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

    batch = fn objects ->
      preloaded_objects = preload(objects, assoc, opts)

      objects
      |> Enum.with_index()
      |> Enum.map(fn {obj, index} ->
        preloaded_obj = Enum.at(preloaded_objects, index)
        {obj, preloaded_obj}
      end)
    end

    batch_loader = %BatchLoader{item: item, batch: batch, opts: opts}
    {:middleware, BatchLoader.Absinthe.Middleware, batch_loader}
  end

  defp preload(objects, assoc, opts) do
    repo = opts[:repo] || default_repo()

    objects
    |> Enum.group_by(&Map.get(&1, :__struct__))
    |> Map.values()
    |> Enum.flat_map(fn homogeneous_items ->
      repo.preload(homogeneous_items, assoc, opts[:preload_opts])
    end)
  end

  defp default_repo, do: Application.get_env(:batch_loader, :default_repo)
end
