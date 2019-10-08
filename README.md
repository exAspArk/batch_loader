# BatchLoader

This package provides a generic lazy batching mechanism to avoid N+1 DB queries, HTTP queries, etc.

## Contents

* [Highlights](#highlights)
* [Usage](#usage)
  * [Ecto Resolve Association](#ecto-resolve-association)
  * [Ecto Preload Association](#ecto-preload-association)
  * [DIY Batching](#diy-batching)
  * [Customization](#customization)
* [Installation](#installation)
* [Testing](#testing)

## Highlights

* Generic utility to avoid N+1 DB queries, HTTP requests, etc.
* Adapted Elixir implementation of battle-tested tools like [Haskell Haxl](https://github.com/facebook/Haxl), [JS DataLoader](https://github.com/graphql/dataloader), [Ruby BatchLoader](https://github.com/exaspark/batch-loader), etc.
* Allows inlining the code without forcing to define extra named functions (unlike [Absinthe Batch](https://hexdocs.pm/absinthe/Absinthe.Middleware.Batch.html)).
* Allows using batching with any data sources, not just `Ecto` (unlike [Absinthe DataLoader](https://hexdocs.pm/dataloader/Dataloader.html)).

## Usage

Let's imagine that we have a `Post` GraphQL type defined with [Absinthe](https://github.com/absinthe-graphql/absinthe):

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

This will produce N+1 DB requests if we send this GraphQL request:

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

### Ecto Resolve Association

We can get rid of the N+1 DB requests by loading all `Users` for all `Posts` at once in.
All we have to do is to use `resolve_assoc` function by passing the Ecto associations name:

```elixir
import BatchLoader.Absinthe, only: [resolve_assoc: 1]

field :user, :user_type, resolve: resolve_assoc(:user)
```

Set the default `repo` in your `config.exs` file:

```elixir
config :batch_loader, :default_repo, MyApp.Repo
```

And finally, add `BatchLoader.Absinthe.Plugin` plugin to the GraphQL schema.
This will allow to lazily collect information about all users which need to be loaded and then batch them all together:

```elixir
defmodule MyApp.Schema do
  use Absinthe.Schema
  import_types MyApp.PostType

  def plugins do
    [BatchLoader.Absinthe.Plugin] ++ Absinthe.Plugin.defaults()
  end
end
```

### Ecto Preload Association

You can use `preload_assoc` to preload Ecto associations in the existing schema:

```elixir
import BatchLoader.Absinthe, only: [preload_assoc: 3]

field :title, :string do
  resolve(fn post, _, _ ->
    preload_assoc(post, :user, fn post_with_user ->
      {:ok, "#{post_with_user.title} - #{post_with_user.user.name}"}
    end)
  end)
end
```

### DIY Batching

You can also use `BatchLoader` to batch in the `resolve` function manually, for example, to fix N+1 HTTP requests:

```elixir
field :user, :user_type do
  resolve(fn post, _, _ ->
    BatchLoader.Absinthe.for(post.user_id, &resolved_users_by_user_ids/1)
  end)
end

def resolved_users_by_user_ids(user_ids) do
  MyApp.HttpClient.users(user_ids)                   # load all users at once
  |> Enum.map(fn user -> {user.id, {:ok, user}} end) # return "{user.id, result}" tuples
end
```

Alternatively, you can simply inline the batch function:

```elixir
field :user, :user_type do
  resolve(fn post, _, _ ->
    BatchLoader.Absinthe.for(post.user_id, fn user_ids ->
      MyApp.HttpClient.users(user_ids)
      |> Enum.map(fn user -> {user.id, {:ok, user}} end)
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
BatchLoader.Absinthe.preload_assoc(post, :user, &callback/1, repo: AnotherRepo)
```

* To pass custom options to `Ecto.Repo.preload`:

```elixir
BatchLoader.Absinthe.resolve_assoc(:user, preload_opts: [prefix: nil])
BatchLoader.Absinthe.preload_assoc(post, :user, &callback/1, preload_opts: [prefix: nil])
```

## Installation

Add `batch_loader` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:batch_loader, "~> 0.1.0-beta.3"}
  ]
end
```

## Testing

```ex
make install
make test
```
