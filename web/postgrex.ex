Postgrex.Types.define(Thegm.PostgresTypes,
              [Geo.PostGIS.Extension] ++ Ecto.Adapters.Postgres.extensions(),
              json: Poison)
# credo:disable-for-this-file
