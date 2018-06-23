defmodule Thegm.Validators do
  import Ecto.Changeset
  def validate_url(changeset, field, options \\ []) do
    validate_change(changeset, field, fn _, url ->
      case URI.parse(url) do
        %URI{scheme: nil} -> [{field, options[:message] || "Missing URL scheme"}]
        %URI{host: nil} -> [{field, options[:message] || "Missing URL host"}]
        _ -> []
      end
    end)
  end

  def validate_type(type, expected_type) do
    if type == expected_type do
      {:ok, type}
    else 
      {:error, "Expected data type \"" <> expected_type <> "\", got \"" <> type <> "\""}
    end
  end
end
