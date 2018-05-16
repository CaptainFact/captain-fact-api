defmodule CaptainFact.DemoFr do
  @moduledoc"""
  Run a demo in real-time. To use it from iex console:

      iex> List.first(c(Path.join(:code.priv_dir(:captain_fact), "demos/demo_fr.ex"))).init_and_run
  """

  import DB.Factory
  import CaptainFact.VideoDebate.ActionCreator, only: [action_add: 3, action_create: 3]

  alias Ecto.Multi
  alias DB.Repo
  alias DB.Schema.Video
  alias DB.Schema.Speaker
  alias DB.Schema.VideoSpeaker
  alias DB.Schema.Statement
  alias DB.Schema.User
  alias DB.Type.VideoHashId

  alias CaptainFact.Comments


  @video_url "https://www.youtube.com/watch?v=OhWRT3PhMJs"
  @video_youtube_id "OhWRT3PhMJs"
  @video_title "Le replay du grand débat de la présidentielle"
  @min_sleep 500 # In milliseconds
  @max_sleep 3000 # In milliseconds
  @admin_user_id 1
  @users [
    %{username: "killozor",       name: "Frank Zappa"},
    %{username: "patrick",        name: "Patrick"},
    %{username: "herbiVor",       name: "Mélissa"},
    %{username: "sarah56",        name: "Sarah Fréchit"},
    %{username: "foobar",         name: "Jean Dupont"},
    %{username: "CerealKiller",   name: "Bob Machine"},
    %{username: "LaLoupe",        name: "Medhi Sine"},
    %{username: "Berni55",        name: "Bernard Chapelet"},
    %{username: "jouge",          name: "Jean Tanrien"},
    %{username: "homerLeFact",    name: "Homer Dalors"}
  ]
  @statements %{
    "Nathalie Arthaud" => [],
    "François Asselineau" => [],
    "Nicolas Dupont-Aignan" => [],
    "François Fillon" => [
      %{
        time: 1130,
        text: "Ça n’a jamais créé de l’emploi de réduire le temps de travail",
        comments: [
          %{user_idx: 3, text: "Un rapport du sénat affirme pourtant l'inverse", approve: false, async: true, source: "https://www.senat.fr/rap/r00-414/r00-4146.html", replies: [
            %{user_idx: 1, approve: true, text: "Le rapport dit aussi que \"cet effet n'est, en réalité, guère « très significatif » puisque les 35 heures sont à l'origine de moins de 30% des créations d'emploi en 2000 !\"", replies: [
              %{user_idx: 2, text: "En même temps c'est dur de mesurer ça avec précision, entre la hausse naturelle du chomage et tout le reste!"}
            ]},
          ]},
          %{user_idx: 1, text: "A lire cette tribute du Figaro qui montre bien l'incohérence de la mesure", approve: true, source: "http://www.lefigaro.fr/social/2015/01/30/09010-20150130ARTFIG00002-la-france-paie-toujours-la-facture-des-35heures.php"},
          %{user_idx: 4, text: "Y'en a mare de remettre à chaque fois cette question sur la table", replies: [
            %{user_idx: 5, text: "C'est clair, comme si avec la robotisation et tout le tralala travailler + d'heures avait un sens :/"},
            %{user_idx: 1, approve: false, text: "Heuresement qu'on la remet en question, avec une dette publique de 50000 milliards d'euros!!!", replies: [
              %{user_idx: 3, approve: false, text: "Je sais pas où t'as trouvé tes chiffres mais ça tourne plus autour des 60 milliards", source: "http://www.lepoint.fr/economie/la-dette-publique-de-la-france-se-rapproche-des-100-du-pib-30-06-2017-2139426_28.php"}
            ]}
          ]},
          %{user_idx: 0, text: "Moi j'ai pas d'avis"},
          %{user_idx: 7, text: "C'EST LA FAUTE AU CAPITALISME!!!"}
        ]
      },
#      %{
#        time: 0,
#        text: "La France est aujourd’hui le pays où le volume d’heures travaillées est le plus bas"
#      }, %{
#        time: 0,
#        text: "Chaque année, 150 000 élèves sortent du système scolaire sans diplôme"
#      }
    ],
    "Benoît Hamon" => [
#      %{
#        time: 0,
#        text: "Nous avons aujourd’hui un solde migratoire qui doit être entre 50 000 et 70 000 personnes"
#      }
    ],
    "Jean Lassalle" => [],
    "Marine Le Pen" => [
#      %{
#        time: 0,
#        text: "Les résultats de la Grande Bretagne sont formidables"
#      },
#      %{
#        time: 0,
#        text: "200 000 étrangers légaux entrent en France chaque année"
#      }
    ],
    "Emmanuel Macron" => [
#      %{
#        time: 0,
#        text: "En CM2, 20% des élève ne savent pas proprement lire, écrire ou compter. Cette proportion peut atteindre les 50 voire 60% dans les ZEP"
#      },
      %{
          time: 2269,
          text: "On oublie de dire à chaque fois qu’il y a près de 300.000 Français qui sont travailleurs détachés.",
          comments: [
            %{user_idx: 3, approve: false, score: 42, text: "C'est 125.000, et non pas 300.000 (chiffres de 2014)", source: "https://www.franceinter.fr/emissions/le-vrai-faux-de-l-europe/le-vrai-faux-de-l-europe-04-fevrier-2017"},
            %{user_idx: 9, approve: false, score: 11, text: "Le chiffre de 300.000 correspond au nombre de travailleurs détachés EN FRANCE et non pas au nombre de travailleurs détachés francais", source: "http://travail-emploi.gouv.fr/droit-du-travail/detachement-des-salaries-et-lutte-contre-la-fraude-au-detachement/"}
          ]
      },
      %{
        time: 2628,
        text: "Le lait Français est à 40% exporté en Europe",
        comments: [
          %{user_idx: 6, approve: true, score: 8, source: "http://www.maison-du-lait.com/fr/filiere-laitiere/un-marche-qui-croit-lexport"}
        ]
      }
#     %{
#        time: 0,
#        text: "La France n’accueille pas assez de demandeurs d’asiles, seulement quelques milliers"
#      }
    ],
    "Jean-Luc Mélenchon" => [
#      %{
#        time: 0,
#        text: "La France se fait voler 85 milliards par les tricheurs du Fisc"
#      },
      %{
        time: 1149,
        text: "Dans le prochain mandat, 18 réacteurs nucléaires fêteront leurs 40 ans, il faut 100 milliards pour les caréner",
        comments: [
          %{user_idx: 6, approve: false, text: "C'est la rénovation de l'ensemble du parc nucléaire qui coûterait 100 milliards", source: "http://energie.lexpansion.com/energie-nucleaire/nucleaire-qu-est-ce-que-le-grand-carenage-_a-32-8015.html", replies: [
            %{user_idx: 7, text: "ESPECE DE PROPAGANDISTE!!!"}
          ]}
        ]
      },
      %{
        time: 10_000,
        text: "La France est l’un des pays qui produit le plus d’ingénieurs pour 100 000 habitants"
      }
    ],
    "Philippe Poutou" => []
  }

  def init_and_run, do: run(init())

  def init() do
    # Create or reset video
    if get_video_by_url(@video_url), do: Repo.delete(get_video_by_url(@video_url))
    video = insert(:video, %{url: @video_url, provider: "youtube", provider_id: @video_youtube_id, title: @video_title})

    # Create users
    users = Enum.map(@users, &(
      Repo.get_by(User, username: &1.username) || insert(:user, Map.merge(%{reputation: 1000}, &1)))
    )

    # Add speakers & statements
    Code.require_file(Path.join(:code.priv_dir(:db), "repo/seed_politicians.exs"))
    seed_file = Path.join(:code.priv_dir(:db), "repo/seed_data/politicians_born_after_1945_having_a_picture.csv")

    SeedPoliticians.seed(seed_file, true, Map.keys(@statements))
    speakers = Enum.map(@statements, fn {speaker_name, statements} ->
      speaker = Repo.get_by!(Speaker, full_name: speaker_name)
      video_speaker_changeset = VideoSpeaker.changeset(%VideoSpeaker{speaker_id: speaker.id, video_id: video.id})
      Multi.new
      |> Multi.insert(:video_speaker, video_speaker_changeset)
      |> Multi.insert(:action_add, action_add(@admin_user_id, video.id, speaker))
      |> Repo.transaction()

      {speaker, Enum.map(statements, fn statement ->
        statement =
          %Statement{speaker_id: speaker.id, video_id: video.id, time: statement.time, text: statement.text}
          |> Statement.changeset()
          |> Repo.insert!()
          |> Map.put(:comments, statement[:comments])
        Repo.insert(action_create(@admin_user_id, video.id, statement))
        statement
      end)}
    end)

    {video, users, speakers}
  end

  def run({video, users, speakers}) do
    for {_, statements} <- speakers do
      for statement <- statements do
        Enum.map(statement.comments || [], &(add_comment(users, video.id, statement.id, &1)))
      end
    end
  end

  defp add_comment(users, video_id, statement_id, comment_base, reply_to_id \\ nil) do
    context = DB.Schema.UserAction.video_debate_context(video_id)
    params =
      comment_base
      |> Map.take([:text, :approve])
      |> Map.put(:statement_id, statement_id)
      |> Map.put(:reply_to_id, reply_to_id)
      |> Map.put(:source, (comment_base[:source] && %{url: comment_base.source}) || nil)

    comment =
      users
      |> Enum.at(comment_base.user_idx)
      |> Comments.add_comment(context, params, comment_base[:source], fn comment ->
        comment = Repo.preload(Repo.preload(comment, :source), :user)
        CaptainFactWeb.Endpoint.broadcast(
          "comments:video:#{VideoHashId.encode(video_id)}", "comment_updated",
          CaptainFactWeb.CommentView.render("comment.json", comment: comment)
        )
      end)
      |> update_score(comment_base[:score])

    CaptainFactWeb.Endpoint.broadcast(
      "comments:video:#{VideoHashId.encode(video_id)}", "comment_added",
      CaptainFactWeb.CommentView.render("comment.json", comment: comment)
    )

    # Add replies
    add_replies_task = Task.async(fn ->
      Process.sleep(comment_base[:wait_after] || rand_sleep_time(@min_sleep, @max_sleep))
      for reply <- Map.get(comment_base, :replies, []),
        do: add_comment(users, video_id, statement_id, reply, comment.id)
    end)
    if comment_base[:async] != true,
      do: Task.await(add_replies_task, @max_sleep * 10_000)
  end

  def rand_sleep_time(min, max) do
    if min < 1 do
      0
    else
      min + :rand.uniform(max - min)
    end
  end

  defp update_score(comment, nil), do: comment
  defp update_score(comment, target_score) when is_integer(target_score) do
    for _ <- 1..target_score do
      insert(:vote, %{comment: comment, value: 1})
    end
    Map.put(comment, :score, target_score)
  end

  defp get_video_by_url(url) do
    case Video.parse_url(url) do
      {provider, id} -> Repo.get_by(Video.with_speakers(Video), provider: provider, provider_id: id)
      nil -> nil
    end
  end

end
