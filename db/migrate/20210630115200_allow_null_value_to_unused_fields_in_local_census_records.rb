class AllowNullValueToUnusedFieldsInLocalCensusRecords < ActiveRecord::Migration[5.2]
  def change
    change_column :local_census_records, :date_of_birth, :string, null: true
    change_column :local_census_records, :postal_code, :string, null: true
  end
end
