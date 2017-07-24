# TODO Extract this to an open source project

defmodule CaptainFact.SendInBlueApi do
  def headers() do
    [{"api-key", Application.get_env(:captain_fact, :send_in_blue_api_key)}]
  end

  defmodule User do
    defstruct email: "", attributes: %{}, listid: [], listid_unlink: []

    @base_url "https://api.sendinblue.com/v2.0/user/"

    def create_or_update(user = %User{}) do
      method_url = @base_url <> "createdituser"
      headers = CaptainFact.SendInBlueApi.headers()
      case HTTPoison.post(method_url, Poison.encode!(user), headers) do
        {:ok, %HTTPoison.Response{body: body}} -> case Poison.decode!(body) do
          %{"code" => "success", "data" => data} -> {:ok, data}
          %{"message" => message} -> {:error, message}
        end
        {:error, %{reason: reason}} -> {:error, reason}
      end
    end
  end
end
