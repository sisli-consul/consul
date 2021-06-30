class ImportedUserThird < ImportedUser
  self.table_name = "hizmetmasasi.vhm_muhatap"

  establish_connection :hizmetmasasi unless Rails.env.test?
end
