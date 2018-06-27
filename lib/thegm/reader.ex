defmodule Thegm.Reader do
  def read_games_and_game_suggestions(params) do
    games = case params["games"] do
      nil ->
        []
      list ->
        list
    end

    game_suggestions = case params["game_suggestions"] do
      nil ->
        []
      list ->
        list
    end

    {:ok, games, game_suggestions}
  end

  def read_games_and_status(params) do
    case params["games"] do
      nil ->
        {:ok, [], :skip}
      list ->
        {:ok, list, :replace}
    end
  end

  def read_game_suggestions_and_status(params) do
    case params["game_suggestions"] do
      nil ->
        {:ok, [], :skip}
      list ->
        {:ok, list, :replace}
    end
  end
end
