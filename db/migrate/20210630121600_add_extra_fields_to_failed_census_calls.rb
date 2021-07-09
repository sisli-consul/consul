class AddExtraFieldsToFailedCensusCalls < ActiveRecord::Migration[5.2]
  def change
    add_column :failed_census_calls, :phone_number, :string
  end
end
