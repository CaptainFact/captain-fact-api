defmodule DB.Repo.Migrations.ChangeWikidataItemIdTypeToString do
  use Ecto.Migration

  def up do
    execute("""
    ALTER TABLE speakers
    ALTER COLUMN wikidata_item_id TYPE character varying(255)
    USING 'Q' || wikidata_item_id;
    """)
  end

  def down do
    execute("""
    ALTER TABLE speakers
    ALTER COLUMN wikidata_item_id TYPE integer
    USING (substring(wikidata_item_id from 2))::integer;
    """)
  end
end
