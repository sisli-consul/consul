class ImportedUserFirst < ImportedUser
  self.table_name = "sosyalkart.vsk_isletme"

  establish_connection :beyazweb unless Rails.env.test?
end
