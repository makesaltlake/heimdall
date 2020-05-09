class ChangeCertificationIssuancesToDefaultActive < ActiveRecord::Migration[6.0]
  def change
    change_column_default :certification_issuances, :active, true
  end
end
