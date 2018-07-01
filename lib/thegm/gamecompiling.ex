defmodule Thegm.GameCompiling do
  @moduledoc """
  A way to go about compiling game lists
  """


  def compile_game_changesets(list, parent_key, parent_id, result \\ [])
  def compile_game_changesets([], _, _, result), do: {:ok, result}
  def compile_game_changesets([head | tail], parent_key, parent_id, result) do
    this = %{
      id: UUID.uuid4,
      game_suggestions_id: nil,
      games_id: head,
      inserted_at: NaiveDateTime.utc_now(),
      updated_at: NaiveDateTime.utc_now()
    }
    this = Map.put(this, parent_key, parent_id)
    compile_game_changesets(tail, parent_key, parent_id, [this | result])
  end

  def compile_game_suggestion_changesets(list, parent_key, parent_id, result \\ [])
  def compile_game_suggestion_changesets([], _, _, result), do: {:ok, result}
  def compile_game_suggestion_changesets([head | tail], parent_key, parent_id, result) do
    this = %{
      id: UUID.uuid4,
      game_suggestions_id: head,
      games_id: nil,
      inserted_at: NaiveDateTime.utc_now(),
      updated_at: NaiveDateTime.utc_now()
    }
    this = Map.put(this, parent_key, parent_id)
    compile_game_suggestion_changesets(tail, parent_key, parent_id, [this | result])
  end

  def reduce_and_divide(list, games \\ [], game_suggestions \\ [])
  def reduce_and_divide([], games, game_suggestions), do: {:ok, games, game_suggestions}
  def reduce_and_divide([head | tail], games, game_suggestions) do
    cond do
      head.games_id != nil ->
        reduce_and_divide(tail, games ++ [head.games_id], game_suggestions)
      head.game_suggestions_id != nil ->
        reduce_and_divide(tail, games, game_suggestions ++ [head.game_suggestions_id])
      true ->
        reduce_and_divide(tail, games, game_suggestions)
    end
  end
end
