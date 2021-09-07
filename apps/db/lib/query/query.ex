defmodule DB.Query do
  @moduledoc """
  General queriying utils.
  """

  import Ecto.Query

  @doc """
  Revert sort by last_inserted. Fallsback on `id` in case there's an equality.
  """
  @spec order_by_last_inserted_desc(Ecto.Queryable.t()) :: Ecto.Queryable.t()
  def order_by_last_inserted_desc(query) do
    order_by(query, desc: :inserted_at, desc: :id)
  end
end
