alias CaptainFact.Repo
alias CaptainFact.User

admin = User.changeset(%User{reputation: 4200}, %{
  username: "Betree",
  email: "admin@captainfact.io",
  password: "password"
})

Repo.insert!(admin)

# Some speakers
#speakers = [
#  %Speaker{full_name: "Nicolas Sarkozy", title: "Former French President"},
#  %Speaker{full_name: "Donald Trump", title: "President of the USA"},
#  %Speaker{full_name: "Marine Lepen", title: "French Politician"},
#  %Speaker{full_name: "Francois Fillon", title: "French Politician"},
#  %Speaker{full_name: "Cécile Duflot", title: "French Politician"},
#  %Speaker{full_name: "Jean-Luc Mélenchon", title: "French Politician"}
#]
#
#Enum.each speakers, fn(speaker) ->
#  speaker = Map.put(speaker, :is_user_defined, false)
#  Repo.insert!(speaker)
#end
