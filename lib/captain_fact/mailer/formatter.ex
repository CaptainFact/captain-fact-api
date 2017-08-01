defimpl Bamboo.Formatter, for: CaptainFact.Accounts.User do
  def format_email_address(user, _opts) do
    {CaptainFact.Accounts.User.user_appelation(user), user.email}
  end
end