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
alias Thegm.Repo

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
          %{"games" => games} ->

            game_operations = Enum.map(games, fn (game_entry) ->
              id = Games.generate_uuid(game_entry.name, game_entry.version)
              unless game_entry.avatar == nil do
                icon = open("resources/"<> game_entry.avatar)
                       |> gravity("Center")
                       |> resize_to_limit("512x512")
                       |> extent("512x512")
                       |> format("png")
                       |> save

                AWS.upload_game_icon(icon.path, id)
              end

              %{
                id: id,
                avatar: game_entry.avatar !== nil,
                description: game_entry.description,
                url: game_entry.homepage,
                name: game_entry.name,
                publisher: game_entry.publisher,
                version: game_entry.version,
                inserted_at: NaiveDateTime.utc_now(),
                updated_at: NaiveDateTime.utc_now()
              }
            end)

            game_disambig_operations = Enum.reduce(games, [], fn (game_entry, acc) ->
              unless game_entry.disambiguations == nil do
                id = Games.generate_uuid(game_entry.name, game_entry.version)
                acc ++ Enum.map(game_entry.disambiguations, fn (disambiguation_entry) ->
                  %{
                    id: UUID.uuid4,
                    name: disambiguation_entry,
                    games_id: id,
                    inserted_at: NaiveDateTime.utc_now(),
                    updated_at: NaiveDateTime.utc_now()
                  }
                end)
              end
            end)


            transaction = Multi.new
            |> Multi.insert_all(:game_operations, Games, game_operations)
            |> Multi.insert_all(:game_disambig_operations, GameDisambiguations, game_disambig_operations)

            case Repo.transaction(transaction) do
              {:ok, values} ->
                IO.inspect game_disambig_operations
                IO.puts "Operation successful"

              {:error, _, value, _} ->
                IO.puts "Operation failed"
                IO.inspect value
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