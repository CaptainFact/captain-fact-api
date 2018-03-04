defmodule CaptainFact.Authenticator.ProviderInfos do
  defstruct provider: nil, # Atom representing the provider
            name: nil, # The best display name known to the strategy. Usually a concatenation of first and last name, but may also be an arbitrary designator or nickname for some strategies
            nickname: nil, # The username of an authenticating user (such as your @-name from Twitter or GitHub account name)
            email: nil, # The e-mail of the authenticating user. Should be provided if at all possible (but some sites such as Twitter do not provide this information)
            locale: nil, # User locale
            picture_url: nil, # A URL representing a profile image of the authenticating user. Where possible, should be specified to a square, roughly 50x50 pixel image.
            uid: nil # Unique user id on given platform
end