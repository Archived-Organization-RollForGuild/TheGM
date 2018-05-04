defmodule Thegm.ReadPagination do
  @moduledoc """
  Handles reading pagination params.
  """

  @doc """
  Reads the params, tries to parse them, returns errors where necessary.
  """

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
end
