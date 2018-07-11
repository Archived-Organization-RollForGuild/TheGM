defmodule Thegm.UniqueView do
  use Thegm.Web, :view

  def render("suggestions.json", %{suggestions: suggestions}) do
    %{
      data: %{
        type: "suggestions",
        attributes: %{
          suggestions: suggestions
        }
      }
    }
  end
end
# credo:disable-for-this-file
