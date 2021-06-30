class ImportedUser < ApplicationRecord
  include ImportValidation

  self.primary_key = :uniqid

  def readonly?
    true
  end
end
