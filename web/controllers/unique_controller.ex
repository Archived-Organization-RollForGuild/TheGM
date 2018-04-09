defmodule Thegm.UniqueController do
  use Thegm.Web, :controller

  def show(conn, %{"email" => email}) do
    cond do
      Regex.match?(~r/@/, email) ->
        case Repo.one(from u in Thegm.Users, where: u.email == ^email) do
          nil ->
            send_resp(conn, :no_content, "")
          _ ->
            send_resp(conn, :conflict, "")
        end
      true ->
        conn
        |> put_status(:bad_request)
        |> render(Thegm.ErrorView, "error.json", errors: ["email: must be valid email address"])
    end
  end

  def show(conn, %{"username" => username}) do
    cond do
      Regex.match?(~r/^[a-zA-Z0-9\s'_-]+$/, username) ->
        case Repo.one(from u in Thegm.Users, where: u.username == ^username ) do
          nil ->
            send_resp(conn, :no_content, "")
          _ ->
            username_like = username <> "%"
            users = Repo.all(from u in Thegm.Users, select: u.username, where: like(u.username, ^username_like))
            suggestions = get_suggestions(users, [], 0, 100, 0, username)
            conn
            |> put_status(409)
            |> render("suggestions.json", suggestions: suggestions)
        end
      true ->
        conn
        |> put_status(:bad_request)
        |> render(Thegm.ErrorView, "error.json", errors: ["username: invalid format"])
    end
  end

  def show(conn, %{"slug" => slug}) do
    cond do
      Regex.match?(~r/^[a-zA-Z0-9\s-]+$/, slug) ->
        case Repo.one(from g in Thegm.Groups, where: g.slug == ^slug ) do
          nil ->
            send_resp(conn, :no_content, "")
          _ ->
            slug_like = slug <> "%"
            slugs = Repo.all(from g in Thegm.Groups, select: g.slug, where: like(g.slug, ^slug_like))
            suggestions = get_suggestions(slugs, [], 0, 100, 0, slug)
            conn
            |> put_status(409)
            |> render("suggestions.json", suggestions: suggestions)
        end
      true ->
        conn
        |> put_status(:bad_request)
        |> render(Thegm.ErrorView, "error.json", errors: ["slug: invalid format"])
    end
  end

  # *Defintion*
  # get_suggestions recurses until there are 3 suggestions in the suggestions list
  #
  # *Variables*
  # exist is a list of names that contain base_string that already exist
  # suggestions is the list of suggestions we're gonna make
  # lower is an integer of the random lower bound
  # upper is an integer of the random upper bound
  # attempts is the number of attempts made with the given upper and lower bound
  # base_string is the base of the string the user is attempting to use
  defp get_suggestions(exist, suggestions, lower, upper, attempts, base_string) do
    {attempts, lower, upper} = cond do
      # if we have attempted this upper and lower 10 times, increase upper and lower
      attempts >= 10 ->
        {0, upper, upper * 10}
      true ->
        {attempts, lower, upper}
    end
    # get a random number between lower and upper
    ending = Enum.random(lower..upper)
    temp = base_string <> Integer.to_string(ending)

    cond do
      # If the new string suggestion `temp` exists in neither exists or suggestions
      !Enum.member?(exist, temp) and !Enum.member?(suggestions, temp) ->
        # Append `temp` to suggestions list
        new_suggestions = suggestions ++ [temp]
        cond do
          # If the length of the suggestions list is 3, return
          length(new_suggestions) >= 3 ->
            new_suggestions
          # Otherwise, recurse
          true ->
            get_suggestions(exist, new_suggestions, lower, upper, attempts + 1, base_string)
        end
      # Otherwise, recurse
      true ->
        get_suggestions(exist, suggestions, lower, upper, attempts + 1, base_string)
    end
  end
end
# credo:disable-for-this-file
