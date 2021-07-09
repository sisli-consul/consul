class AddExtraFieldsToSignatures < ActiveRecord::Migration[5.2]
  def change
    add_column :signatures, :phone_number, :string
  end
end
