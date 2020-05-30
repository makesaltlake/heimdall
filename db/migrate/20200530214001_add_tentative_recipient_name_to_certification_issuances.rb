class AddTentativeRecipientNameToCertificationIssuances < ActiveRecord::Migration[6.0]
  def change
    add_column :certification_issuances, :tentative_recipient_name, :string, index: true
    change_column_null :certification_issuances, :user_id, null: true
  end
end
