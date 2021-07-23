class ImportedUserSecond < ImportedUser
  self.table_name = "sosyalkart.vsk_muhatap"

  establish_connection :beyazweb unless Rails.env.test?
end
