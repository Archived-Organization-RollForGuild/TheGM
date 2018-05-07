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
end# credo:disable-for-this-file
