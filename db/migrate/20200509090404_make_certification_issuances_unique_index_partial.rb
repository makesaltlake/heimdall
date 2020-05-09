class MakeCertificationIssuancesUniqueIndexPartial < ActiveRecord::Migration[6.0]
  def change
    remove_index :certification_issuances, column: [:certification_id, :user_id], unique: true
    add_index :certification_issuances, [:certification_id, :user_id], unique: true, where: 'active = true'
  end
end
