defmodule CaptainFact.Sources.Source do
  use CaptainFactWeb, :model

  schema "sources" do
    field :url, :string
    field :title, :string
    field :language, :string
    field :site_name, :string

    timestamps()
  end

  @url_regex ~r/[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&\/\/=]*)/

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:url, :title, :language, :site_name])
    |> validate_required([:url])
    |> unique_constraint(:url)
    |> validate_url()
  end

  if Mix.env !== :test do
    def validate_url(changeset), do: validate_format(changeset, :url, @url_regex)
  else # Allow localhost in test
    def validate_url(changeset) do
      url = get_field(changeset, :url)
      if url && String.contains?(url, "__IGNORE_URL_VALIDATION__"),
        do: changeset,
        else: validate_format(changeset, :url, @url_regex)
    end
  end
end
