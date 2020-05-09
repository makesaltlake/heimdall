class AddRevokedByToCertificationIssuances < ActiveRecord::Migration[6.0]
  def change
    add_reference :certification_issuances, :revoked_by, foreign_key: { to_table: :users }
  end
end
