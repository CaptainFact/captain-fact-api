defmodule CaptainFact.Statement do
  use CaptainFact.Web, :model

  schema "statements" do
    field :text, :string
    field :time, :integer
    field :status, StatementStatusEnum
    belongs_to :video, CaptainFact.Video
    belongs_to :speaker, CaptainFact.Speaker

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:text, :status, :time])
    |> validate_required([:text, :status, :time])
  end
end
