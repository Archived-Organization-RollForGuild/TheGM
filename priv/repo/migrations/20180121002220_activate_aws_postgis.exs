defmodule Thegm.Repo.Migrations.ActivateAwsPostgis do
  use Ecto.Migration

  def change do
    # initialize
    execute "create extension postgis"
    execute "create extension fuzzystrmatch"
    execute "create extension postgis_tiger_geocoder"
    execute "create extension postgis_topology"

    # schema permissions
#    execute "alter schema tiger owner to rds_superuser"
#    execute "alter schema tiger_data owner to rds_superuser"
#    execute "alter schema topology owner to rds_superuser"

    #functions
    execute "CREATE FUNCTION exec(text) returns text language plpgsql volatile AS $f$ BEGIN EXECUTE $1; RETURN $1; END; $f$;"
    execute "SELECT exec('ALTER TABLE ' || quote_ident(s.nspname) || '.' || quote_ident(s.relname) || ' OWNER TO alex;')
  FROM (
    SELECT nspname, relname
    FROM pg_class c JOIN pg_namespace n ON (c.relnamespace = n.oid)
    WHERE nspname in ('tiger','topology') AND
    relkind IN ('r','S','v') ORDER BY relkind = 'S')
s;"
  end
end
