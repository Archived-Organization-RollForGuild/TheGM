# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Thegm.Repo.insert!(%Thegm.SomeModel{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will halt execution if something goes wrong.

alias Ecto.Multi
alias Thegm.AWS
alias Thegm.Games
alias Thegm.GameDisambiguations

import Mogrify

defmodule Game do
  @derive [Poison.Encoder]

  defstruct avatar: false, description: nil, homepage: nil, name: nil, publisher: nil, version: nil, disambiguations: []
end

defmodule Main do
  def main do
    case File.read("resources/games-list.json") do
      {:ok, gamesdata} ->
        case Poison.decode!(gamesdata, as: %{"games" => [%Game{}]}) do
          {:ok, games} ->
            transaction = Multi.new
            Enum.map(games, fn (game_entry) ->
              id = Games.generate_uuid(game_entry.name, game_entry.version)

              unless game_entry.avatar == nil do
                IO.puts game_entry.avatar
                icon = open("resources/"<> game_entry.avatar)
                       |> gravity("Center")
                       |> resize_to_limit("512x512")
                       |> extent("512x512")
                       |> format("jpg")
                       |> save()

                AWS.upload_game_icon(icon, id)
              end

              game = Games.create_changeset(%Games{}, %{
                id: id,
                avatar: game_entry.avatar !== nil,
                description: game_entry.description,
                url: game_entry.homepage,
                name: game_entry.name,
                publisher: game_entry.publisher,
                version: game_entry.version
              })

              transaction
              |> Multi.insert(:games, game)

              unless game_entry.disambiguations == nil do
                game_entry.map(game_entry.disambiguations, fn (disambiguation_entry) ->
                  disambiguation = GameDisambiguations.create_changeset(%GameDisambiguations{}, %{
                    id: GameDisambiguations.generate_uuid(disambiguation_entry),
                    name: disambiguation_entry,
                    games_id: id
                  })

                  transaction
                  |> Multi.insert(:game_disambiguations, disambiguation)
                end)
              end

              transaction
              |> Multi.insert(:game)
            end)

            case Repo.transaction(transaction) do
              {:ok, result} ->
                IO.puts result

              {:error, operation, value, _} ->
                IO.puts operation, value
            end

          {:error, reason} ->
            IO.puts reason
        end

      {:error, reason} ->
        IO.puts reason
    end
  end
end

Main.main