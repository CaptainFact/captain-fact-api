defmodule DB.RuntimeConfiguration do
  use Weave

  # ----- Configuration handlers -----

  weave "db_hostname", handler: fn v -> put_in_repo([:hostname], v) end
  weave "db_username", handler: fn v -> put_in_repo([:username], v) end
  weave "db_password", handler: fn v -> put_in_repo([:password], v) end
  weave "db_name", handler: fn v -> put_in_repo([:database], v) end
  weave "db_pool_size", handler: fn v -> put_in_repo([:pool_size], String.to_integer(v)) end

  # ----- Configuration utils -----

  defp put_in_env(app, [head | keys], value) do
    base = Application.get_env(app, head, [])
    modified = case keys do
      [] -> value
      _ -> put_in(base, keys, value)
    end
    Application.put_env(app, head, modified)
    []
  end

  defp put_in_repo(keys, value),
    do: put_in_env(:db, [DB.Repo] ++ keys, value)
end