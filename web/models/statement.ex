defmodule CaptainFact.Statement do
  use CaptainFact.Web, :model

  schema "statements" do
    field :text, :string
    field :status, StatementStatusEnum
    field :truthiness, TruthinessEnum
    belongs_to :video, CaptainFact.Video
    belongs_to :speaker, CaptainFact.Speaker

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:text, :status, :truthiness])
    |> validate_required([:text, :status, :truthiness])
  end
end
