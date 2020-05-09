class ChangeIssuedAtToDate < ActiveRecord::Migration[6.0]
  def up
    change_column :certification_issuances, :issued_at, :date
  end

  def down
    change_column :certification_issuances, :issued_at, :datetime
  end
end
