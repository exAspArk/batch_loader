# BatchLoader

This package provides a generic lazy batching mechanism to avoid N+1 DB queries, HTTP queries, etc.

Here are similar implementations in other programming languages:

* [BatchLoader](https://github.com/exaspark/batch-loader) written in Ruby (1.4M downloads).

## Contents

* [Usage](#usage)
  * [With Absinthe (GraphQL)](#with-absinthe-graphql)
* [Installation](#installation)
* [Testing](#testing)

## Usage

### With Absinthe (GraphQL)

Use `BatchLoader` in your resolve function:

```ex
defmodule MyApp.PostType do
  use Absinthe.Schema.Notation

  object :post_type do
    field :name, :string

    field :user, :user_type do
      resolve(fn post, _, _ ->
        BatchLoader.Absinthe.for(post.user_id, fn user_ids ->
          Repo.all(from u in User, where: u.id in ^user_ids)
          |> Enum.map(fn user -> {user.id, {:ok, user}} end)
        end)
      end)
    end
  end
end
```

Add `BatchLoader` plugin to your Absinthe schema:

```ex
defmodule MyApp.Schema do
  use Absinthe.Schema
  import_types MyApp.PostType

  # ...

  def plugins do
    [BatchLoader.Absinthe.Plugin] ++ Absinthe.Plugin.defaults()
  end
end
```

## Installation

Add `batch_loader` to your list of dependencies in `mix.exs`:

```ex
def deps do
  [
    {:batch_loader, "~> 0.1.0"}
  ]
end
```

## Testing

```ex
make install
make test
```
