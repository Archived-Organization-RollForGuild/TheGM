defmodule Thegm.Repo.Migrations.ActivateAwsPostgis do
  @moduledoc "Migration that activates postgis and makes some postgres modifications if running on AWS"
  use Ecto.Migration

  def change do
    # initialize
    execute "create extension postgis"
    execute "create extension fuzzystrmatch"
    execute "create extension postgis_tiger_geocoder"
    execute "create extension postgis_topology"

    if System.get_env("RFG_ENVIRONMENT_TYPE") == "aws" do
      cond do
        Application.get_env(:thegm, Thegm.Repo)[:database] == "thegm_test" ->
          # schema permissions
          execute "alter schema tiger owner to postgres"
          execute "alter schema tiger_data owner to postgres"
          execute "alter schema topology owner to postgres"
        true ->
          # schema permissions
          execute "alter schema tiger owner to rds_superuser"
          execute "alter schema tiger_data owner to rds_superuser"
          execute "alter schema topology owner to rds_superuser"
      end
      #functions
      execute "CREATE FUNCTION exec(text) returns text language plpgsql volatile AS $f$ BEGIN EXECUTE $1; RETURN $1; END; $f$;"

      if Application.get_env(:thegm, Thegm.Repo)[:database] != "thegm_test" do
        execute "SELECT exec('ALTER TABLE ' || quote_ident(s.nspname) || '.' || quote_ident(s.relname) || ' OWNER TO rds_superuser;')
        FROM (
          SELECT nspname, relname
          FROM pg_class c JOIN pg_namespace n ON (c.relnamespace = n.oid)
          WHERE nspname in ('tiger','topology') AND
          relkind IN ('r','S','v') ORDER BY relkind = 'S')
        s;"
      end
    end
  end
end
