class CreateBadgeAccessGrantsView < ActiveRecord::Migration[6.0]
  VIEW_SQL = <<-'END_SQL'
    CREATE OR REPLACE VIEW badge_access_grants AS
      SELECT id, user_id, badge_reader_id, access_reason FROM (
        SELECT
          'u:' || u.id || ',br:' || br.id AS id,
          u.id AS user_id,
          br.id AS badge_reader_id,
          CASE
            WHEN EXISTS(SELECT 1 FROM badge_reader_manual_users AS brmu WHERE brmu.badge_reader_id = br.id AND brmu.user_id = u.id)
            THEN
              'This user is listed under the badge reader''s list of manual users'
            WHEN
              NOT br.restricted_access AND
              EXISTS(
                SELECT 1
                FROM users AS hu
                WHERE hu.household_id = u.household_id
                AND hu.subscription_active
              ) AND
              NOT EXISTS(SELECT 1 FROM badge_reader_certifications AS brc WHERE brc.badge_reader_id = br.id)
            THEN
              'This user has an active membership and the badge reader is open to anyone with an active membership'
            WHEN
              NOT br.restricted_access AND
              EXISTS(
                SELECT 1
                FROM users AS hu
                WHERE hu.household_id = u.household_id
                AND hu.subscription_active
              ) AND
              EXISTS(
                SELECT 1
                FROM badge_reader_certifications AS brc
                JOIN certification_issuances AS ci
                  ON ci.certification_id = brc.certification_id
                WHERE
                  brc.badge_reader_id = br.id AND
                  ci.user_id = u.id AND
                  ci.active
              )
            THEN
              'This user has an active membership and holds a certification that grants access to this badge reader'
          END AS access_reason
        FROM users AS u
        JOIN badge_readers AS br
          ON true
      ) AS badge_access_grants_subquery
    WHERE access_reason IS NOT NULL
  END_SQL

  def up
    execute VIEW_SQL
  end

  def down
    execute "DROP VIEW IF EXISTS badge_access_grants"
  end
end
