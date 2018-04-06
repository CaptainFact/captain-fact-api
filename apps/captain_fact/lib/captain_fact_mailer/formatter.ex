defimpl Bamboo.Formatter, for: DB.Schema.User do
  def format_email_address(user, _opts) do
    {DB.Schema.User.user_appelation(user), user.email}
  end
end