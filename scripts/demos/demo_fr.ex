ExUnit.start
Faker.start

# Based on:
#   * https://www.lesdecryptages.fr/fact-checking-grand-debat-18-declarations-decryptees/
#   * http://www.lemonde.fr/les-decodeurs/article/2017/03/21/presidentielle-les-petites-et-grosses-intox-du-debat-a-cinq-candidats-sur-tf1_5097892_4355770.html
#   * http://www.lefigaro.fr/elections/presidentielles/2017/03/21/35003-20170321ARTFIG00023-debat-les-six-erreurs-des-candidats.php

defmodule CaptainFact.DemoFr do
  use CaptainFactWeb.ChannelCase
  alias CaptainFactWeb.{Speaker, Video, VideoSpeaker, Statement}
  alias CaptainFact.Accounts.User
  alias CaptainFact.Comments
  alias CaptainFact.{Repo, VideoHashId}

  @video_url "https://www.youtube.com/watch?v=OhWRT3PhMJs"
  @video_youtube_id "OhWRT3PhMJs"
  @video_title "Le replay du grand débat de la présidentielle"
  @min_sleep 2000
  @max_sleep 4000 # 0.0-1.0
  @users [
    %{username: "killozor",       name: "Frank Zappa", picture_url: "http://images.wolfgangsvault.com/images/catalog/thumb/JRM02019-VL.jpg"},
    %{username: "patrick",        name: "Patrick"},
    %{username: "herbiVor",       name: "Mélissa"},
    %{username: "nadine",         name: "Nadine Lapoutre"},
    %{username: "foobar",         name: "Jean Dupont"},
    %{username: "CerealKiller",   name: "Bob Machine"},
    %{username: "LaLoupe",        name: "Medhi China"},
    %{username: "Anonymous",      name: "Bernard Chapelet"},
    %{username: "Anonymous"}
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
            %{user_idx: 1, text: "Le rapport dit aussi que \"cet effet n'est, en réalité, guère « très significatif » puisque les 35 heures sont à l'origine de moins de 30% des créations d'emploi en 2000 !\"", replies: [
              %{user_idx: 2, text: "En même temps c'est dur de mesurer ça avec précision, entre la hausse naturelle du chomage et tout le reste!"}
            ]},
          ]},
          %{user_idx: 1, text: "A lire cette tribute du Figaro qui montre bien l'incohérence de la mesure", approve: true, source: "http://www.lefigaro.fr/social/2015/01/30/09010-20150130ARTFIG00002-la-france-paie-toujours-la-facture-des-35heures.php"},
          %{user_idx: 4, text: "Y'en a mare de remettre à chaque fois cette question sur la table", replies: [
            %{user_idx: 5, text: "C'est clair, comme si avec la robotisation et tout le tralala travailler + d'heures avait un sens :/"},
            %{user_idx: 1, text: "Heuresement qu'on la remet en question, avec une dette publique de 50000 milliards d'euros!!!", replies: [
              %{user_idx: 3, text: "Je sais pas où t'as trouvé tes chiffres mais ça tourne plus autour des 60 milliards", source: "http://www.lepoint.fr/economie/la-dette-publique-de-la-france-se-rapproche-des-100-du-pib-30-06-2017-2139426_28.php"}
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
    "Benoît Hamon" => [],
    "Jean Lassalle" => [],
    "Marine Le Pen" => [
#      %{
#        time: 0,
#        text: "Les résultats de la Grande Bretagne sont formidables"
#      },
      %{
        time: 3000,
        text: "En réalité, sous le mandat de Nicolas Sarkozy, il y a eu 12 500 policiers et gendarmes qui ont été supprimés"
      },
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
        time: 5000,
        text: "L’administration française accorde 200 000 titres de séjours chaque année"
      },
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
          %{user_idx: 6, approve: false, text: "Faux: C'est la rénovation de l'ensemble du parc nucléaire qui coûterait 100 milliards", source: "http://energie.lexpansion.com/energie-nucleaire/nucleaire-qu-est-ce-que-le-grand-carenage-_a-32-8015.html", replies: [
            %{user_idx: 7, text: "ESPECE DE PROPAGANDISTE!!!"}
          ]}
        ]
      },
#      %{
#        time: 0,
#        text: "La France est l’un des pays qui produit le plus d’ingénieurs pour 100 000 habitants"
#      }
    ],
    "Philippe Poutou" => []
  }

  def init_and_run, do: run(init())

  def init() do
    # Create or reset video
    if get_video_by_url(@video_url), do: Repo.delete(get_video_by_url(@video_url))
    video = insert(:video, %{url: @video_url, provider: "youtube", provider_id: @video_youtube_id, title: @video_title})

    # Create users
    users = Enum.map(@users, &(Repo.get_by(User, username: &1.username) || insert(:user, &1)))

    # Add speakers & statements
    Application.put_env(:captain_fact, :manual_seed, true)
    Code.require_file("priv/repo/seed_politicians.exs")
    SeedPoliticians.seed(
      "../captain-fact-data/Wikidata/data/politicians_born_after_1945_having_a_picture.csv",
      true, Map.keys(@statements)
    )
    speakers = Enum.map(@statements, fn {speaker, statements} ->
      speaker = Repo.get_by!(Speaker, full_name: speaker)
      Repo.insert(VideoSpeaker.changeset(%VideoSpeaker{speaker_id: speaker.id, video_id: video.id}))
      {speaker, Enum.map(statements, fn statement ->
        %Statement{speaker_id: speaker.id, video_id: video.id, time: statement.time, text: statement.text}
        |> Statement.changeset()
        |> Repo.insert!()
        |> Map.put(:comments, statement[:comments])
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
    params =
      comment_base
      |> Map.take([:text, :approve])
      |> Map.put(:statement_id, statement_id)
      |> Map.put(:reply_to_id, reply_to_id)
      |> Map.put(:source, (comment_base[:source] && %{url: comment_base.source}) || nil)

    comment = Comments.add_comment(Enum.at(users, comment_base.user_idx), params, comment_base[:source], fn comment ->
      comment = Repo.preload(comment, :source) |> Repo.preload(:user)
      CaptainFactWeb.Endpoint.broadcast(
        "comments:video:#{VideoHashId.encode(video_id)}", "comment_updated",
        CaptainFactWeb.CommentView.render("comment.json", comment: comment)
      )
    end)
    CaptainFactWeb.Endpoint.broadcast(
      "comments:video:#{VideoHashId.encode(video_id)}", "comment_added",
      CaptainFactWeb.CommentView.render("comment.json", comment: comment)
    )

    # Add replies
    add_replies_task = Task.async(fn ->
      Process.sleep(comment_base[:wait_after] || @min_sleep + :rand.uniform(@max_sleep - @min_sleep))
      for reply <- Map.get(comment_base, :replies, []),
        do: add_comment(users, video_id, statement_id, reply, comment.id)
    end)
    if comment_base[:async] != true, do: Task.await(add_replies_task, @max_sleep * 10000)
  end

  defp get_video_by_url(url) do
    case Video.parse_url(url) do
      {provider, id} -> Repo.get_by(Video.with_speakers(Video), provider: provider, provider_id: id)
      nil -> nil
    end
  end

end
