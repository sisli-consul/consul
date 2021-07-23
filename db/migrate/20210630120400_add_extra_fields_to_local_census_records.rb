class AddExtraFieldsToLocalCensusRecords < ActiveRecord::Migration[5.2]
  def change
    add_column :local_census_records, :name, :string
    add_column :local_census_records, :phone_number, :string
    add_column :local_census_records, :gender, :string
    add_column :local_census_records, :neighborhood, :string
  end
end
