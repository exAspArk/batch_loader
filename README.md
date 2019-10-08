# BatchLoader

This package provides a generic lazy batching mechanism to avoid N+1 DB queries, HTTP queries, etc.

## Contents

* [Highlights](#highlights)
* [Usage](#usage)
  * [With Absinthe (GraphQL)](#with-absinthe-graphql)
  * [With Ecto (DB)](#with-ecto-db)
  * [Customization](#customization)
* [Installation](#installation)
* [Testing](#testing)

## Highlights

* Generic utility to avoid N+1 DB queries, HTTP requests, etc.
* Adapted Elixir implementation of battle-tested tools like [Haskell Haxl](https://github.com/facebook/Haxl), [JS DataLoader](https://github.com/graphql/dataloader), [Ruby BatchLoader](https://github.com/exaspark/batch-loader), etc.
* Allows inlining the code without forcing to define extra named functions (unlike [Absinthe Batch](https://hexdocs.pm/absinthe/Absinthe.Middleware.Batch.html)).
* Allows using batching with any data sources, not just `Ecto` (unlike [Absinthe DataLoader](https://hexdocs.pm/dataloader/Dataloader.html)).

## Usage

Let's imagine we have a `Post` GraphQL type:

```elixir
defmodule MyApp.PostType do
  use Absinthe.Schema.Notation
  alias MyApp.Repo

  object :post_type do
    field :title, :string

    field :user, :user_type do
      resolve(fn post, _, _ ->
        user = post |> Ecto.assoc(:user) |> Repo.one() # N+1 DB requests
        {:ok, user}
      end)
    end
  end
end
```

This produces N+1 DB requests if we send this GraphQL request:

```gql
query {
  posts {
    title
    user { # N+1 request per each post
      name
    }
  }
}
```

### With Absinthe (GraphQL)

We can get rid of the N+1 requests by loading all `Users` for all `Posts` at once in.
All we have to do is to use `BatchLoader.Absinthe` in the `resolve` function:

```elixir
field :user, :user_type do
  resolve(fn post, _, _ ->
    BatchLoader.Absinthe.for(post.user_id, &resolved_users_by_user_ids/1)
  end)
end

def resolved_users_by_user_ids(user_ids) do
  Repo.all(from u in User, where: u.id in ^user_ids) # load all users at once (DB, HTTP, etc.)
  |> Enum.map(fn user -> {user.id, {:ok, user}} end) # return "{user.id, result}" tuples (where user.id == post.user_id)
end
```

Alternatively, you can simply inline the batch function:

```elixir
field :user, :user_type do
  resolve(fn post, _, _ ->
    BatchLoader.Absinthe.for(post.user_id, fn user_ids ->
      Repo.all(from u in User, where: u.id in ^user_ids)
      |> Enum.map(fn user -> {user.id, {:ok, user}} end)
    end)
  end)
end
```

Finally, add `BatchLoader.Absinthe.Plugin` plugin to the Absinthe schema.
This will allow to lazily collect information about all users which need to be loaded and then load them all at once:

```elixir
defmodule MyApp.Schema do
  use Absinthe.Schema
  import_types MyApp.PostType

  def plugins do
    [BatchLoader.Absinthe.Plugin] ++ Absinthe.Plugin.defaults()
  end
end
```

### With Ecto (DB)

Set the default `repo` in your config file:

```elixir
# config/config.exs
config :batch_loader, :default_repo, MyApp.Repo
```

Now you can resolve Ecto associations with:

```elixir
field :user, :user_type, resolve: BatchLoader.Absinthe.resolve_assoc(:user)
```

To preload Ecto associations:

```elixir
field :title, :string do
  resolve(fn post, _, _ ->
    BatchLoader.Absinthe.preload_assoc(post, :user, fn post_with_user ->
      {:ok, "#{post_with_user.title} - #{post_with_user.user.name}"}
    end)
  end)
end
```

### Customization

* To specify default resolve Absinthe values:

```elixir
BatchLoader.Absinthe.for(post.user_id, &resolved_users_by_user_ids/1, default_value: {:error, "NOT FOUND"})
```

* To use custom callback function:

```elixir
BatchLoader.Absinthe.for(post.user_id, &users_by_user_ids/1, callback: fn user ->
  {:ok, user.name}
end)
```

* To use custom Ecto repos:

```elixir
BatchLoader.Absinthe.resolve_assoc(:user, repo: AnotherRepo)
BatchLoader.Absinthe.preload_assoc(post, :user, fn post_with_user -> _ end, repo: AnotherRepo)
```

* To pass custom options to `Ecto.Repo.preload`:

```elixir
BatchLoader.Absinthe.resolve_assoc(:user, preload_opts: [prefix: nil])
BatchLoader.Absinthe.preload_assoc(post, :user, fn post_with_user -> _ end, preload_opts: [prefix: nil])
```

## Installation

Add `batch_loader` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:batch_loader, "~> 0.1.0-beta.1"}
  ]
end
```

## Testing

```ex
make install
make test
```
