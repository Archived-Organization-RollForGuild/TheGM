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

  def read_pagination_params(params) do
    errors = []

    {page, errors} = read_page(params, errors)
    {limit, errors} = read_limit(params, errors)

    if length(errors) > 0 do
      {:error, errors}
    else
      {:ok, %{offset: (page - 1) * limit, page: page, limit: limit}}
    end
  end

  defp read_page(params, errors) do
    case read_int_param_with_default(params: params, name: "page", default: 1) do
      {:error, error} ->
        {nil, errors ++ [page: error]}

      {:ok, val} ->
        case ensure_between_inclusive(val: val, min: 1, max: nil) do
          {:error, error} ->
            {nil, errors ++ [page: error]}

          {:ok, val} ->
            {val, errors}
        end
    end
  end

  defp read_limit(params, errors) do
    case read_int_param_with_default(params: params, name: "limit", default: 20) do
      {:error, error} ->
        {nil, errors ++ [limit: error]}

      {:ok, val} ->
        case ensure_between_inclusive(val: val, min: 1, max: nil) do
          {:error, error} ->
            {nil, errors ++ [limit: error]}

          {:ok, val} ->
            {val, errors}
        end
    end
  end

  def read_int_param_with_default(params: params, name: name, default: default) do
    case params[name] do
      nil ->
        {:ok, default}

      temp ->
        case Integer.parse(temp) do
          {:error} ->
            {:error, "Unable to parse integer"}

          {integer, _remainder} ->
            {:ok, integer}
        end
    end
  end

  defp ensure_between_inclusive(val: val, min: min, max: max) do
    cond do
      min == nil and val < min ->
        {:error, "Value must be an integer greater than or equal to " <> Integer.to_string(min)}

      max == nil and val > max ->
        {:error, "Value must be an integer less than or equal to " <> Integer.to_string(max)}

      true ->
        {:ok, val}
    end
  end

  def read_geo_search_params(params, default_meters) do
    with {:ok, lat} <- read_float_param(params: params, name: "lat"),
      {:ok, lng} <- read_float_param(params: params, name: "lng"),
      {:ok, meters} <- read_float_param_with_default(params: params, name: "meters", default: default_meters) do
        {:ok, %{lat: lat, lng: lng, meters: meters}}
    else
      {:error, _, error_msg} ->
        {:error, error_msg}
      {:error, error_msg} ->
        {:error, error_msg}
    end
  end

  defp read_float_param(params: params, name: name) do
    case params[name] do
      nil ->
        {:error, :missing_required_param, "The param `" <> name <> "` is required."}
      temp ->
        case Float.parse(temp) do
          {:error} ->
            {:error, "Unable to parse float"}

          {float, _remainder} ->
            {:ok, float}
        end
    end
  end

  defp read_float_param_with_default(params: params, name: name, default: default) do
    case read_float_param(params: params, name: name) do
      {:ok, float} ->
        {:ok, float}
      {:error, :missing_required_param, _} ->
        {:ok, default}
      {:error, error} ->
        {:error, error}
    end
  end
end
