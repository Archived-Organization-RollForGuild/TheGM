defmodule Thegm.UserGames do
  use Thegm.Web, :model

  @primary_key {:id, :binary_id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}
  @foreign_key_type :binary_id

  schema "user_games" do
    field :field, :string
    belongs_to :users, Thegm.Users
    belongs_to :games, Thegm.Games

    timestamps()
  end


  def create_changeset(model, params \\ :empty) do
    model
    |> cast(params, [:field, :games_id, :users_id])
    |> validate_required([:users_id, :games_id])
    |> unique_constraint(:users_id, name: :user_games_games_id_users_id_index)
    |> foreign_key_constraint(:games_id, name: :user_games_games_id_fk)
  end
end
